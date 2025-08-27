import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/gemini_service.dart';
import '../utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../widgets/glass_container.dart';
import 'dart:convert';
import 'prescription_scanner_screen.dart';


class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({Key? key}) : super(key: key);

  @override
  _ScanPrescriptionScreenState createState() => _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen> {
  File? _imageFile;
  String _extractedText = '';
  List<Map<String, String>> _medications = [];
  bool _isLoading = false;

  final GeminiService _geminiService = GeminiService();
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _imageFile = File(imagePath);
      _isLoading = true;
    });

    // Use Latin script which includes better support for handwriting recognition
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFilePath(imagePath));
    await textRecognizer.close();

    setState(() {
      _extractedText = recognizedText.text;
    });

    _processScannedText(recognizedText.text, await _imageFile!.readAsBytes());
  }

  Future<void> _processScannedText(String text, Uint8List imageBytes) async {
    try {
    final result = await _geminiService.askWithImage(
      question: '''You are an expert medical assistant with exceptional skills at reading doctors' handwritten prescriptions.
      Examine the attached prescription image and extract ONLY the medications prescribed. For each medication return:
        • name
        • dosage (including unit)
          • frequency (e.g. 2×/day, 3 times daily)
          • timing (e.g. after meal, at night, morning, evening)
          • duration (if mentioned, e.g. 7 days, 2 weeks)
        Provide the response as a JSON array where each element is an object with exactly these keys: "name", "dosage", "frequency", "timing", "duration".
        If duration is not mentioned, use empty string for that field.''',
      imageBytes: imageBytes,
    );

      final List<dynamic> extractedData = jsonDecode(result);
      List<Map<String, String>> newMedications = extractedData.map((med) => {
        'name': med['name'] as String? ?? '',
        'dosage': med['dosage'] as String? ?? '',
        'frequency': med['frequency'] as String? ?? '',
        'timing': med['timing'] as String? ?? '',
        'duration': med['duration'] as String? ?? '',
      }).toList();

      // Filter out empty entries
      newMedications = newMedications.where((med) =>
        med['name']?.isNotEmpty == true
      ).toList();

      if (newMedications.isNotEmpty) {
        setState(() {
          _medications = newMedications;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${newMedications.length} medication(s). Review and save below.'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No medications found in the prescription. Please try scanning again.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }

    } catch (e) {
      debugPrint('Error processing prescription: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing prescription: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _editMedication(int index) {
    final med = _medications[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Medication',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: med['name'],
                decoration: InputDecoration(
                  labelText: 'Medication Name',
                  labelStyle: TextStyle(color: AppTheme.textTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgGlassMedium,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => med['name'] = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: med['dosage'],
                decoration: InputDecoration(
                  labelText: 'Dosage',
                  labelStyle: TextStyle(color: AppTheme.textTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgGlassMedium,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => med['dosage'] = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: med['frequency'],
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  labelStyle: TextStyle(color: AppTheme.textTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgGlassMedium,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => med['frequency'] = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: med['timing'],
                decoration: InputDecoration(
                  labelText: 'Timing',
                  labelStyle: TextStyle(color: AppTheme.textTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgGlassMedium,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => med['timing'] = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: med['duration'],
                decoration: InputDecoration(
                  labelText: 'Duration (optional)',
                  labelStyle: TextStyle(color: AppTheme.textTeal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgGlassMedium,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (value) => med['duration'] = value,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild
                      Navigator.pop(context);
                    },
                    child: Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeMedication(int index) {
    setState(() {
      _medications.removeAt(index);
    });
  }

  Future<void> _saveMedications() async {
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No medications to save'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int savedCount = 0;
    for (final med in _medications) {
        if (med['name']?.isNotEmpty == true) {
        final medicationData = {
          'name': med['name'],
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
          'userId': userId,
        };
        await _firebaseService.addMedication(userId, medicationData);
          savedCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully saved $savedCount medication(s) to your profile!'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear medications and image after successful save
      setState(() {
        _medications.clear();
        _imageFile = null;
      });

      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });

    } catch (e) {
      debugPrint('Error saving medications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medications: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildInstructions(Map<String, String> medication) {
    final instructions = <String>[];

    if (medication['dosage']?.isNotEmpty == true) {
      instructions.add('Dosage: ${medication['dosage']}');
    }

    if (medication['frequency']?.isNotEmpty == true) {
      instructions.add('Frequency: ${medication['frequency']}');
    }

    if (medication['timing']?.isNotEmpty == true) {
      instructions.add('Timing: ${medication['timing']}');
    }

    if (medication['duration']?.isNotEmpty == true) {
      instructions.add('Duration: ${medication['duration']}');
    }

    return instructions.isEmpty ? 'As prescribed' : instructions.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Prescription'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: GlassContainer(
            child: Column(
              children: [
                if (_imageFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!),
                  ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Prescription'),
                  onPressed: () async {
                    final imagePath = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrescriptionScannerScreen()),
                    );
                    if (imagePath != null) {
                      _processImage(imagePath);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Analyzing prescription...', style: TextStyle(color: Colors.white70)),
                ] else if (_medications.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Scanned Medications (${_medications.length})',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Review the medications below and edit if needed. Tap SAVE when ready.',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.bgGlassMedium,
                              AppTheme.bgGlassMedium.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with name and actions
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.primaryColor, AppTheme.accentColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.medication,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      med['name'] ?? 'Unknown Medication',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Action buttons
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: AppTheme.textTeal, size: 20),
                                        onPressed: () => _editMedication(index),
                                        tooltip: 'Edit medication',
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: AppTheme.dangerColor, size: 20),
                            onPressed: () => _removeMedication(index),
                                        tooltip: 'Remove medication',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Medication details in a structured format
                              if (med['dosage']?.isNotEmpty == true) ...[
                                Row(
                                  children: [
                                    Icon(Icons.local_pharmacy, color: AppTheme.textTeal, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dosage:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        med['dosage']!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],

                              if (med['frequency']?.isNotEmpty == true) ...[
                                Row(
                                  children: [
                                    Icon(Icons.repeat, color: AppTheme.textTeal, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Frequency:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        med['frequency']!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],

                              if (med['timing']?.isNotEmpty == true) ...[
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: AppTheme.textTeal, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Timing:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        med['timing']!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],

                              if (med['duration']?.isNotEmpty == true) ...[
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: AppTheme.textTeal, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Duration:',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        med['duration']!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _saveMedications,
                      child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Save ${_medications.length} Medication(s)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Scan Again Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.camera_alt, color: AppTheme.textTeal),
                      label: Text(
                        'Scan Another Prescription',
                        style: TextStyle(
                          color: AppTheme.textTeal,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.textTeal.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _medications.clear();
                          _imageFile = null;
                        });
                      },
                    ),
                  ),
                ] else ...[
                  const Text('No medications scanned yet', style: TextStyle(color: Colors.white70)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
