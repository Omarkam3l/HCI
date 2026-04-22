import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Full-width gradient button with optional loading state.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;
  final LinearGradient gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    this.loading = false,
    this.onPressed,
    this.gradient = AppColors.buttonGradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: loading ? null : gradient,
          color: loading ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading ? null : AppColors.subtleGlow,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white70),
              )
            else
              Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              loading ? 'Please wait...' : label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
