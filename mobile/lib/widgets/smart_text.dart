import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bilingual_helper.dart';

/// A smart text widget that auto-detects language and applies:
///   - Correct font (Cairo for Arabic, Poppins for English)
///   - Correct text direction (RTL for Arabic, LTR for English)
///   - Appropriate font weight (heavier for Arabic in dark mode)
class SmartText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SmartText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = BilingualHelper.isArabic(text);
    final direction = BilingualHelper.getTextDirection(text);
    final align = textAlign ?? BilingualHelper.getTextAlign(text);

    // Choose font based on language
    final baseStyle = isArabic
        ? GoogleFonts.cairo(
            fontWeight: FontWeight.w500, // Heavier for readability in dark mode
            letterSpacing: 0.3,
          )
        : GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          );

    // Merge with provided style
    final finalStyle = baseStyle.merge(style);

    return Directionality(
      textDirection: direction,
      child: Text(
        text,
        style: finalStyle,
        textAlign: align,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

/// A smart text widget specifically for chat bubbles.
///
/// Adds extra padding and line height for better readability.
class SmartChatText extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;

  const SmartChatText(
    this.text, {
    super.key,
    this.color,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SmartText(
      text,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.6,
        color: color ?? Colors.white.withValues(alpha: 0.85),
        letterSpacing: 0.3,
      ),
    );
  }
}

/// A smart text widget for headings/titles.
class SmartHeading extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;

  const SmartHeading(
    this.text, {
    super.key,
    this.fontSize = 18,
    this.fontWeight,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = BilingualHelper.isArabic(text);
    
    return SmartText(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight ?? (isArabic ? FontWeight.w700 : FontWeight.w600),
        color: color ?? Colors.white,
        letterSpacing: isArabic ? 0.3 : 0.5,
      ),
    );
  }
}
