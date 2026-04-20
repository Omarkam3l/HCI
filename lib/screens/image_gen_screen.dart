import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({super.key});

  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen> {
  final _promptCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _loading = false;
  String _status = '';

  final List<String> _examples = [
    'A cat wearing a crown on a golden throne',
    'A futuristic city at sunset with flying cars',
    'A magical forest with glowing mushrooms',
    'A steampunk robot reading a book',
    'A cozy coffee shop on a rainy day',
  ];

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Generating...';
      _imageBytes = null;
    });

    try {
      // Use a simple placeholder image service for now
      // In a real app, you'd use a proper AI image generation service
      final encodedPrompt = Uri.encodeComponent(prompt.replaceAll(' ', '+'));
      final seed = DateTime.now().millisecondsSinceEpoch % 10000;
      
      // Use Lorem Picsum with a seed based on the prompt
      final promptHash = prompt.hashCode.abs() % 1000;
      final url = 'https://picsum.photos/seed/$promptHash/1024/1024';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _status = 'Generated placeholder image for: "$prompt"';
          _loading = false;
        });
      } else {
        setState(() {
          _status = 'Error ${response.statusCode}: Failed to generate image';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Image Generation', style: TextStyle(fontSize: 16)),
            Text('Placeholder images (demo)',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt input
            TextField(
              controller: _promptCtrl,
              decoration: InputDecoration(
                hintText: 'Describe the image you want to generate...',
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _promptCtrl.clear(),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            // Generate button
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_loading ? 'Generating...' : 'Generate Image'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Generated image
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Creating your image...',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              )
            else if (_imageBytes != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(_status,
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center),
                ],
              )
            else if (_status.isNotEmpty)
              Text(_status,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center),

            // Examples
            const SizedBox(height: 24),
            const Text('Examples:',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            ..._examples.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => setState(() => _promptCtrl.text = e),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(e,
                                style: const TextStyle(fontSize: 13))),
                        const Icon(Icons.arrow_forward_ios,
                            size: 12, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
