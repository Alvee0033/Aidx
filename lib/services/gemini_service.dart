import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';

class GeminiService {
  // TODO: Replace with your own API key or load from secure storage
  static const String _apiKey = 'AIzaSyAKOUTO3nKiLfMuoZBe5oEVr2vyhfgcK1I';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final List<Function(String)> _listeners = [];

  /// Add a listener to receive notifications about API calls
  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }
  
  /// Remove a listener
  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }
  
  /// Notify all listeners with a message
  void _notify(String message) {
    for (final listener in _listeners) {
      listener(message);
    }
  }

  /// Analyze symptoms using Gemini API and return the raw text response.
  /// Throws [Exception] if the request fails.
  Future<String> analyzeSymptoms({
    required String description,
    int? age,
    String? gender,
    String? intensity,
    String? duration,
    bool imageAttached = false,
    File? imageFile,
    Uint8List? imageBytes,
    String? imageMimeType,
    Map<String, dynamic>? vitals,
  }) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Please set your Gemini API key in gemini_service.dart');
    }

    final prompt = _buildPrompt(
      description: description,
      age: age,
      gender: gender,
      intensity: intensity,
      duration: duration,
      imageAttached: imageAttached,
      vitals: vitals,
    );

    final systemPrompt =
        'You are a licensed medical assistant. Analyze the symptoms and provide a ROBUST but BRIEF analysis. Return ONLY these three sections, in this exact order, with NO extra words or explanations:\n\n'
        '1. Possible Conditions:\n- List up to 3 likely conditions with percentages (e.g., "Condition (80%)")\n'
        '2. Medications:\n- List recommended medicines (brief, comma-separated)\n'
        '3. Measures to be Taken:\n- List actionable self-care or next steps (brief, bulleted)';

    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    final parts = <Map<String, dynamic>>[
      {
        'text': '$systemPrompt\n\n$prompt',
      }
    ];

    // Add image if provided (bytes first for web)
    if (imageBytes != null && imageBytes.isNotEmpty) {
      if (imageBytes.length > 4 * 1024 * 1024) {
        throw Exception('Image file is too large. Please use an image smaller than 4MB.');
      }
      final base64Img = base64Encode(imageBytes);
      parts.add({
        'inlineData': {
          'mimeType': imageMimeType ?? 'image/jpeg',
          'data': base64Img,
        }
      });
    } else if (imageFile != null && imageFile.existsSync()) {
      try {
        final bytes = await imageFile.readAsBytes();
        if (bytes.length > 4 * 1024 * 1024) {
          throw Exception('Image file is too large. Please use an image smaller than 4MB.');
        }
        final base64Image = base64Encode(bytes);
        String mimeType = imageMimeType ?? 'image/jpeg';
        final path = imageFile.path.toLowerCase();
        if (path.endsWith('.png')) mimeType = 'image/png';
        if (path.endsWith('.gif')) mimeType = 'image/gif';
        if (path.endsWith('.webp')) mimeType = 'image/webp';
        parts.add({
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Image,
          }
        });
      } catch (e) {
        throw Exception('Error processing image: ${e.toString()}');
      }
    }

    final body = {
      'contents': [
        {
          'role': 'user',
          'parts': parts,
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 1000,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_LOW_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_LOW_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_LOW_AND_ABOVE'
        }
      ]
    };

    int retries = 0;
    while (true) {
      try {
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        );
        if (res.statusCode != 200) {
          // Parse Gemini error if possible
          String msg = 'Gemini API error (${res.statusCode})';
          try {
            final err = jsonDecode(res.body);
            if (err is Map && err['error'] != null && err['error']['message'] != null) {
              msg = 'Gemini API error: ${err['error']['message']}';
            }
          } catch (_) {}
          throw Exception(msg);
        }
        final data = jsonDecode(res.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text == null || text is! String || text.isEmpty) {
          throw Exception('No response received from Gemini API');
        }
        return text.trim();
      } catch (e) {
        if (retries < 2) {
          retries++;
          await Future.delayed(const Duration(milliseconds: 600));
          continue;
        }
        // Instead of throwing, return a user-friendly error string
        return 'Sorry, the AI analysis could not be completed at this time. Please try again later.';
      }
    }
  }

  String _buildPrompt({
    required String description,
    int? age,
    String? gender,
    String? intensity,
    String? duration,
    bool imageAttached = false,
    Map<String, dynamic>? vitals,
  }) {
    final ageText = age != null ? 'Age: $age years' : 'Age: Not specified';
    final genderText = gender != null ? 'Gender: $gender' : 'Gender: Not specified';
    final intensityText = 'Symptom intensity: $intensity';
    final durationText = 'Duration: $duration';
    final imageText = imageAttached ? 'Image: Provided for visual analysis' : 'Image: Not provided';
    String vitalsText = '';
    if (vitals != null && vitals.isNotEmpty) {
      vitalsText = '\n## Latest Vitals Data';
      if (vitals['heartRate'] != null) vitalsText += '\nHeart Rate: ${vitals['heartRate']} bpm';
      if (vitals['spo2'] != null) vitalsText += '\nSpO2: ${vitals['spo2']}%';
      if (vitals['bloodPressure'] != null && vitals['bloodPressure'] is Map) {
        final bp = vitals['bloodPressure'];
        if (bp['systolic'] != null && bp['diastolic'] != null) {
          vitalsText += '\nBlood Pressure: ${bp['systolic']}/${bp['diastolic']} mmHg';
        }
      }
      if (vitals['temperature'] != null) vitalsText += '\nTemperature: ${vitals['temperature']} °C';
      if (vitals['steps'] != null) vitalsText += '\nSteps: ${vitals['steps']}';
      if (vitals['calories'] != null) vitalsText += '\nCalories: ${vitals['calories']}';
      if (vitals['sleepHours'] != null) vitalsText += '\nSleep Hours: ${vitals['sleepHours']}';
    }

    return """# Medical Symptom Analysis Request

## Patient Information
$ageText
$genderText
$intensityText
$durationText
$imageText
${vitalsText}

## Symptoms Description
$description

## Analysis Request
Provide a ROBUST but BRIEF analysis in the following format ONLY:

1. Possible Conditions:
- List each condition with likelihood percentage (e.g., "Condition (80%)")
- Maximum 3 conditions, most likely first

2. Medications:
- Brief list of recommended medicines

3. Measures to be Taken:
- Brief, actionable self-care or next steps

Keep each section clearly labeled with numbers (1, 2, 3) and be concise but informative.""";
  }

  /// Search for drug information using Gemini API
  /// Returns structured drug information
  Future<Map<String, dynamic>> searchDrug(String drugName, {bool brief = false}) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('Please set your Gemini API key in gemini_service.dart');
    }

    final systemPrompt = brief
        ? '''You are a professional pharmacist. Use web search tools if available. For "$drugName":
- Determine the most accurate, up-to-date, and widely recognized trademark/brand name(s) using web search.
- If there are multiple brands, list the most common ones (comma-separated). If only generic, state clearly.
- Be robust: clarify if the drug is only generic or has multiple brands.

Return ONLY these fields, each on a single line, no extra info, no paragraphs:
Name: [brand or trade name(s), comma-separated if multiple]
Generic: [generic/chemical name]
Uses: [very short, e.g. "pain relief, fever"]
Dosage: [short, e.g. "500mg every 6h"]
Warnings: [short, e.g. "liver disease, overdose risk"]
No paragraphs, no side effects, no classification, no form, no extra explanation. Be concise.'''
        : '''You are a professional pharmacist. Provide accurate information about $drugName.

Return ONLY these categories in this exact format:

Generic Formula: [generic name]
Uses: [primary medical uses]
Classification: [pharmacological class]
Form: [available forms]
Dosage: [typical adult dosage]
Side Effects: [common side effects]
Warnings: [important warnings]''';

    final uri = Uri.parse('$_endpoint?key=$_apiKey');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': systemPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': brief ? 200 : 800,
          },
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
        return brief ? parseBriefDrugResponse(text, drugName) : parseDrugResponse(text, drugName);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return {
          'name': drugName,
          'error': 'Failed to fetch information. Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Exception: $e');
      return {
        'name': drugName,
        'error': 'Network error. Please check your internet connection and try again.',
      };
    }
  }

  /// Parse drug response into structured format
  Map<String, dynamic> parseDrugResponse(String text, String drugName) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final result = <String, String>{};
    
    final sections = ['Generic Formula', 'Uses', 'Classification', 'Form', 'Dosage', 'Side Effects', 'Warnings'];
    
    for (final section in sections) {
      final regex = RegExp('$section:\\s*(.+)', caseSensitive: false);
      final match = lines.where((line) => regex.hasMatch(line)).firstOrNull;
      if (match != null) {
        final content = regex.firstMatch(match)?.group(1)?.trim() ?? 'Information not available';
        result[section] = content;
      } else {
        result[section] = 'Information not available';
      }
    }

    return {
      'name': drugName,
      'generic_formula': result['Generic Formula'] ?? 'Information not available',
      'uses': result['Uses'] ?? 'Information not available',
      'classification': result['Classification'] ?? 'Information not available',
      'form': result['Form'] ?? 'Information not available',
      'dosage': result['Dosage'] ?? 'Information not available',
      'side_effects': result['Side Effects'] ?? 'Information not available',
      'warnings': result['Warnings'] ?? 'Information not available',
    };
  }

  /// Parse brief Gemini response into a short map.
  Map<String, dynamic> parseBriefDrugResponse(String text, String drugName) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    String name = drugName;
    String generic = '';
    String uses = '';
    String dosage = '';
    String warnings = '';
    for (final line in lines) {
      if (line.toLowerCase().startsWith('name:')) {
        name = line.substring(5).trim();
        // If multiple brand names, keep as comma-separated string
      } else if (line.toLowerCase().startsWith('generic:')) {
        generic = line.substring(8).trim();
      } else if (line.toLowerCase().startsWith('uses:')) {
        uses = line.substring(5).trim();
      } else if (line.toLowerCase().startsWith('dosage:')) {
        dosage = line.substring(7).trim();
      } else if (line.toLowerCase().startsWith('warnings:')) {
        warnings = line.substring(9).trim();
      }
    }
    return {
      'name': name, // may be comma-separated brand names
      'generic_formula': generic,
      'uses': uses,
      'dosage': dosage,
      'warnings': warnings,
    };
  }

  /// Parse the raw Gemini response into a structured map.
  /// Returns a map with keys: conditions (List<String>), medication (String), measures (String)
  Map<String, dynamic> parseResponse(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final conditions = <String>[];
    String medication = '';
    String measures = '';
    
    // Track which section we're currently parsing
    int currentSection = 0;
 
    for (final line in lines) {
      final lower = line.toLowerCase();
      
      // Check for section headers
      if (lower.contains('1.') && lower.contains('condition')) {
        currentSection = 1;
        continue;
      } else if (lower.contains('2.') && lower.contains('medication')) {
        currentSection = 2;
        continue;
      } else if (lower.contains('3.') && lower.contains('measure')) {
        currentSection = 3;
        continue;
      }
      
      // Process content based on current section
      if (currentSection == 1 && line.contains('-')) {
        conditions.add(line);
      } else if (currentSection == 2) {
        if (medication.isEmpty) {
          medication = line;
        } else {
          medication += '\n' + line;
        }
      } else if (currentSection == 3) {
        if (measures.isEmpty) {
          measures = line;
        } else {
          measures += '\n' + line;
        }
      }
    }
 
    return {
      'conditions': conditions,
      'medication': medication,
      'measures': measures,
    };
  }
} 