import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../widgets/prompt_card.dart';
import '../widgets/gradient_button.dart';
import '../services/voice_controller.dart';

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
  bool   _listening = false;
  String _status  = '';
  bool   _focused = false;

  static const _examples = [
    'قطة تلبس تاج على عرش ذهبي',
    'مدينة مستقبلية عند غروب الشمس مع سيارات طائرة',
    'غابة سحرية مع فطر متوهج',
    'روبوت بخاري يقرأ كتاب',
    'مقهى مريح في يوم ممطر',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
    VoiceController.initStt();
    // Set Arabic locale for this screen
    VoiceController.setSttLocale('ar-SA');
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _focusNode.dispose();
    VoiceController.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await VoiceController.stopListening();
      setState(() => _listening = false);
      return;
    }
    
    final perm = await Permission.microphone.request();
    if (perm.isDenied || perm.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied.')),
      );
      return;
    }
    
    setState(() => _listening = true);
    await VoiceController.startListening(
      onResult: (text, isFinal) {
        // Keep the Arabic text in the field
        setState(() => _promptCtrl.text = text);
        
        if (isFinal) {
          setState(() => _listening = false);
        }
      },
    );
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
      debugPrint('[Image Gen] Original prompt: $prompt');
      
      // Translate Arabic to English behind the scenes
      String englishPrompt = prompt;
      
      // Check if text contains Arabic characters
      final hasArabic = prompt.runes.any((rune) => rune >= 0x0600 && rune <= 0x06FF);
      
      if (hasArabic) {
        debugPrint('[Image Gen] Detected Arabic, translating...');
        try {
          final translateResponse = await http.post(
            Uri.parse('http://localhost:7863/api/translate-text'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': prompt}),
          );
          
          if (translateResponse.statusCode == 200) {
            final data = jsonDecode(translateResponse.body);
            englishPrompt = data['translated'] ?? prompt;
            debugPrint('[Image Gen] Translated to: $englishPrompt');
          }
        } catch (e) {
          debugPrint('[Image Gen] Translation error: $e');
          // Continue with original text if translation fails
        }
      }
      
      // Use backend API for image generation with English prompt
      final response = await http.post(
        Uri.parse('http://localhost:7863/api/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': englishPrompt}),
      ).timeout(const Duration(seconds: 90));

      debugPrint('[Image Gen] Status: ${response.statusCode}');
      debugPrint('[Image Gen] Size: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _status     = 'Generated: "$prompt"';  // Show original Arabic prompt
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
    return Column(
      children: [
        AnimatedContainer(
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
              hintText: 'صف الصورة التي تريد إنشاءها...',
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
        ),
        const SizedBox(height: 12),
        // Voice input button (Arabic only - translation happens behind the scenes)
        GestureDetector(
          onTap: _loading ? null : _toggleListening,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: _listening ? AppColors.primaryGradient : null,
              color: _listening ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _listening ? Colors.transparent : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _listening ? Colors.white : AppColors.primary2,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _listening ? 'جاري الاستماع...' : 'تحدث بالعربية',
                  style: TextStyle(
                    color: _listening ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              'جاري إنشاء الصورة...',
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
                  _status.isEmpty ? 'تم إنشاء الصورة بنجاح' : _status,
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
