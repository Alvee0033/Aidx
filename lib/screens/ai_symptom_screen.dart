import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';
import '../services/database_init.dart';
import '../services/health_id_service.dart';
import '../models/health_id_model.dart';

class AISymptomScreen extends StatefulWidget {
  const AISymptomScreen({Key? key}) : super(key: key);

  @override
  State<AISymptomScreen> createState() => _AISymptomScreenState();
}

class _AISymptomScreenState extends State<AISymptomScreen> {
  // Controllers
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Services
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  // State
  int _tabIndex = 0; // 0 = detector, 1 = history
  String? _gender;
  String _intensity = "mild";
  String _duration = "<1d";
  XFile? _pickedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  bool _historyLoading = true;
  final List<Map<String, dynamic>> _history = [];
  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _useLiveVitals = false;
  bool _useHealthIdProfile = false;
  HealthIdModel? _healthId;
  bool _healthIdLoading = false;

  @override
  void initState() {
    super.initState();
    print('🚀 AI Symptom Screen initialized');
    _loadHistory();
    _loadHealthIdProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildTabToggle(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _tabIndex == 0 ? _buildAnalyzerView() : _buildHistoryView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        elevation: 0,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.bgGlassLight.withOpacity(0.6),
                    Colors.black.withOpacity(0.4)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.monitor_heart, size: 22, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                    "AI Symptom Analyzer",
                    style: TextStyle(
                      color: Colors.white,
                        fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
                    onTap: _logout,
                    child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Montserrat'),
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton("Analyzer", 0),
          _buildTabButton("History", 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor])
                : null,
            color: selected ? null : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Main content views
  Widget _buildAnalyzerView() {
        return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
            child: _buildAnalyzerCard(),
    );
  }

  Widget _buildAnalyzerCard() {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  AppTheme.bgGlassMedium.withOpacity(0.85)
                ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                      ),
                    ],
                  ),
            child: Padding(
              padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildSectionHeader("Describe your symptoms", Icons.psychology),
                  const SizedBox(height: 16),
                  _buildSymptomInput(),
                  const SizedBox(height: 16),
                  _buildDetailInputs(),
                  const SizedBox(height: 16),
                  _buildImageUpload(),
                  const SizedBox(height: 20),
                  _buildAnalyzeButton(),
                  if (_analysisResult != null || _isAnalyzing) ...[
                    const SizedBox(height: 24),
                    _buildResultCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                              color: Colors.white,
              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
            overflow: TextOverflow.ellipsis,
          ),
                          ),
                        ],
    );
  }

  Widget _buildSymptomInput() {
    return TextField(
                        controller: _symptomController,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
        fillColor: Colors.black.withOpacity(0.25),
                          hintText: "Describe your main symptoms...",
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Montserrat'),
                          border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
        contentPadding: const EdgeInsets.all(16),
                        ),
    );
  }

  Widget _buildDetailInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health ID Toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                _healthId != null ? Icons.verified_user : Icons.person_off,
                color: _useHealthIdProfile ? AppTheme.accentColor : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _healthIdLoading
                          ? "Loading Health ID..."
                          : (_healthId == null
                              ? "Health ID not linked"
                              : (_useHealthIdProfile ? "Using Health ID" : "Use Health ID")),
                      style: TextStyle(
                        color: _healthId == null
                            ? Colors.white54
                            : (_useHealthIdProfile ? Colors.white : Colors.white70),
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_healthId != null && !_healthIdLoading) ...[
                      const SizedBox(width: 8),
                      Switch(
                        value: _useHealthIdProfile,
                        onChanged: (val) {
                          setState(() {
                            _useHealthIdProfile = val;
                            // Refresh age display when toggle changes
                            _refreshAgeDisplay();
                          });
                        },
                        activeColor: AppTheme.accentColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Age and Gender fields (always visible, but indicate Health ID usage)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            _buildDropdown(
              value: _gender,
              items: const ["Male", "Female", "Other"],
              hint: _useHealthIdProfile && _healthId != null ? "Gender (from Health ID)" : "Gender",
              icon: Icons.person,
              onChanged: (v) => setState(() => _gender = v),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                enabled: !(_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.white.withOpacity(0.04),
                  hintText: (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null)
                      ? "Age: ${_healthId!.age}"
                      : "Age",
                  hintStyle: TextStyle(
                    color: (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null)
                        ? Colors.greenAccent.withOpacity(0.8)
                        : Colors.white.withOpacity(0.4),
                    fontFamily: 'Montserrat',
                    fontStyle: (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null) ? FontStyle.italic : FontStyle.normal,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null)
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        if (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty && int.tryParse(_healthId!.age!) != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "✓ Using age ${_healthId!.age} from Health ID profile",
              style: TextStyle(
                color: Colors.greenAccent.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Always visible fields (intensity, duration, live vitals)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.start,
          children: [
            _buildDropdown(
              value: _intensity,
              items: const ["mild", "moderate", "severe"],
              hint: "Intensity",
              icon: Icons.bolt,
              onChanged: (v) => setState(() => _intensity = v ?? "mild"),
            ),
            _buildDropdown(
              value: _duration,
              items: const ["<1d", "1-3d", "1w", ">1w"],
              hint: "Duration",
              icon: Icons.timer,
              onChanged: (v) => setState(() => _duration = v ?? "<1d"),
            ),
            Row(
              children: [
                Switch(
                  value: _useLiveVitals,
                  onChanged: (val) {
                    setState(() {
                      _useLiveVitals = val;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Text(
                  "Live Vitals",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value?.isEmpty == true ? null : value,
          icon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.8), size: 18),
          dropdownColor: Colors.black.withOpacity(0.8),
          style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
          hint: Text(hint, style: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'Montserrat')),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontFamily: 'Montserrat')),
                  ))
              .toList(),
          onChanged: onChanged,
                                  ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image, size: 20),
          label: const Text("Upload Photo"),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            shadowColor: Colors.transparent,
            side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.6)),
                            ),
                          ),
                          if (_pickedImage != null) ...[
          const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentColor.withOpacity(0.18),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.18), width: 1.2),
                              ),
                              child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
                                child: kIsWeb
                                    ? Image.memory(
                                        _imageBytes!,
                      width: 50,
                      height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_pickedImage!.path),
                      width: 50,
                      height: 50,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ],
                        ],
    );
  }

  Widget _buildAnalyzeButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _isAnalyzing ? null : _analyze,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: AppTheme.primaryColor.withOpacity(0.5),
          side: BorderSide(color: AppTheme.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isAnalyzing 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  )
                : const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Analyze Symptoms",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSevereCondition(List conditions) {
    if (conditions.isEmpty) return false;
    final joined = conditions.join(' ').toLowerCase();

    // Check if AI response explicitly indicates severe condition
    if (joined.contains('severity: severe') || joined.contains('severe (emergency)')) {
      return true;
    }

    // Define severe conditions that require immediate medical attention
    const severeKeywords = [
      'heart attack', 'myocardial infarction', 'stroke', 'kidney failure', 'renal failure',
      'sepsis', 'anaphylaxis', 'pulmonary embolism', 'pe', 'aortic dissection',
      'meningitis', 'intracranial hemorrhage', 'hemorrhage', 'gi bleed', 'diabetic ketoacidosis', 'dka',
      'status asthmaticus', 'respiratory failure', 'acute liver failure', 'encephalitis',
      'appendicitis with perforation', 'ectopic pregnancy', 'testicular torsion',
      'acute coronary syndrome', 'acs', 'shock', 'cardiac arrest', 'cancer', 'tumor',
      'pneumonia', 'tuberculosis', 'hiv', 'aids', 'hepatitis', 'cirrhosis',
      'pancreatitis', 'peritonitis', 'osteomyelitis', 'endocarditis', 'myocarditis'
    ];

    for (final kw in severeKeywords) {
      if (joined.contains(kw)) return true;
    }

    // Also check for high confidence with severe intensity
    final hasHighPercent = RegExp(r'\(\s*(9[0-9]|100)\s*%\s*\)').hasMatch(joined);
    if (hasHighPercent && _intensity.toLowerCase() == 'severe') return true;

    return false;
  }

  Widget _buildResultCard() {
    if (_isAnalyzing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              "Analyzing your symptoms...",
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Montserrat'),
            ),
          ],
        ),
      );
    }

    final conditions = (_analysisResult?["conditions"] as List?) ?? [];
    final bool isSevere = _isSevereCondition(conditions);

    return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                colors: [
            Colors.black.withOpacity(0.6),
            AppTheme.bgGlassMedium.withOpacity(0.6),
                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_information,
                      color: AppTheme.primaryColor,
                      size: 24,
                            ),
                    const SizedBox(width: 10),
                    const Text(
                      "Analysis Results",
                        style: TextStyle(
                          color: Colors.white,
                        fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                                ),
                              ],
                            ),
                const SizedBox(height: 10),
                if (conditions.isNotEmpty) ...[
                  _buildResultSection(
                    title: "1. Possible Conditions",
                    icon: Icons.coronavirus_outlined,
                    content: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: conditions.map((condition) => _buildConditionBubble(condition)).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                                // Section 2: Medications (concise display)
                _buildResultSection(
                  title: "Medications",
                  icon: Icons.medication_outlined,
                  content: _buildMedicationContent(_analysisResult?["medication"] ?? ""),
                ),
                const SizedBox(height: 8),
                // Section 3: Home Remedies (concise display)
                _buildResultSection(
                  title: "Home Remedies",
                  icon: Icons.local_florist_outlined,
                  content: _buildHomeRemedyContent(_analysisResult?["homemade_remedies"] ?? ""),
                ),
                const SizedBox(height: 8),
                // Section 4: Actions (concise display)
                _buildResultSection(
                  title: "Actions",
                  icon: Icons.healing,
                  content: _buildMeasuresContent(_analysisResult?["measures"] ?? ""),
                ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildConditionBubble(String condition) {
    // Extract percentage if present
    String displayText = condition;
    String percentage = "";
    
    // Look for patterns like "(80%)" or "(80 %)" or "80%"
    final percentageRegex = RegExp(r'\(?\d+\s*%\)?');
    final match = percentageRegex.firstMatch(condition);
    
    if (match != null) {
      percentage = match.group(0) ?? "";
      // Clean up the percentage text
      percentage = percentage.replaceAll(RegExp(r'[()]'), '').trim();
      
      // Remove the percentage from display text if it's in parentheses
      if (condition.contains('(') && condition.contains(')')) {
        displayText = condition.replaceAll(RegExp(r'\s*\(\d+\s*%\)'), '').trim();
      }
    }
    
    // Remove any bullet points or dashes
    displayText = displayText.replaceAll(RegExp(r'^[-•]\s*'), '').trim();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.accentColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
          if (percentage.isNotEmpty) ...[
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                percentage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                Icon(
                  icon,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
            const SizedBox(width: 8),
            Text(
              title,
                  style: TextStyle(
                    color: AppTheme.accentColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
            const SizedBox(height: 6),
            content,
          ],
        ),
        ),
    );
  }

  // Simplified content builders for concise display
  Widget _buildMedicationContent(String medicationText) {
    return Text(
      medicationText.isEmpty ? "Paracetamol 500mg every 4-6h, Ibuprofen 200mg every 4-6h" : medicationText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Montserrat',
        height: 1.4,
      ),
    );
  }

  Widget _buildHomeRemedyContent(String remedyText) {
    return Text(
      remedyText.isEmpty ? "Rest, hydrate, cool compress for fever" : remedyText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Montserrat',
        height: 1.4,
      ),
    );
  }

  Widget _buildMeasuresContent(String measuresText) {
    return Text(
      measuresText.isEmpty ? "Monitor symptoms, seek care if worsens" : measuresText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Montserrat',
        height: 1.4,
      ),
    );
  }





  Widget _buildResultTextSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat'),
          softWrap: true,
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
      ),
      backgroundColor: Colors.white.withOpacity(0.1),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildHistoryView() {
    if (_historyLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading symptom history...',
              style: TextStyle(
                color: Colors.white70, 
                fontFamily: 'Montserrat'
              ),
            ),
          ],
        ),
      );
    }
    
        if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.white.withOpacity(0.5), size: 50),
            const SizedBox(height: 8),
            Text(
              "No symptom history yet",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Montserrat'
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh History'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "History will appear here after you analyze symptoms",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'Montserrat',
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHistoryItem(_history[index]),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> record) {
    final timestamp = (record['timestamp'] as Timestamp?)?.toDate();
    final formattedDate = timestamp != null ? DateFormat('MMM dd, yyyy').format(timestamp) : 'No date';
    
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                      Icon(Icons.medical_services, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                          record['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Montserrat',
                    ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                  ],
                ),
                  if (record['analysis'] != null) ...[
                    const SizedBox(height: 8),
                    _buildAnalysisSummary(record['analysis']),
                  ],
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisSummary(Map<String, dynamic> analysis) {
    final List<String> summaryParts = [];

    try {
      // Handle conditions - can be List<String> or List<Map> with name/likelihood
      if (analysis['conditions'] != null) {
        final conditions = analysis['conditions'];
        String conditionsText = '';

        if (conditions is List) {
          if (conditions.isNotEmpty && conditions.first is Map) {
            // New format: [{"name": "...", "likelihood": 70}]
            conditionsText = conditions.map((c) {
              if (c is Map && c['name'] != null) {
                final likelihood = c['likelihood'] ?? '';
                return likelihood.isNotEmpty ? '${c['name']} (${likelihood}%)' : c['name'];
              }
              return c.toString();
            }).join(', ');
          } else {
            // Old format: ["condition1", "condition2"]
            conditionsText = conditions.join(', ');
          }
        } else if (conditions is String) {
          conditionsText = conditions;
        }

        if (conditionsText.isNotEmpty) {
          summaryParts.add("Conditions: $conditionsText");
        }
      }

      // Handle medications
      final meds = analysis['medication'] ?? analysis['medications'];
      if (meds != null) {
        String medsText = '';
        if (meds is List) {
          medsText = meds.join(', ');
        } else if (meds is String) {
          medsText = meds;
        }
        if (medsText.isNotEmpty) {
          summaryParts.add("Medications: $medsText");
        }
      }

      // Handle home remedies
      if (analysis['homemade_remedies'] != null) {
        final remedies = analysis['homemade_remedies'];
        String remediesText = '';
        if (remedies is List) {
          remediesText = remedies.join(', ');
        } else if (remedies is String) {
          remediesText = remedies;
        }
        if (remediesText.isNotEmpty) {
          summaryParts.add("Home Remedies: $remediesText");
        }
      }

      // Handle measures/actions
      final measures = analysis['measures'] ?? analysis['actions'];
      if (measures != null) {
        String measuresText = '';
        if (measures is List) {
          measuresText = measures.join(', ');
        } else if (measures is String) {
          measuresText = measures;
        }
        if (measuresText.isNotEmpty) {
          summaryParts.add("Actions: $measuresText");
        }
      }

      // Handle severity if not shown elsewhere
      if (analysis['severity'] != null && !summaryParts.any((part) => part.contains('Severity'))) {
        summaryParts.add("Severity: ${analysis['severity']}");
      }

    } catch (e) {
      print('Error building analysis summary: $e');
      summaryParts.add("Analysis data available");
    }

    if (summaryParts.isEmpty) {
      return const Text(
        "Analysis data available",
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Montserrat',
          fontSize: 13,
        ),
      );
    }

    return Text(
      summaryParts.join('\n'),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 13,
        height: 1.3,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 4,
    );
  }

  // Logic methods
  Future<void> _loadHealthIdProfile() async {
    setState(() => _healthIdLoading = true);
    try {
      final svc = HealthIdService();
      final profile = await svc.getHealthId();
      if (!mounted) return;
      print('Symptom Screen - Loaded Health ID: ${profile?.name}, Age: ${profile?.age}');
      setState(() {
        _healthId = profile;
        _healthIdLoading = false;

        // Pre-fill age from Health ID if available and valid
        if (profile != null && profile.age != null && profile.age!.isNotEmpty) {
          final ageInt = int.tryParse(profile.age!);
          if (ageInt != null) {
            _ageController.text = ageInt.toString();
            print('Symptom Screen - Pre-filled age: $ageInt');
          } else {
            print('Symptom Screen - Could not parse age: ${profile.age}');
          }
        } else {
          print('Symptom Screen - No age in Health ID profile');
        }
      });
    } catch (e) {
      print('Symptom Screen - Error loading Health ID: $e');
      setState(() => _healthIdLoading = false);
      // Silently ignore profile load errors
    }
  }

  void _refreshAgeDisplay() {
    // Update age field display based on Health ID toggle state
    if (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty) {
      final ageInt = int.tryParse(_healthId!.age!);
      if (ageInt != null && ageInt > 0 && ageInt <= 150) {
        // Valid age in Health ID, update the controller
        _ageController.text = ageInt.toString();
      }
    }
  }

  String _appendPatientProfile(String baseDescription) {
    if (_healthId == null || !_useHealthIdProfile) return baseDescription;
    final profile = _healthId!;
    final List<String> lines = [];
    if ((profile.bloodGroup ?? '').trim().isNotEmpty) {
      lines.add('Blood Group: ${profile.bloodGroup}');
    }
    if (profile.allergies.isNotEmpty) {
      lines.add('Allergies: ${profile.allergies.join(', ')}');
    }
    if (profile.activeMedications.isNotEmpty) {
      lines.add('Active Medications: ${profile.activeMedications.join(', ')}');
    }
    if ((profile.medicalConditions ?? '').trim().isNotEmpty) {
      lines.add('Known Conditions: ${profile.medicalConditions}');
    }
    if ((profile.notes ?? '').trim().isNotEmpty) {
      lines.add('Notes: ${profile.notes}');
    }
    if (lines.isEmpty) return baseDescription;
    return baseDescription +
        '\n\nPatient Profile (from Digital Health ID):\n' +
        lines.join('\n');
  }

  Future<void> _pickImage() async {
    try {
      // Show bottom sheet with options
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  AppTheme.bgGlassMedium.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Choose Image Source",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildImageSourceOption(
                            icon: Icons.camera_alt,
                            label: "Camera",
                            onTap: () async {
                              Navigator.pop(context);
                              await _getImageFromSource(ImageSource.camera);
                            },
                          ),
                          _buildImageSourceOption(
                            icon: Icons.photo_library,
                            label: "Gallery",
                            onTap: () async {
                              Navigator.pop(context);
                              await _getImageFromSource(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error showing image options: ${e.toString()}')),
      );
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.7),
                  AppTheme.accentColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (img != null) {
        setState(() => _pickedImage = img);
        _imageBytes = await img.readAsBytes();
        _imageMimeType = img.mimeType;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _analyze() async {
    final desc = _symptomController.text.trim();
    if (desc.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe symptoms or attach an image')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });
    try {
      File? imageFile;
      if (!kIsWeb && _pickedImage != null) {
        imageFile = File(_pickedImage!.path);
        if (!imageFile.existsSync()) {
          throw Exception('Selected image file no longer exists');
        }
        final fileSize = await imageFile.length();
        if (fileSize > 4 * 1024 * 1024) {
          throw Exception('Image file is too large. Please use an image smaller than 4MB.');
        }
      }
      Map<String, dynamic>? vitals;
      if (_useLiveVitals) {
        final dbService = DatabaseService();
        final userId = dbService.getCurrentUserId();
        if (userId != null) {
          vitals = await dbService.getLatestVitals(userId);
        }
      }

      // Enrich description with patient profile from Digital Health ID for accuracy
      final enrichedDesc = _appendPatientProfile(desc);

      // Use health ID data if available and enabled, otherwise use manual inputs
      int? analysisAge;
      String? analysisGender;

      // First try to get age from Health ID if enabled
      if (_useHealthIdProfile && _healthId != null && _healthId!.age != null && _healthId!.age!.isNotEmpty) {
        analysisAge = int.tryParse(_healthId!.age!.trim());
        if (analysisAge != null && analysisAge > 0 && analysisAge <= 150) {
          // Successfully parsed valid age from Health ID
          print('Using Health ID age: $analysisAge');
        } else {
          // Invalid age in Health ID, fall back to manual input
          print('Invalid Health ID age: ${_healthId!.age}, falling back to manual input');
          analysisAge = int.tryParse(_ageController.text.trim());
        }
      } else {
        // Health ID not enabled or no age data, use manual input
        analysisAge = int.tryParse(_ageController.text.trim());
      }

      // Validate that age is provided and valid
      if (analysisAge == null || analysisAge <= 0 || analysisAge > 150) {
        setState(() => _isAnalyzing = false);
        String errorMessage = 'Age field is required. ';
        if (_useHealthIdProfile && _healthId != null) {
          errorMessage += 'Please add a valid age to your Health ID profile or enter it manually.';
        } else {
          errorMessage += 'Please enter your age.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      analysisGender = _gender;

      final resText = await _geminiService.analyzeSymptoms(
        description: enrichedDesc,
        age: analysisAge,
        gender: analysisGender,
        intensity: _intensity,
        duration: _duration,
        imageAttached: _pickedImage != null,
        imageFile: imageFile,
        imageBytes: _imageBytes,
        imageMimeType: _imageMimeType,
        vitals: vitals,
      );
      // If the result is a user-friendly error string, show error and return
      if (resText.startsWith('Sorry, the AI analysis could not be completed')) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resText),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final parsed = _geminiService.parseResponse(resText);
      setState(() {
        _analysisResult = parsed;
        _isAnalyzing = false;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
      await _saveRecord(desc, parsed);
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, the AI analysis could not be completed at this time. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Future<void> _saveRecord(String name, Map<String, dynamic> analysis) async {
    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;
    if (user != null) {
      try {
        print('💾 Saving symptom record for user: ${user.uid}');
        print('📝 Record data: name="$name", severity="$_intensity", duration="$_duration"');

        final recordData = {
          'userId': user.uid,
          'name': name,
          'analysis': analysis,
          'severity': _intensity,
          'duration': _duration,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await firebaseService.saveSymptomRecord(user.uid, recordData);
        print('✅ Symptom record saved successfully');

        // Add a small delay before loading history to ensure Firestore sync
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadHistory();
      } catch (e) {
        print('❌ Error saving symptom record: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('⚠️ Cannot save record: User not logged in');
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;

    if (user != null) {
      try {
        print('🔍 Loading symptom history for user: ${user.uid}');
        final hist = await firebaseService.getSymptomHistory(user.uid);

        print('📊 Loaded ${hist.length} symptom history records');

        if (hist.isNotEmpty) {
          print('📋 Sample record structure:');
          print('   - Name: ${hist.first['name']}');
          print('   - Timestamp: ${hist.first['timestamp']}');
          print('   - Has analysis: ${hist.first['analysis'] != null}');
          if (hist.first['analysis'] != null) {
            print('   - Analysis keys: ${hist.first['analysis'].keys.join(', ')}');
          }
        } else {
          print('ℹ️ No symptom history found for user');
        }

        if (mounted) {
          setState(() {
            _history
              ..clear()
              ..addAll(hist);
            _historyLoading = false;
          });
        }
        print('✅ History loaded and state updated');
      } catch (e) {
        print('❌ Error loading symptom history: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading symptom history: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _loadHistory,
              ),
            ),
          );
          setState(() {
            _history.clear();
            _historyLoading = false;
          });
        }
      }
    } else {
      print('⚠️ No user logged in, cannot load symptom history');
      if (mounted) {
        setState(() {
          _history.clear();
          _historyLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view symptom history'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Add a method to manually refresh history
  Future<void> _refreshHistory() async {
    await _loadHistory();
  }

  void _logout() async {
    final firebaseService = FirebaseService();
    await firebaseService.signOut();
    if (mounted) Navigator.pop(context);
  }
} 