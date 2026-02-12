import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/api_service.dart';
import '../../core/theme/charify_theme.dart';
import '../widgets/charify_widgets.dart';
import 'package:ong_mobile_app/l10n/app_localizations.dart';
import 'case_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _apiService.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: CharifyTheme.backgroundGrey,
      appBar: AppBar(title: Text(loc.notifications), centerTitle: true),
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: CharifyTheme.primaryGreen,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: CharifyEmptyState(
                icon: Icons.error_outline_rounded,
                title: loc.error,
                subtitle: loc.genericError,
                actionLabel: loc.retry,
                onActionPressed: () {
                  setState(() {
                    _notificationsFuture = _apiService.getNotifications();
                  });
                },
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: CharifyEmptyState(
                icon: Icons.notifications_none_rounded,
                title: loc.noNotifications,
                subtitle: "",
              ),
            );
          }

          final notifications = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _notificationsFuture = _apiService.getNotifications();
              });
              await _notificationsFuture;
            },
            color: CharifyTheme.primaryGreen,
            child: ListView.separated(
              padding: const EdgeInsets.all(CharifyTheme.space16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: CharifyTheme.space12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  isArabic: isArabic,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isArabic;

  const _NotificationCard({required this.notification, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
        side: const BorderSide(color: CharifyTheme.lightGrey, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (notification.idCasSocial != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CaseDetailsScreen(caseId: notification.idCasSocial!),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(CharifyTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(CharifyTheme.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CharifyTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: CharifyTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: CharifyTheme.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? notification.messageAr
                          : notification.messageFr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CharifyTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: CharifyTheme.space6),
                    Text(
                      DateFormat.yMMMd().add_jm().format(
                        notification.dateNotification,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CharifyTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (notification.image != null &&
                  notification.image!.isNotEmpty) ...[
                const SizedBox(width: CharifyTheme.space12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(CharifyTheme.radiusSmall),
                  child: CharifyNetworkImage(
                    imageUrl: notification.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
