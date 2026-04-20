import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/groq_service.dart';
import '../services/web_speech_service.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  final _picker = ImagePicker();
  final _questionCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String _answer = '';
  bool _loading = false;
  bool _speaking = false;
  bool _listening = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    if (kIsWeb) WebSpeechService.stopSpeaking();
    super.dispose();
  }

  void _speak(String text) {
    if (!kIsWeb) return;
    WebSpeechService.stopSpeaking();
    setState(() => _speaking = true);
    WebSpeechService.speak(text, onEnd: () {
      if (mounted) setState(() => _speaking = false);
    });
  }

  void _stopSpeaking() {
    if (!kIsWeb) return;
    WebSpeechService.stopSpeaking();
    setState(() => _speaking = false);
  }

  void _startListening() {
    if (!kIsWeb) {
      _showSnack('Voice input only works on web');
      return;
    }

    setState(() => _listening = true);
    
    WebSpeechService.startListening(
      onResult: (transcript) {
        setState(() {
          _questionCtrl.text = transcript;
          _listening = false;
        });
        _showSnack('Got it: $transcript');
      },
      onError: (error) {
        setState(() => _listening = false);
        _showSnack(error);
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _answer = '';
    });
  }

  Future<void> _analyze() async {
    if (_imageBytes == null) {
      _showSnack('Please select an image first');
      return;
    }
    final question = _questionCtrl.text.trim().isEmpty
        ? 'Describe everything in this image in rich detail for someone who cannot see.'
        : _questionCtrl.text.trim();

    setState(() {
      _loading = true;
      _answer = '';
    });

    final result = await GroqService.analyzeImage(
      imageBytes: _imageBytes!,
      question: question,
    );

    setState(() {
      _answer = result;
      _loading = false;
    });

    // Auto-speak the answer
    if (kIsWeb) {
      _speak(result);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vision Assistant', style: TextStyle(fontSize: 16)),
            Text('For visually impaired users',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            GestureDetector(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 56, color: Colors.white38),
                          SizedBox(height: 8),
                          Text('Tap to upload or take a photo',
                              style: TextStyle(color: Colors.white38)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Image source buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question input with mic button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask a question or use the microphone...',
                      filled: true,
                      fillColor: const Color(0xFF16213E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                // Mic button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _listening
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _listening ? null : _startListening,
                    icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                    color: Colors.white,
                    iconSize: 28,
                    tooltip: 'Ask by voice',
                  ),
                ),
              ],
            ),
            if (_listening)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Listening... Speak now',
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Analyze button
            FilledButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? 'Analyzing...' : 'Analyze Image'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Answer
            if (_answer.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  if (kIsWeb)
                    IconButton(
                      onPressed: _speaking ? _stopSpeaking : () => _speak(_answer),
                      icon: Icon(_speaking ? Icons.stop_circle : Icons.volume_up),
                      tooltip: _speaking ? 'Stop' : 'Read aloud',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(_answer,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
            ],

            // Example questions
            const SizedBox(height: 20),
            const Text('Example questions:',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                'Describe everything in detail',
                'What objects are here?',
                'Is there any text?',
                'What colors are present?',
                'Who is in this image?',
              ]
                  .map((q) => ActionChip(
                        label: Text(q,
                            style: const TextStyle(fontSize: 12)),
                        onPressed: () =>
                            setState(() => _questionCtrl.text = q),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
