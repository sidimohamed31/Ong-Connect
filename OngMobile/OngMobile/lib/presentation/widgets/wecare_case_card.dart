import 'package:flutter/material.dart';
import '../../data/models/case_model.dart';
import '../../core/theme/charify_theme.dart';
import 'charify_widgets.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

/// Wecare-style case card for grid/list display
class WecareCaseCard extends StatelessWidget {
  final CaseModel socialCase;
  final VoidCallback onTap;
  final bool isGridView;

  const WecareCaseCard({
    super.key,
    required this.socialCase,
    required this.onTap,
    this.isGridView = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridCard(context);
    } else {
      return _buildListCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
        child: Container(
          decoration: BoxDecoration(
            color: CharifyTheme.white,
            borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image with category badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(CharifyTheme.radiusMedium),
                    ),
                    child: CharifyNetworkImage(
                      imageUrl: socialCase.mainImageUrl,
                      height: 130,
                      width: double.infinity,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(CharifyTheme.radiusMedium),
                      ),
                    ),
                  ),
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: 8,
                    end: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(loc),
                        borderRadius: BorderRadius.circular(
                          CharifyTheme.radiusRound,
                        ),
                      ),
                      child: Text(
                        _getCategoryDisplay(loc),
                        style: const TextStyle(
                          color: CharifyTheme.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        socialCase.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CharifyTheme.darkGrey,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Progress bar (showing case urgency/support)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          CharifyTheme.radiusRound,
                        ),
                        child: LinearProgressIndicator(
                          value: _getProgressValue(),
                          backgroundColor: CharifyTheme.lightGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(loc),
                          ),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Support metric
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${(_getProgressValue() * 100).toInt()}% ${loc.processed}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(loc),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Days indicator
                          if (socialCase.date != null)
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: CharifyTheme.mediumGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getDaysAgo(loc),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: CharifyTheme.mediumGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: CharifyTheme.space12),
        decoration: BoxDecoration(
          color: CharifyTheme.white,
          borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(CharifyTheme.radiusMedium),
              ),
              child: CharifyNetworkImage(
                imageUrl: socialCase.mainImageUrl,
                height: 100,
                width: 100,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(CharifyTheme.radiusMedium),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            socialCase.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CharifyTheme.darkGrey,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(loc),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getCategoryDisplay(loc),
                            style: const TextStyle(
                              color: CharifyTheme.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        CharifyTheme.radiusRound,
                      ),
                      child: LinearProgressIndicator(
                        value: _getProgressValue(),
                        backgroundColor: CharifyTheme.lightGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusColor(loc),
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_getProgressValue() * 100).toInt()}% ${loc.processed}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(loc),
                          ),
                        ),
                        if (socialCase.date != null)
                          Text(
                            _getDaysAgo(loc),
                            style: const TextStyle(
                              fontSize: 10,
                              color: CharifyTheme.mediumGrey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplay(AppLocalizations loc) {
    final cat = socialCase.category?.toLowerCase() ?? '';
    switch (cat) {
      case 'santé':
      case 'health':
        return loc.health;
      case 'éducation':
      case 'education':
        return loc.education;
      case 'alimentation':
      case 'food':
        return loc.food;
      case 'logement':
      case 'housing':
        return loc.housing;
      case 'eau':
      case 'water':
        return loc.water;
      default:
        // Attempt to match by name if not in switch
        final lowCat = cat.toLowerCase();
        if (lowCat.contains('santé') || lowCat.contains('health'))
          return loc.health;
        if (lowCat.contains('éduc') || lowCat.contains('educ'))
          return loc.education;
        if (lowCat.contains('alim') || lowCat.contains('food')) return loc.food;
        if (lowCat.contains('loge') || lowCat.contains('hous'))
          return loc.housing;
        if (lowCat.contains('eau') || lowCat.contains('water'))
          return loc.water;
        return socialCase.category ?? loc.general;
    }
  }

  Color _getCategoryColor(AppLocalizations loc) {
    if (socialCase.category == null) return CharifyTheme.primaryGreen;

    // We map based on known values or check localized match if needed,
    // but color logic usually depends on fixed keys.
    // If backend returns 'Santé' or 'Health', we want specific colors.
    switch (socialCase.category!.toLowerCase()) {
      case 'santé':
      case 'health':
      case 'medical':
        return const Color(0xFFFF6B6B);
      case 'éducation':
      case 'education':
        return const Color(0xFF4ECDC4);
      case 'alimentation':
      case 'food':
        return const Color(0xFFFFBE0B);
      case 'logement':
      case 'housing':
        return const Color(0xFF8B5CF6);
      case 'eau':
      case 'water':
        return const Color(0xFF4A90E2);
      default:
        final lowCat = socialCase.category!.toLowerCase();
        if (lowCat.contains('santé') || lowCat.contains('health'))
          return const Color(0xFFFF6B6B);
        if (lowCat.contains('éduc') || lowCat.contains('educ'))
          return const Color(0xFF4ECDC4);
        if (lowCat.contains('alim') || lowCat.contains('food'))
          return const Color(0xFFFFBE0B);
        if (lowCat.contains('loge') || lowCat.contains('hous'))
          return const Color(0xFF8B5CF6);
        if (lowCat.contains('eau') || lowCat.contains('water'))
          return const Color(0xFF4A90E2);
        return CharifyTheme.primaryGreen;
    }
  }

  Color _getStatusColor(AppLocalizations loc) {
    if (socialCase.status == 'Urgent') {
      return CharifyTheme.dangerRed;
    } else if (socialCase.status == 'Résolu') {
      return CharifyTheme.successGreen;
    } else {
      return CharifyTheme.warningYellow;
    }
  }

  double _getProgressValue() {
    if (socialCase.status == 'Résolu') {
      return 1.0;
    } else if (socialCase.status == 'Urgent') {
      return 0.3;
    } else {
      return 0.65; // En cours
    }
  }

  String _getDaysAgo(AppLocalizations loc) {
    if (socialCase.date == null) return '';
    try {
      final date = DateTime.parse(socialCase.date!);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return loc.today;
      } else if (difference.inDays == 1) {
        return loc.oneDay;
      } else if (difference.inDays < 30) {
        return '${difference.inDays} ${loc.days}';
      } else {
        return '${(difference.inDays / 30).floor()} ${loc.months}';
      }
    } catch (e) {
      return '';
    }
  }
}
