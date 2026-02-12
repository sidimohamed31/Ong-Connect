import '../../core/constants/api_constants.dart';

class NotificationModel {
  final int id;
  final int? idCasSocial;
  final String messageFr;
  final String messageAr;
  final DateTime dateNotification;
  final bool isRead;
  final String? titre;
  final String? description;
  final String? image;

  NotificationModel({
    required this.id,
    this.idCasSocial,
    required this.messageFr,
    required this.messageAr,
    required this.dateNotification,
    required this.isRead,
    this.titre,
    this.description,
    this.image,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id_notification'],
      idCasSocial: json['id_cas_social'],
      messageFr: json['message_fr'],
      messageAr: json['message_ar'],
      dateNotification: DateTime.parse(json['date_notification']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      titre: json['titre'],
      description: json['description'],
      image: json['image'],
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http')) return image!;

    // Normalize path
    String cleanPath = image!.replaceAll("\\", "/");
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // If it's already a full static path from backend
    if (cleanPath.startsWith('static/')) {
      return '${ApiConstants.rootUrl}/$cleanPath';
    }

    return '${ApiConstants.rootUrl}/static/$cleanPath';
  }
}
