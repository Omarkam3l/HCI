import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Handles all AI API calls for the standard screens (Vision, Chat, Image Gen).
class AiService {
  static const String _systemPrompt =
      'You are a helpful AI assistant. Be friendly and conversational. '
      'Respond directly without showing your thinking process. '
      'Do not use markdown formatting.';

  // ── Chat ──────────────────────────────────────────────────────────────────

  static Future<String> getChatResponse(
    List<Map<String, String>> messages,
  ) async {
    if (!ApiConfig.isKeySet) {
      return 'No API key set. Tap the key icon in the top bar to add one.';
    }
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.groqEndpoint),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'model': ApiConfig.chatModel,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                ...messages,
              ],
              'temperature': 0.7,
              'max_tokens': 2048,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }
      return ApiConfig.parseError(response.statusCode, response.body);
    } on http.ClientException {
      return 'Network error. Check your connection and try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Vision ────────────────────────────────────────────────────────────────

  static Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String question,
  }) async {
    if (!ApiConfig.isKeySet) {
      return 'No API key set. Tap the key icon in the top bar to add one.';
    }
    try {
      final b64 = base64Encode(imageBytes);
      final response = await http
          .post(
            Uri.parse(ApiConfig.groqEndpoint),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'model': ApiConfig.visionModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an accessibility assistant for blind and visually impaired people. '
                      'Describe images in rich, clear detail. No markdown.',
                },
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': question},
                    {
                      'type': 'image_url',
                      'image_url': {'url': 'data:image/jpeg;base64,$b64'},
                    },
                  ],
                },
              ],
              'max_tokens': 1024,
              'temperature': 0.5,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }
      return ApiConfig.parseError(response.statusCode, response.body);
    } on http.ClientException {
      return 'Network error. Check your connection and try again.';
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String cleanResponse(String text) {
    return text
        .replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '')
        .replaceAll(RegExp(r'</?think>', dotAll: true), '')
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .trim();
  }
}
