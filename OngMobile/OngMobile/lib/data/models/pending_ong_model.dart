class PendingOngModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String domains;
  final String? logoUrl;
  final String? verificationDocUrl;
  final DateTime? createdAt;

  PendingOngModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.domains,
    this.logoUrl,
    this.verificationDocUrl,
    this.createdAt,
  });

  factory PendingOngModel.fromJson(Map<String, dynamic> json) {
    return PendingOngModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      domains: json['domains'] ?? '',
      logoUrl: json['logo_url'],
      verificationDocUrl: json['verification_doc_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
