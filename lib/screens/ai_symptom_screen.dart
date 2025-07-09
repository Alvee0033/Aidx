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

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
                        children: [
        _buildDropdown(
                            value: _gender,
                            items: const ["Male", "Female", "Other"],
                            hint: "Gender",
                            icon: Icons.person,
                            onChanged: (v) => setState(() => _gender = v),
                          ),
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
        SizedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                          SizedBox(
          width: 80,
                            child: TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.04),
                                hintText: "Age",
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'Montserrat'),
                                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                ),
              ),
              const SizedBox(width: 8),
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
                  ),
                  const SizedBox(width: 2),
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
                if (_analysisResult?["medication"] != null) ...[
                  _buildResultSection(
                    title: "2. Medications",
                    icon: Icons.medication_outlined,
                    content: Text(
                      _analysisResult!["medication"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_analysisResult?["measures"] != null)
                  _buildResultSection(
                    title: "3. Measures to be Taken",
                    icon: Icons.healing,
                    content: Text(
                      _analysisResult!["measures"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Montserrat',
                      ),
                  ),
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
      return const Center(child: CircularProgressIndicator());
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
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontFamily: 'Montserrat'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHistoryItem(_history[index]),
        );
      },
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
                  if (record['analysis'] != null && (record['analysis']['conditions'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                    Text(
                      "Conditions: " + (record['analysis']['conditions'] as List).join(', '),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'Montserrat',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                ],
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  // Logic methods
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
      final resText = await _geminiService.analyzeSymptoms(
        description: desc,
        age: int.tryParse(_ageController.text),
        gender: _gender,
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
      await firebaseService.saveSymptomRecord(user.uid, {
        'name': name,
        'analysis': analysis,
        'severity': _intensity,
        'duration': _duration,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final firebaseService = FirebaseService();
    final user = firebaseService.currentUser;
    if (user != null) {
      final hist = await firebaseService.getSymptomHistory(user.uid);
      setState(() {
        _history
          ..clear()
          ..addAll(hist);
        _historyLoading = false;
      });
    } else {
      setState(() => _historyLoading = false);
    }
  }

  void _logout() async {
    final firebaseService = FirebaseService();
    await firebaseService.signOut();
    if (mounted) Navigator.pop(context);
  }
} 