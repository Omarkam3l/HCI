import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'bilingual_helper.dart';
import 'arabic_tts_service.dart';
import 'api_config.dart';

// Conditional import for web
import 'dart:html' as html if (dart.library.io) 'dart:io';

/// Bilingual Voice Controller — manages STT and TTS with automatic language switching.
///
/// Supports Arabic (ar-SA) and English (en-US) with auto-detection for TTS.
class VoiceController {
  // ── STT ───────────────────────────────────────────────────────────────────
  static final SpeechToText _stt = SpeechToText();
  static bool _sttReady = false;
  static String _currentSttLocale = 'en-US'; // Default

  /// Initialize the STT engine.
  static Future<bool> initStt() async {
    _sttReady = await _stt.initialize(
      onError: (e) => debugPrint('[STT] error: $e'),
    );
    return _sttReady;
  }

  /// Set the STT locale manually (for user preference toggle).
  ///
  /// Valid values: `'en-US'`, `'ar-SA'`, `'ar-EG'`.
  static void setSttLocale(String locale) {
    _currentSttLocale = locale;
    debugPrint('[STT] Locale set to: $locale');
  }

  /// Start listening with the current locale.
  ///
  /// [onResult] receives partial and final transcripts.
  static Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_sttReady) await initStt();
    if (!_sttReady) return;

    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords, result.finalResult),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: _currentSttLocale,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening.
  static Future<void> stopListening() async {
    await _stt.stop();
  }

  /// Whether the STT engine is currently listening.
  static bool get isListening => _stt.isListening;

  // ── TTS ───────────────────────────────────────────────────────────────────
  static final FlutterTts _tts = FlutterTts();
  static bool _ttsReady = false;

  /// Initialize the TTS engine with default English settings.
  static Future<void> initTts() async {
    if (_ttsReady) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _ttsReady = true;
  }

  /// Speak [text] aloud with automatic language detection.
  ///
  /// If the text contains Arabic characters, switches to `ar-SA`.
  /// Otherwise, uses `en-US`.
  /// 
  /// For Arabic: Uses Hugging Face Orpheus model if API key is set,
  /// otherwise falls back to browser voices.
  static Future<void> speak(String text, {void Function()? onComplete}) async {
    if (text.isEmpty) {
      debugPrint('[TTS] Empty text, skipping');
      onComplete?.call();
      return;
    }
    
    // Auto-detect language
    final isArabic = BilingualHelper.isArabic(text);
    final locale = isArabic ? 'ar-SA' : 'en-US';
    
    debugPrint('[TTS] Detected language: ${isArabic ? "Arabic" : "English"}');
    
    // For Arabic on web, try backend TTS first
    if (isArabic && kIsWeb && ApiConfig.isArabicTtsEnabled) {
      debugPrint('[TTS] Using Backend Orpheus Arabic TTS');
      try {
        await ArabicTtsService.speak(text, onComplete: onComplete);
        return;
      } catch (e) {
        debugPrint('[TTS] Backend TTS failed, falling back to browser: $e');
        // Fall through to browser TTS
      }
    }
    
    // Use Web Speech API on web for better Arabic support
    if (kIsWeb) {
      try {
        debugPrint('[TTS] Using Web Speech API for: "${text.substring(0, text.length > 30 ? 30 : text.length)}..."');
        
        final speechSynthesis = html.window.speechSynthesis;
        final utterance = html.SpeechSynthesisUtterance(text);
        
        // Get available voices and select the best one for the language
        final voices = speechSynthesis!.getVoices();
        
        if (isArabic) {
          // Priority list for best Arabic voices (free, built-in)
          // Microsoft Edge has excellent Arabic voices
          final preferredVoiceNames = [
            'Microsoft Hamed - Arabic (Saudi Arabia)',
            'Microsoft Naayf - Arabic (Saudi Arabia)', 
            'Google العربية',
            'Microsoft Salim - Arabic (Saudi Arabia)',
            'Arabic Saudi Arabia',
          ];
          
          html.SpeechSynthesisVoice? selectedVoice;
          
          // Try to find preferred voices first
          for (var preferredName in preferredVoiceNames) {
            selectedVoice = voices.firstWhere(
              (v) => v.name!.contains(preferredName) || v.name == preferredName,
              orElse: () => voices.first,
            );
            if (selectedVoice.name != voices.first.name) break;
          }
          
          // Fallback: find any Arabic voice
          if (selectedVoice == null || selectedVoice.name == voices.first.name) {
            selectedVoice = voices.firstWhere(
              (v) => v.lang == 'ar-SA',
              orElse: () => voices.firstWhere(
                (v) => v.lang == 'ar-EG',
                orElse: () => voices.firstWhere(
                  (v) => v.lang!.startsWith('ar'),
                  orElse: () => voices.first,
                ),
              ),
            );
          }
          
          utterance.voice = selectedVoice;
          utterance.lang = selectedVoice.lang ?? 'ar-SA';
          utterance.rate = 0.85;
          debugPrint('[TTS] Selected Arabic voice: ${selectedVoice.name} (${selectedVoice.lang})');
        } else {
          // Try to find a good English voice
          final preferredEnglishVoices = [
            'Microsoft Zira - English (United States)',
            'Google US English',
            'Microsoft David - English (United States)',
          ];
          
          html.SpeechSynthesisVoice? selectedVoice;
          
          for (var preferredName in preferredEnglishVoices) {
            selectedVoice = voices.firstWhere(
              (v) => v.name!.contains(preferredName) || v.name == preferredName,
              orElse: () => voices.first,
            );
            if (selectedVoice.name != voices.first.name) break;
          }
          
          if (selectedVoice == null || selectedVoice.name == voices.first.name) {
            selectedVoice = voices.firstWhere(
              (v) => v.lang == 'en-US',
              orElse: () => voices.firstWhere(
                (v) => v.lang!.startsWith('en'),
                orElse: () => voices.first,
              ),
            );
          }
          
          utterance.voice = selectedVoice;
          utterance.lang = selectedVoice.lang ?? 'en-US';
          utterance.rate = 0.9;
          debugPrint('[TTS] Selected English voice: ${selectedVoice.name} (${selectedVoice.lang})');
        }
        
        utterance.pitch = 1.0;
        utterance.volume = 1.0;
        
        utterance.onEnd.listen((_) {
          debugPrint('[TTS] Web Speech completed');
          onComplete?.call();
        });
        
        utterance.onError.listen((error) {
          debugPrint('[TTS] Web Speech error: $error');
          onComplete?.call();
        });
        
        speechSynthesis.speak(utterance);
        debugPrint('[TTS] Web Speech started');
      } catch (e) {
        debugPrint('[TTS] Web Speech API error: $e');
        onComplete?.call();
      }
    } else {
      // Use flutter_tts for mobile platforms
      await initTts();
      
      try {
        await _tts.setLanguage(locale);
        
        // Adjust speech rate for Arabic (slightly slower for clarity)
        if (isArabic) {
          await _tts.setSpeechRate(0.45);
        } else {
          await _tts.setSpeechRate(0.5);
        }

        debugPrint('[TTS] Speaking in $locale: "${text.substring(0, text.length > 30 ? 30 : text.length)}..."');

        if (onComplete != null) {
          _tts.setCompletionHandler(onComplete);
        }
        
        final result = await _tts.speak(text);
        debugPrint('[TTS] Speak result: $result');
        
        if (result == 0) {
          debugPrint('[TTS] Failed to speak - result code 0');
          onComplete?.call();
        }
      } catch (e) {
        debugPrint('[TTS] Error: $e');
        onComplete?.call();
      }
    }
  }

  /// Stop any ongoing speech.
  static Future<void> stop() async {
    if (kIsWeb) {
      try {
        html.window.speechSynthesis?.cancel();
        debugPrint('[TTS] Web Speech cancelled');
      } catch (e) {
        debugPrint('[TTS] Error cancelling Web Speech: $e');
      }
    } else {
      await _tts.stop();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Get available locales for STT (for UI picker).
  static Future<List<String>> getAvailableLocales() async {
    if (!_sttReady) await initStt();
    final locales = await _stt.locales();
    return locales
        .where((l) => l.localeId.startsWith('en') || l.localeId.startsWith('ar'))
        .map((l) => l.localeId)
        .toList();
  }

  /// Get the current STT locale.
  static String get currentSttLocale => _currentSttLocale;
  
  /// Get available TTS voices (web only, for debugging).
  static List<String> getAvailableVoices() {
    if (!kIsWeb) return [];
    try {
      final voices = html.window.speechSynthesis!.getVoices();
      return voices.map((v) => '${v.name} (${v.lang})').toList();
    } catch (e) {
      debugPrint('[TTS] Error getting voices: $e');
      return [];
    }
  }
  
  /// Print available voices to console (for debugging).
  static void printAvailableVoices() {
    if (!kIsWeb) {
      debugPrint('[TTS] Voice listing only available on web');
      return;
    }
    try {
      final voices = html.window.speechSynthesis!.getVoices();
      debugPrint('[TTS] Available voices (${voices.length}):');
      for (var voice in voices) {
        final isLocal = voice.localService == true ? "[Local]" : "[Remote]";
        debugPrint('  - ${voice.name} (${voice.lang}) $isLocal');
      }
    } catch (e) {
      debugPrint('[TTS] Error listing voices: $e');
    }
  }
}
