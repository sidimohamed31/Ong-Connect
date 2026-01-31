import 'package:flutter/material.dart';
import '../../data/models/case_model.dart';
import '../../core/theme/charify_theme.dart';
import 'charify_widgets.dart';

class CaseCard extends StatelessWidget {
  final CaseModel socialCase;
  final VoidCallback onTap;

  const CaseCard({super.key, required this.socialCase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CharifyCard(
      onTap: onTap,
      padding:
          EdgeInsets.zero, // Content already has padding or consumes full width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              CharifyNetworkImage(
                imageUrl: socialCase.mainImageUrl,
                height: 180,
                width: double.infinity,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(CharifyTheme.radiusMedium),
                ),
              ),
              // Status Badge
              Positioned(
                top: CharifyTheme.space12,
                right: CharifyTheme.space12,
                child: _buildStatusChip(socialCase.status),
              ),
              // Category Badge
              Positioned(
                bottom: CharifyTheme.space12,
                left: CharifyTheme.space12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CharifyTheme.space12,
                    vertical: CharifyTheme.space6,
                  ),
                  decoration: BoxDecoration(
                    color: CharifyTheme.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(
                      CharifyTheme.radiusRound,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    socialCase.category ?? 'Général',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CharifyTheme.primaryGreenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(CharifyTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  socialCase.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: CharifyTheme.space8),

                // Location with Icon
                if (socialCase.location.wilaya != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: CharifyTheme.mediumGrey,
                      ),
                      const SizedBox(width: CharifyTheme.space4),
                      Text(
                        socialCase.location.wilaya!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                const SizedBox(height: CharifyTheme.space12),

                // Progress Bar (Mockup data since we don't have donation details yet)
                // This adds to the "Charity" feel
                ClipRRect(
                  borderRadius: BorderRadius.circular(CharifyTheme.radiusRound),
                  child: LinearProgressIndicator(
                    value: 0.65, // Example value
                    backgroundColor: CharifyTheme.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      CharifyTheme.primaryGreen,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: CharifyTheme.space8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '65% collectés',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: CharifyTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // ONG Name
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: CharifyTheme.accentOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          socialCase.ong.name,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: CharifyTheme.mediumGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    if (status == 'Urgent') {
      return CharifyStatusChip.urgent('Urgent');
    } else if (status == 'Résolu') {
      return CharifyStatusChip.resolved('Terminé');
    } else {
      return CharifyStatusChip.inProgress('En cours');
    }
  }
}
