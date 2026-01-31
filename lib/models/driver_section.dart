import 'document_section.dart';

class DriverSection extends DocumentSection {
  String name;
  String phone;
  String email;

  DriverSection({
    this.name = '',
    this.phone = '',
    this.email = '',
    super.photos = const [],
    super.pdfs = const [],
    super.notes = '',
    super.expirationDate,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'photos': photos,
      'pdfs': pdfs,
      'notes': notes,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

  factory DriverSection.fromJson(Map<String, dynamic> json) {
    return DriverSection(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      pdfs: List<String>.from(json['pdfs'] ?? []),
      notes: json['notes'] ?? '',
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
    );
  }

  @override
  DriverSection copyWith({
    String? name,
    String? phone,
    String? email,
    List<String>? photos,
    List<String>? pdfs,
    String? notes,
    DateTime? expirationDate,
  }) {
    return DriverSection(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photos: photos ?? this.photos,
      pdfs: pdfs ?? this.pdfs,
      notes: notes ?? this.notes,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
