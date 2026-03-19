import 'document_section.dart';
import 'document_history_record.dart';
import 'driver_history_record.dart';

class DriverSection extends DocumentSection {
  String name;
  String phone;
  String email;

  DriverSection({
    this.name = '',
    this.phone = '',
    this.email = '',
    super.history = const [],
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
      'history': history.map((h) => h.toJson()).toList(),
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
      history:
          (json['history'] as List<dynamic>?)
              ?.map(
                (h) => DriverHistoryRecord.fromJson(h as Map<String, dynamic>),
              )
              .toList() ??
          [],
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
    List<DocumentHistoryRecord>? history,
    List<String>? photos,
    List<String>? pdfs,
    String? notes,
    DateTime? expirationDate,
  }) {
    return DriverSection(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      history: history ?? this.history,
      photos: photos ?? this.photos,
      pdfs: pdfs ?? this.pdfs,
      notes: notes ?? this.notes,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}
