import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/case_model.dart';
import '../../core/theme/charify_theme.dart';
import '../../data/services/api_service.dart';
import '../widgets/charify_widgets.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';

class CaseDetailsScreen extends StatelessWidget {
  final int caseId;
  final ApiService _apiService = ApiService();

  CaseDetailsScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: CharifyTheme.backgroundGrey,
      body: FutureBuilder<CaseModel>(
        future: _apiService.getCaseDetails(caseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: CharifyTheme.primaryGreen,
              ),
            );
          } else if (snapshot.hasError) {
            return CharifyEmptyState(
              icon: Icons.error_outline_rounded,
              title: loc.error,
              subtitle: loc.errorLoadingDetails,
              actionLabel: loc.back,
              onActionPressed: () => Navigator.pop(context),
            );
          } else if (!snapshot.hasData) {
            return Center(child: Text(loc.caseNotFound));
          }

          final socialCase = snapshot.data!;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Hero Image with back button
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    stretch: true,
                    backgroundColor: CharifyTheme.white,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Share.share(
                              loc.shareText(
                                socialCase.title,
                                socialCase.description ?? "",
                                socialCase.location.wilaya ?? loc.unavailable,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CharifyNetworkImage(
                            imageUrl: socialCase.mainImageUrl,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.zero,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                                stops: const [0.7, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: CharifyTheme.backgroundGrey,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category and Status Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      socialCase.category,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getCategoryDisplay(
                                      socialCase.category,
                                      loc,
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      color: CharifyTheme.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(context, socialCase.status),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              socialCase.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Progress Card (Wecare-style)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CharifyTheme.white,
                                borderRadius: BorderRadius.circular(
                                  CharifyTheme.radiusMedium,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        loc.caseStatus,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${(_getProgressValue(socialCase.status) * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                            socialCase.status,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      CharifyTheme.radiusRound,
                                    ),
                                    child: LinearProgressIndicator(
                                      value: _getProgressValue(
                                        socialCase.status,
                                      ),
                                      backgroundColor: CharifyTheme.lightGrey,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getStatusColor(socialCase.status),
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: CharifyTheme.mediumGrey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${loc.publishedOn} ${socialCase.date ?? loc.unavailable}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: CharifyTheme.mediumGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Description Section
                            Text(
                              loc.description,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CharifyTheme.white,
                                borderRadius: BorderRadius.circular(
                                  CharifyTheme.radiusMedium,
                                ),
                              ),
                              child: Text(
                                socialCase.description ?? loc.noDescription,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: CharifyTheme.darkGrey,
                                      height: 1.6,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Location
                            if (socialCase.location.wilaya != null) ...[
                              Text(
                                loc.wilaya,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: CharifyTheme.white,
                                  borderRadius: BorderRadius.circular(
                                    CharifyTheme.radiusMedium,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CharifyTheme.primaryGreen
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          CharifyTheme.radiusSmall,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.location_on_outlined,
                                        color: CharifyTheme.primaryGreen,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            socialCase.location.wilaya!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (socialCase.location.moughataa !=
                                              null)
                                            Text(
                                              socialCase.location.moughataa!,
                                              style: const TextStyle(
                                                color: CharifyTheme.mediumGrey,
                                                fontSize: 13,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Organizer (ONG) Section
                            Text(
                              loc.organizer,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CharifyTheme.white,
                                borderRadius: BorderRadius.circular(
                                  CharifyTheme.radiusMedium,
                                ),
                                border: Border.all(
                                  color: CharifyTheme.lightGrey,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CharifyTheme.lightGrey,
                                      image: socialCase.ong.logoUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                socialCase.ong.logoUrl,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: socialCase.ong.logoUrl.isEmpty
                                        ? const Icon(
                                            Icons.business,
                                            color: CharifyTheme.mediumGrey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          socialCase.ong.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: CharifyTheme.darkGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.verified,
                                              size: 14,
                                              color: CharifyTheme.primaryGreen,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              loc.verifiedOng,
                                              style: TextStyle(
                                                color:
                                                    CharifyTheme.primaryGreen,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Sticky Bottom Action Buttons
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchEmail(socialCase.ong.email),
                            icon: const Icon(Icons.email_outlined),
                            label: Text(loc.sendEmail),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: CharifyTheme.primaryGreen,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  CharifyTheme.radiusMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _launchCaller(socialCase.ong.phone),
                            icon: const Icon(Icons.phone),
                            label: Text(loc.call),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CharifyTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  CharifyTheme.radiusMedium,
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String? status) {
    Color color;
    String label;
    final loc = AppLocalizations.of(context)!;

    if (status == 'Urgent') {
      color = CharifyTheme.dangerRed;
      label = loc.urgent;
    } else if (status == 'Résolu') {
      color = CharifyTheme.successGreen;
      label = loc.statusResolved;
    } else {
      color = CharifyTheme.warningYellow;
      label = loc.statusInProgress;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getCategoryDisplay(String? category, AppLocalizations loc) {
    switch (category?.toLowerCase()) {
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
        return category ?? loc.general;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'santé':
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
      default:
        return CharifyTheme.primaryGreen;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == 'Urgent') {
      return CharifyTheme.dangerRed;
    } else if (status == 'Résolu') {
      return CharifyTheme.successGreen;
    } else {
      return CharifyTheme.warningYellow;
    }
  }

  double _getProgressValue(String? status) {
    if (status == 'Résolu') {
      return 1.0;
    } else if (status == 'Urgent') {
      return 0.3;
    } else {
      return 0.65;
    }
  }

  void _launchCaller(String? phone) async {
    if (phone != null) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _launchEmail(String? email) async {
    if (email != null) {
      final uri = Uri.parse('mailto:$email');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
