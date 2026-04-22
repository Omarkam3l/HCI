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
      final requestBody = {
        'model': ApiConfig.visionModel,
        'messages': [
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
      };
      
      print('Sending request to: ${ApiConfig.groqEndpoint}');
      print('Model: ${ApiConfig.visionModel}');
      
      final response = await http
          .post(
            Uri.parse(ApiConfig.groqEndpoint),
            headers: ApiConfig.headers,
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      }
      
      // Return detailed error for debugging
      try {
        final errorData = jsonDecode(response.body);
        return 'API Error (${response.statusCode}): ${errorData['error']?['message'] ?? response.body}';
      } catch (_) {
        return 'API Error (${response.statusCode}): ${response.body}';
      }
    } on http.ClientException catch (e) {
      return 'Network error: $e';
    } catch (e) {
      return 'Error: $e';
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
        .replaceAll(RegExp(r'\$1\s*\$1\s*'), '') // Remove double $1 $1
        .replaceAll(RegExp(r'^\$1\s*'), '') // Remove $1 at start of line
        .replaceAll(RegExp(r'\s*\$1\s*'), ' ') // Replace $1 with space
        .replaceAll(RegExp(r'\*\s*\$1\s*'), '* ') // Fix bullet points with $1
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
}
