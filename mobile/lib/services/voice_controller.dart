import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'bilingual_helper.dart';

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
  static Future<void> speak(String text, {void Function()? onComplete}) async {
    await initTts();

    // Auto-detect language and switch TTS locale
    final isArabic = BilingualHelper.isArabic(text);
    final locale = isArabic ? 'ar-SA' : 'en-US';
    
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
    await _tts.speak(text);
  }

  /// Stop any ongoing speech.
  static Future<void> stop() async {
    await _tts.stop();
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
}
