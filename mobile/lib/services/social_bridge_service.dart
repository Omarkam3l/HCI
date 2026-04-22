import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'voice_controller.dart';
import 'language_controller.dart';
import 'bilingual_helper.dart';

/// The "Brain" — orchestrates Vision + LLM + Voice for a unified social experience.
class SocialBridgeService {
  // Uses ApiConfig so the key is always in sync with the rest of the app
  static Map<String, String> get _headers => ApiConfig.headers;
  static const String _endpoint = ApiConfig.groqEndpoint;
  static const String chatModel   = ApiConfig.chatModel;
  static const String visionModel = ApiConfig.visionModel;

  static const String _systemPrompt =
      'You are the Sanrio Community Heart, a warm and inclusive AI assistant. '
      'Strictly NO markdown formatting (no *, **, #, or special symbols). '
      'Translate all inputs to suit the recipient\'s accessibility needs. '
      'Use Kawaii vocabulary and gentle, kind language. '
      'For blind users: Describe visual elements in rich, colorful detail. '
      'For deaf users: Include emotional tone tags like [Cheerful], [Excited], [Gentle]. '
      'Always respond with warmth and positivity.';

  // ── Message Stream ────────────────────────────────────────────────────────
  static final _messageController = StreamController<SocialMessage>.broadcast();
  static Stream<SocialMessage> get messageStream => _messageController.stream;

  // ── Input: Voice ──────────────────────────────────────────────────────────

  static Future<void> processVoiceInput({
    required void Function(String transcript) onTranscript,
    required void Function(String error) onError,
    LanguageController? langCtrl,
  }) async {
    await VoiceController.startListening(
      onResult: (text, isFinal) async {
        onTranscript(text);
        if (isFinal && text.isNotEmpty) {
          final response = await _processWithEmotionTags(text, langCtrl);
          final rawTag = _extractEmotionTag(response);
          final localizedTag =
              BilingualHelper.getLocalizedEmotionTag(response, rawTag);

          _messageController.add(SocialMessage(
            role: 'assistant',
            content: response,
            type: MessageType.voiceToText,
            emotionalTag: localizedTag,
          ));
          await VoiceController.speak(ResponseCleaner.clean(response));
        }
      },
    );
  }

  // ── Input: Image ──────────────────────────────────────────────────────────

  static Future<void> processImageInput({
    required Uint8List imageBytes,
    String? userCaption,
  }) async {
    try {
      final visionDescription = await _analyzeImage(imageBytes);
      final story = await _sanriofy(visionDescription, userCaption);

      _messageController.add(SocialMessage(
        role: 'assistant',
        content: story,
        type: MessageType.imageToStory,
        imageBytes: imageBytes,
      ));
      await VoiceController.speak(ResponseCleaner.clean(story));
    } catch (e) {
      debugPrint('[SocialBridge] Image error: $e');
    }
  }

  // ── Input: Text ───────────────────────────────────────────────────────────

  static Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;

    if (!_isKind(text)) {
      _messageController.add(SocialMessage(
        role: 'system',
        content: 'Let\'s keep our community kind and positive!',
        type: MessageType.moderation,
      ));
      return;
    }

    final response = await _chat(text);
    _messageController.add(SocialMessage(
      role: 'assistant',
      content: response,
      type: MessageType.textToText,
      emotionalTag: _extractEmotionTag(response),
    ));
    await VoiceController.speak(ResponseCleaner.clean(response));
  }

  // ── Core AI ───────────────────────────────────────────────────────────────

  static Future<String> _analyzeImage(Uint8List imageBytes) async {
    try {
      final b64 = base64Encode(imageBytes);
      final r = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: jsonEncode({
              'model': visionModel,
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are a Sanrio-style storyteller. Describe this '
                      'image warmly and colorfully. No markdown.',
                },
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': 'Describe this image in a Sanrio-style story.'},
                    {
                      'type': 'image_url',
                      'image_url': {'url': 'data:image/jpeg;base64,$b64'},
                    },
                  ],
                },
              ],
              'max_tokens': 800,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }
      return ApiConfig.parseError(r.statusCode, r.body);
    } catch (_) {
      return 'A lovely scene that brings warmth to the heart.';
    }
  }

  static Future<String> _sanriofy(
      String description, String? userCaption) async {
    final prompt = userCaption != null
        ? 'Turn this into a Sanrio-style story: "$description". User says: "$userCaption"'
        : 'Turn this into a Sanrio-style story: "$description"';
    return _chat(prompt);
  }

  static Future<String> _chat(String userMessage) async {
    try {
      final r = await http
          .post(
            Uri.parse(_endpoint),
            headers: _headers,
            body: jsonEncode({
              'model': chatModel,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.8,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }
      return ApiConfig.parseError(r.statusCode, r.body);
    } catch (_) {
      return 'Let\'s try that again in a moment!';
    }
  }

  static Future<String> _processWithEmotionTags(
      String text, LanguageController? langCtrl) async {
    final suffix = langCtrl?.systemPromptSuffix ?? '';
    return _chat(
      'Add an emotional tone tag at the start (like [Cheerful], [Excited], [Gentle]) '
      'and respond to: "$text"$suffix',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _isKind(String text) {
    final lower = text.toLowerCase();
    return !['hate', 'stupid', 'ugly', 'dumb', 'idiot']
        .any((w) => lower.contains(w));
  }

  static String _extractEmotionTag(String text) {
    final match = RegExp(r'\[([^\]]+)\]').firstMatch(text);
    return match?.group(1) ?? 'Friendly';
  }

  static void dispose() => _messageController.close();
}

// ── Data Models ───────────────────────────────────────────────────────────────

enum MessageType { textToText, voiceToText, imageToStory, moderation }

class SocialMessage {
  final String role;
  final String content;
  final MessageType type;
  final String? emotionalTag;
  final Uint8List? imageBytes;
  final DateTime timestamp;

  SocialMessage({
    required this.role,
    required this.content,
    required this.type,
    this.emotionalTag,
    this.imageBytes,
  }) : timestamp = DateTime.now();

  bool get isVoiceOrigin => type == MessageType.voiceToText;
  bool get hasImage => imageBytes != null;
}

// ── Response Cleaner ──────────────────────────────────────────────────────────

abstract class ResponseCleaner {
  static String clean(String text) => text
      .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
      .replaceAll(RegExp(r'</?think>', dotAll: true), '')
      .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
      .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
      .replaceAll(RegExp(r'#{1,6}\s*'), '')
      .trim();
}
