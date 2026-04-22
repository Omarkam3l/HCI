import 'package:flutter/material.dart';
import '../services/voice_controller.dart';
import '../theme/app_colors.dart';

/// A compact segmented toggle for switching voice language between
/// English (en-US) and Arabic (ar-SA).
///
/// Calls [VoiceController.setSttLocale] on change and rebuilds via setState.
/// Drop it anywhere — AppBar actions, above a mic button, etc.
class VoiceLanguagePicker extends StatefulWidget {
  /// Called after the locale is changed, with the new locale string.
  final void Function(String locale)? onChanged;

  const VoiceLanguagePicker({super.key, this.onChanged});

  @override
  State<VoiceLanguagePicker> createState() => _VoiceLanguagePickerState();
}

class _VoiceLanguagePickerState extends State<VoiceLanguagePicker> {
  // Mirrors VoiceController's current locale
  bool _isArabic = VoiceController.currentSttLocale.startsWith('ar');

  void _select(bool arabic) {
    if (_isArabic == arabic) return;
    setState(() => _isArabic = arabic);
    final locale = arabic ? 'ar-SA' : 'en-US';
    VoiceController.setSttLocale(locale);
    widget.onChanged?.call(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderMid),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            label: 'EN',
            icon: Icons.language_rounded,
            selected: !_isArabic,
            onTap: () => _select(false),
          ),
          Container(width: 1, height: 20, color: AppColors.borderMid),
          _Tab(
            label: 'ع',
            icon: Icons.translate_rounded,
            selected: _isArabic,
            onTap: () => _select(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : Colors.white38,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? Colors.white : Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
