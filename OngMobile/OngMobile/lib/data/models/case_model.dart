import '../../core/constants/api_constants.dart';

class Ong {
  final int id;
  final String name;
  final String? logo;
  final String? phone;
  final String? email;
  final String? address;

  Ong({
    required this.id,
    required this.name,
    this.logo,
    this.phone,
    this.email,
    this.address,
  });

  factory Ong.fromJson(Map<String, dynamic> json) {
    return Ong(
      id: json['id'] ?? 0,
      name: json['nom_ong'] ?? json['name'] ?? 'Unknown NGO',
      logo: json['logo'] ?? json['logo_url'],
      phone: json['phone'] ?? json['telephone'],
      email: json['email'],
      address: json['address'] ?? json['adresse'],
    );
  }
  String get logoUrl {
    if (logo == null) return '';
    if (logo!.startsWith('http')) return logo!;
    // Prepend host using ApiConstants logic
    return '${ApiConstants.rootUrl}/$logo';
  }
}

class LocationData {
  final double? lat;
  final double? lng;
  final String? wilaya;
  final String? moughataa;

  LocationData({this.lat, this.lng, this.wilaya, this.moughataa});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      lat: json['lat'],
      lng: json['lng'],
      wilaya: json['wilaya'],
      moughataa: json['moughataa'],
    );
  }
}

class CaseModel {
  final int id;
  final String title;
  final String? description;
  final String? address;
  final String? date;
  final String? status;
  final LocationData location;
  final Ong ong;
  final String? category;
  final String? image;
  final List<String>? images;

  CaseModel({
    required this.id,
    required this.title,
    this.description,
    this.address,
    this.date,
    this.status,
    required this.location,
    required this.ong,
    this.category,
    this.image,
    this.images,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      address: json['address'],
      date: json['date'],
      status: json['status'],
      location: LocationData.fromJson(json['location'] ?? {}),
      ong: Ong.fromJson(json['ong'] ?? {}),
      category: json['category'],
      image: json['image'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  String get mainImageUrl {
    // Fallback: if 'image' is null, try to use the first image from 'images' list
    String? effectiveImage = image;
    if ((effectiveImage == null || effectiveImage.isEmpty) &&
        images != null &&
        images!.isNotEmpty) {
      effectiveImage = images!.first;
    }

    // Construct full URL if relative
    if (effectiveImage == null) return '';
    if (effectiveImage.startsWith('http')) return effectiveImage;

    // Flask serves static files from /static/ route
    // Database paths are like "uploads/media/filename.jpg"
    // Need to construct: http://127.0.0.1:5000/static/uploads/media/filename.jpg

    // 1. Normalize separators
    String cleanPath = effectiveImage.replaceAll("\\", "/");

    // 2. Remove leading slash if present
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // 3. Check if path already starts with 'static/'
    if (cleanPath.startsWith('static/')) {
      return '${ApiConstants.rootUrl}/$cleanPath';
    }

    // 4. Default case: prepend 'static/'
    return '${ApiConstants.rootUrl}/static/$cleanPath';
  }
}
