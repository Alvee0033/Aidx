import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aidx/services/gemini_service.dart';

class AiVisionScreen extends StatefulWidget {
  const AiVisionScreen({super.key});

  @override
  State<AiVisionScreen> createState() => _AiVisionScreenState();
}

class _AiVisionScreenState extends State<AiVisionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final GeminiService _gemini = GeminiService();

  Uint8List? _imageBytes;
  File? _imageFile;
  String? _answer;
  String? _error;
  bool _isLoading = false;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
      _answer = null;
    });
    final x = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFile = File(x.path);
    });
  }

  Future<void> _ask() async {
    if (_imageBytes == null && (_imageFile == null || !_imageFile!.existsSync())) {
      setState(() => _error = 'Please capture or select an image first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _answer = null;
      _error = null;
    });
    try {
      final q = _questionController.text.trim().isEmpty
          ? 'What medical information can you infer from this image?'
          : _questionController.text.trim();
      final res = await _gemini.askWithImage(
        question: q,
        imageBytes: _imageBytes,
        imageFile: _imageBytes == null ? _imageFile : null,
      );
      setState(() => _answer = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Visual Q&A')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!, height: 220, fit: BoxFit.cover),
              )
            else if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, height: 220, fit: BoxFit.cover),
              )
            else
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('No image selected'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Ask a question about the image',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _ask,
              icon: const Icon(Icons.send),
              label: Text(_isLoading ? 'Asking…' : 'Ask'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_answer != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_answer!),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 