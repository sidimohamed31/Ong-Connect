import 'package:flutter/material.dart';
import '../../core/theme/charify_theme.dart';

import 'package:ong_mobile_app/l10n/app_localizations.dart';

/// Bottom navigation bar following Wecare design
class WecareBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const WecareBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: CharifyTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CharifyTheme.space16,
            vertical: CharifyTheme.space12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: loc.home,
                index: 0,
                isSelected: currentIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.grid_view_rounded,
                label: loc.browse,
                index: 1,
                isSelected: currentIndex == 1,
              ),
              _buildCenterButton(),
              _buildNavItem(
                icon: Icons.bar_chart_rounded,
                label: loc.stats,
                index: 3,
                isSelected: currentIndex == 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: loc.profile,
                index: 4,
                isSelected: currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CharifyTheme.space12,
          vertical: CharifyTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? CharifyTheme.primaryGreen.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CharifyTheme.primaryGreen
                  : CharifyTheme.mediumGrey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? CharifyTheme.primaryGreen
                    : CharifyTheme.mediumGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: CharifyTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: CharifyTheme.primaryGreen.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.map_outlined,
          color: CharifyTheme.white,
          size: 28,
        ),
      ),
    );
  }
}
