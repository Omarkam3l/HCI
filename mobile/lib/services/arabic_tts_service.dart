import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'dart:html' as html if (dart.library.io) 'dart:io';

/// Arabic TTS service using backend proxy for Orpheus model
class ArabicTtsService {
  /// Generate Arabic speech from text using backend API
  static Future<Uint8List?> generateSpeech(String text) async {
    try {
      debugPrint('[Arabic TTS] Generating speech via backend for: "${text.substring(0, text.length > 30 ? 30 : text.length)}..."');

      final response = await http.post(
        Uri.parse(ApiConfig.arabicTtsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('[Arabic TTS] Speech generated successfully');
        return response.bodyBytes;
      } else {
        debugPrint('[Arabic TTS] Error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Arabic TTS] Exception: $e');
      return null;
    }
  }

  /// Play audio bytes in the browser
  static void playAudioInBrowser(Uint8List audioBytes, {void Function()? onComplete}) {
    if (!kIsWeb) {
      debugPrint('[Arabic TTS] playAudioInBrowser only works on web');
      onComplete?.call();
      return;
    }

    try {
      // Create a blob from the audio bytes
      final blob = html.Blob([audioBytes], 'audio/wav');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Create an audio element
      final audio = html.AudioElement(url);
      
      audio.onEnded.listen((_) {
        debugPrint('[Arabic TTS] Audio playback completed');
        html.Url.revokeObjectUrl(url);
        onComplete?.call();
      });
      
      audio.onError.listen((error) {
        debugPrint('[Arabic TTS] Audio playback error: $error');
        html.Url.revokeObjectUrl(url);
        onComplete?.call();
      });
      
      audio.play();
      debugPrint('[Arabic TTS] Audio playback started');
    } catch (e) {
      debugPrint('[Arabic TTS] Error playing audio: $e');
      onComplete?.call();
    }
  }

  /// Generate and play Arabic speech
  static Future<void> speak(String text, {void Function()? onComplete}) async {
    final audioBytes = await generateSpeech(text);
    
    if (audioBytes != null) {
      playAudioInBrowser(audioBytes, onComplete: onComplete);
    } else {
      debugPrint('[Arabic TTS] Failed to generate speech, falling back');
      onComplete?.call();
    }
  }
}
