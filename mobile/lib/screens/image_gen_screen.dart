import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../widgets/prompt_card.dart';
import '../widgets/gradient_button.dart';

class ImageGenScreen extends StatefulWidget {
  const ImageGenScreen({super.key});

  @override
  State<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends State<ImageGenScreen> {
  final _promptCtrl = TextEditingController();
  final _focusNode  = FocusNode();

  Uint8List? _imageBytes;
  bool   _loading = false;
  String _status  = '';
  bool   _focused = false;

  static const _examples = [
    'A cat wearing a crown on a golden throne',
    'A futuristic city at sunset with flying cars',
    'A magical forest with glowing mushrooms',
    'A steampunk robot reading a book',
    'A cozy coffee shop on a rainy day',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }
    _focusNode.unfocus();
    setState(() { _loading = true; _status = 'Generating AI image...'; _imageBytes = null; });

    try {
      debugPrint('[Image Gen] Generating: $prompt');
      
      // Use backend API for image generation
      final response = await http.post(
        Uri.parse('http://localhost:7863/api/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      ).timeout(const Duration(seconds: 90));

      debugPrint('[Image Gen] Status: ${response.statusCode}');
      debugPrint('[Image Gen] Size: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _status     = 'Generated: "$prompt"';
          _loading    = false;
        });
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        setState(() { _status = 'Error: $error'; _loading = false; });
      }
    } catch (e) {
      debugPrint('[Image Gen] Error: $e');
      setState(() { _status = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Image Generation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            Text('Placeholder images (demo)',
                style: TextStyle(fontSize: 11,
                    color: Colors.white.withOpacity(0.5), letterSpacing: 0.5)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPromptInput(),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Generate Image',
              icon: Icons.auto_awesome_mosaic_rounded,
              loading: _loading,
              onPressed: _generate,
            ),
            const SizedBox(height: 20),
            _buildResultArea(),
            const SizedBox(height: 28),
            _buildExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptInput() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _focused ? AppColors.subtleGlow : null,
      ),
      child: TextField(
        controller: _promptCtrl,
        focusNode: _focusNode,
        maxLines: 3,
        style: const TextStyle(color: Colors.white, letterSpacing: 0.5),
        decoration: InputDecoration(
          hintText: 'Describe the image you want to generate...',
          suffixIcon: _promptCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.white38),
                  onPressed: () => setState(() => _promptCtrl.clear()),
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildResultArea() {
    if (_loading) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Creating your image...',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_imageBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.primaryGlow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _status,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (_status.isNotEmpty) {
      return Text(
        _status,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
        textAlign: TextAlign.center,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3, height: 16,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Suggested Prompts',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._examples.map((e) => PromptCard(
              text: e,
              onTap: () => setState(() => _promptCtrl.text = e),
            )),
      ],
    );
  }
}
