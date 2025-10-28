import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/theme.dart';
import '../widgets/glass_container.dart';

class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({Key? key}) : super(key: key);

  @override
  _ScanPrescriptionScreenState createState() => _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen> {
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();

  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _error;
  List<Map<String, String>> _medications = [];
  final Set<int> _saving = {}; // indexes currently saving
  final Set<int> _saved = {};  // indexes saved

  Future<void> _pickImage() async {
    try {
      setState(() { _error = null; });
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() { _imageBytes = bytes; _medications = []; });
    } catch (e) {
      setState(() { _error = 'Failed to pick image: $e'; });
    }
  }

  Future<void> _sendToGemini() async {
    if (_imageBytes == null) return;
    setState(() { _isLoading = true; _error = null; _medications = []; });
    try {
      final result = await _geminiService.askWithImage(
        question: 'Extract ONLY medications from this prescription image. Return a JSON array; each element has EXACT keys: "name", "dosage", "frequency", "timing", "duration". Use empty string for missing fields. Output ONLY JSON.',
        imageBytes: _imageBytes,
      );
      final List<Map<String, String>> meds = _parseMedications(result);

      if (!mounted) return;
      setState(() { _medications = meds; _isLoading = false; });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(meds.isEmpty ? 'No medications found. Try another image.' : 'Found ${meds.length} medication(s).'),
          backgroundColor: meds.isEmpty ? AppTheme.warningColor : AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = 'Processing failed: $e'; });
    }
  }

  List<Map<String, String>> _parseMedications(String raw) {
    String t = raw.trim();
    if (t.startsWith('```')) {
      // Remove code fences like ```json ... ```
      final start = t.indexOf('[');
      final end = t.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        t = t.substring(start, end + 1);
      }
    }
    // If not code-fenced, still try to extract the first JSON array
    if (!(t.startsWith('[') && t.contains(']'))) {
      final start = t.indexOf('[');
      final end = t.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        t = t.substring(start, end + 1);
      }
    }

    try {
      final List<dynamic> arr = jsonDecode(t);
      final meds = arr.whereType<Map>().map<Map<String, String>>((m) => {
        'name': (m['name'] as String?)?.trim() ?? '',
        'dosage': (m['dosage'] as String?)?.trim() ?? '',
        'frequency': (m['frequency'] as String?)?.trim() ?? '',
        'timing': (m['timing'] as String?)?.trim() ?? '',
        'duration': (m['duration'] as String?)?.trim() ?? '',
      }).where((m) => m['name']!.isNotEmpty).toList();
      if (meds.isNotEmpty) return meds;
    } catch (_) {
      // Fall through to heuristic parsing
    }

    // Fallback: try to extract medication names heuristically from text lines
    final List<Map<String, String>> fallback = [];
    final lines = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    for (final line in lines) {
      // Look for patterns like - Name: Paracetamol 500mg or bullet list items
      final lower = line.toLowerCase();
      if (lower.startsWith('-') || lower.startsWith('•')) {
        final name = line.replaceFirst(RegExp(r'^[-•]\s*'), '').trim();
        if (name.isNotEmpty) {
          fallback.add({'name': name, 'dosage': '', 'frequency': '', 'timing': '', 'duration': ''});
        }
      } else if (lower.startsWith('name:')) {
        final name = line.substring(5).trim();
        if (name.isNotEmpty) {
          fallback.add({'name': name, 'dosage': '', 'frequency': '', 'timing': '', 'duration': ''});
        }
      }
    }
    return fallback;
  }

  void _clear() {
    setState(() { _imageBytes = null; _medications = []; _error = null; });
  }

  Future<void> _saveMedicationAt(int index) async {
    if (index < 0 || index >= _medications.length) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please log in to save medications'), backgroundColor: AppTheme.dangerColor),
      );
      return;
    }

    final med = _medications[index];
    setState(() { _saving.add(index); });
    try {
      final medicationData = {
        'name': med['name'] ?? '',
        'dosage': med['dosage'] ?? '',
        'frequency': med['frequency'] ?? '',
        'timing': med['timing'] ?? '',
        'duration': med['duration'] ?? '',
        'startDate': DateTime.now(),
        'endDate': null,
        'instructions': _buildInstructions(med),
        'prescribedBy': 'Scanned Prescription',
        'pharmacy': '',
        'isActive': true,
      };
      await _firebaseService.addMedication(user.uid, medicationData);
      if (!mounted) return;
      setState(() { _saved.add(index); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${med['name']}'), backgroundColor: AppTheme.successColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.dangerColor),
      );
    } finally {
      if (!mounted) return;
      setState(() { _saving.remove(index); });
    }
  }

  String _buildInstructions(Map<String, String> med) {
    final lines = <String>[];
    if ((med['dosage'] ?? '').isNotEmpty) lines.add('Dosage: ${med['dosage']}');
    if ((med['frequency'] ?? '').isNotEmpty) lines.add('Frequency: ${med['frequency']}');
    if ((med['timing'] ?? '').isNotEmpty) lines.add('Timing: ${med['timing']}');
    if ((med['duration'] ?? '').isNotEmpty) lines.add('Duration: ${med['duration']}');
    return lines.isEmpty ? 'As prescribed' : lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Prescription (AI)'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_imageBytes!),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Choose Image'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _imageBytes == null ? null : _sendToGemini,
                        icon: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.bolt),
                        label: Text(_isLoading ? 'Analyzing...' : 'Analyze'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Center(child: Text('Analyzing...', style: TextStyle(color: Colors.white70))),
                ] else if (_medications.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Medications (${_medications.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgGlassMedium,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medication, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(med['name'] ?? 'Unknown',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: _saved.contains(index) ? 'Saved' : 'Save medication',
                                    onPressed: (_saving.contains(index) || _saved.contains(index)) ? null : () => _saveMedicationAt(index),
                                    icon: _saving.contains(index)
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Icon(
                                            _saved.contains(index) ? Icons.check_circle : Icons.save,
                                            color: _saved.contains(index) ? AppTheme.successColor : Colors.white,
                                          ),
                                  ),
                                ],
                              ),
                              if ((med['dosage'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('Dosage: ${med['dosage']}', style: const TextStyle(color: Colors.white70)),
                                ),
                              if ((med['frequency'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Frequency: ${med['frequency']}', style: const TextStyle(color: Colors.white70)),
                                ),
                              if ((med['timing'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Timing: ${med['timing']}', style: const TextStyle(color: Colors.white70)),
                                ),
                              if ((med['duration'] ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Duration: ${med['duration']}', style: const TextStyle(color: Colors.white70)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _clear,
                    icon: Icon(Icons.refresh, color: AppTheme.textTeal),
                    label: Text('Scan Another Prescription', style: TextStyle(color: AppTheme.textTeal)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.textTeal.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const Center(child: Text('No medications scanned yet', style: TextStyle(color: Colors.white70))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


