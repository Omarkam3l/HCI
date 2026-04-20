import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _apiKey =
      'YOUR_GROQ_API_KEY_HERE'; // Replace with your actual Groq API key
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String chatModel = 'qwen/qwen3-32b';
  static const String visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };

  /// Text-only chat (Qwen3-32B)
  static Future<String> chat(List<Map<String, String>> messages) async {
    try {
      print('Sending request to Groq API with model: $chatModel');
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: jsonEncode({
              'model': chatModel,
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 2048,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('Groq API Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        print('Groq API Response received successfully');
        return content;
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      print('Groq API Exception: $e');
      return 'Error: $e';
    }
  }

  /// Vision analysis (Llama 4 Scout)
  static Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String question,
  }) async {
    try {
      final b64 = base64Encode(imageBytes);

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: jsonEncode({
              'model': visionModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are an accessibility assistant for blind and visually impaired people. '
                          'Describe images in rich, clear detail covering colors, shapes, objects, people, '
                          'text, emotions, and spatial layout. Write in plain sentences without any markdown.',
                },
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': question},
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$b64',
                      },
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
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return 'Error ${response.statusCode}: ${response.body}';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
