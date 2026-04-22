import 'package:flutter/material.dart';
import 'bilingual_helper.dart';
import 'voice_controller.dart';

/// Manages the app-wide language preference and exposes language-switching logic.
///
/// Integrates with [VoiceController] to keep STT locale in sync.
class LanguageController extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────

  /// The user's preferred input language.
  ///
  /// `true` = Arabic (ar-SA), `false` = English (en-US).
  bool _preferArabic = false;
  bool get preferArabic => _preferArabic;

  String get currentLocale => _preferArabic ? 'ar-SA' : 'en-US';
  String get currentLanguageLabel => _preferArabic ? 'العربية' : 'English';
  TextDirection get appDirection =>
      _preferArabic ? TextDirection.rtl : TextDirection.ltr;

  // ── Toggle ────────────────────────────────────────────────────────────────

  /// Toggle between Arabic and English.
  void toggleLanguage() {
    _preferArabic = !_preferArabic;
    VoiceController.setSttLocale(currentLocale);
    notifyListeners();
    debugPrint('[Language] Switched to: $currentLocale');
  }

  /// Set language explicitly.
  void setArabic(bool value) {
    if (_preferArabic == value) return;
    _preferArabic = value;
    VoiceController.setSttLocale(currentLocale);
    notifyListeners();
  }

  // ── Per-Content Detection ─────────────────────────────────────────────────

  /// Detect the language of a specific string (overrides user preference for display).
  ///
  /// Used to render each chat bubble in the correct direction regardless of
  /// the global preference.
  static TextDirection directionOf(String text) =>
      BilingualHelper.getTextDirection(text);

  static bool isArabic(String text) => BilingualHelper.isArabic(text);

  // ── System Prompt Builder ─────────────────────────────────────────────────

  /// Returns a bilingual system prompt suffix based on the current language.
  String get systemPromptSuffix {
    if (_preferArabic) {
      return ' عندما يكتب المستخدم بالعربية، رد بالعربية. '
          'استخدم مصطلحات ودية مثل "يا صديقي" و"أهلاً". '
          'أضف وسوم عاطفية مثل [نبرة سعيدة] أو [نبرة لطيفة] للمستخدمين الصم.';
    }
    return ' When the user writes in English, respond in English. '
        'Use friendly terms like "dear friend" and "welcome". '
        'Add emotional tags like [Cheerful] or [Gentle] for Deaf users.';
  }
}
