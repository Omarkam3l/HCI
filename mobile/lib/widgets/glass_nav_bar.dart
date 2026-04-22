import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Floating glassmorphic bottom navigation bar.
class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.navBar.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.borderMid),
              boxShadow: AppColors.primaryGlow,
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.85),
              elevation: 0,
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.filter_center_focus_rounded),
                  selectedIcon: Icon(Icons.filter_center_focus_rounded),
                  label: 'Vision',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_mosaic_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
                  label: 'Image Gen',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Lounge',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
