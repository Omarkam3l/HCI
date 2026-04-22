import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
abstract class AppColors {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const scaffold  = Color(0xFF1A1A2E); // deep navy
  static const surface   = Color(0xFF16213E); // card / input
  static const navBar    = Color(0xFF0F3460); // app-bar / bottom nav

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const primary   = Color(0xFF6750A4); // purple seed
  static const primary2  = Color(0xFF845EC2); // lighter purple
  static const accent    = Color(0xFFE94560); // hot pink / secondary

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [primary, primary2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const buttonGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const userBubbleGradient = LinearGradient(
    colors: [primary, Color(0xFF9B59B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow / Shadow ──────────────────────────────────────────────────────────
  static const glowColor = Color(0x4D6750A4); // primary @ 30 %

  static List<BoxShadow> get primaryGlow => [
        const BoxShadow(
          color: glowColor,
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> get subtleGlow => [
        const BoxShadow(
          color: glowColor,
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  // ── Borders ────────────────────────────────────────────────────────────────
  static const borderSubtle = Colors.white10;
  static const borderMid    = Colors.white12;
  static const borderBright = Colors.white24;
}
