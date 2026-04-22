import 'package:flutter/material.dart';

/// Utility class for detecting and handling Arabic vs English text.
abstract class BilingualHelper {
  // ── Language Detection ────────────────────────────────────────────────────

  /// Returns `true` if the text contains Arabic characters.
  ///
  /// Uses Unicode range U+0600 to U+06FF (Arabic block).
  static bool isArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Returns `true` if the text is primarily English (Latin characters).
  static bool isEnglish(String text) {
    return RegExp(r'[a-zA-Z]').hasMatch(text) && !isArabic(text);
  }

  /// Detects the primary language and returns the locale code.
  ///
  /// Returns `'ar-SA'` for Arabic, `'en-US'` for English.
  static String detectLocale(String text) {
    return isArabic(text) ? 'ar-SA' : 'en-US';
  }

  // ── Text Direction ────────────────────────────────────────────────────────

  /// Returns the appropriate [TextDirection] for the given text.
  ///
  /// Arabic → RTL, English → LTR.
  static TextDirection getTextDirection(String text) {
    return isArabic(text) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Returns the appropriate [TextAlign] for the given text.
  ///
  /// Always uses `TextAlign.start` to respect directionality.
  static TextAlign getTextAlign(String text) {
    return TextAlign.start;
  }

  // ── Emotional Tags (Bilingual) ────────────────────────────────────────────

  /// Translates English emotional tags to Arabic.
  ///
  /// Used for Deaf users when voice input is in Arabic.
  static String translateEmotionTag(String tag) {
    final translations = {
      'Cheerful':  'نبرة سعيدة',
      'Excited':   'نبرة متحمسة',
      'Gentle':    'نبرة لطيفة',
      'Urgent':    'نبرة عاجلة',
      'Calm':      'نبرة هادئة',
      'Friendly':  'نبرة ودية',
      'Warm':      'نبرة دافئة',
    };
    return translations[tag] ?? tag;
  }

  /// Extracts and translates emotional tags from AI responses.
  ///
  /// If the response is in Arabic, translates the tag to Arabic.
  static String getLocalizedEmotionTag(String response, String tag) {
    return isArabic(response) ? translateEmotionTag(tag) : tag;
  }

  // ── Sanrio Localization ───────────────────────────────────────────────────

  /// Returns Sanrio-style greetings in the appropriate language.
  static String getSanrioGreeting(String text) {
    if (isArabic(text)) {
      return 'أهلاً يا صديقي'; // "Ahlan ya Sadiqi" (Hello my friend)
    }
    return 'Hello friend';
  }

  /// Returns Sanrio-style farewell in the appropriate language.
  static String getSanrioFarewell(String text) {
    if (isArabic(text)) {
      return 'مع السلامة'; // "Ma'a as-salama" (Goodbye)
    }
    return 'Take care';
  }
}
