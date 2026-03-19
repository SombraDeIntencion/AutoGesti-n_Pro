import 'package:uuid/uuid.dart';
import 'document_history_record.dart';

/// Registro de historial de conductor
class DriverHistoryRecord extends DocumentHistoryRecord {
  final String name;
  final String phone;
  final String email;

  DriverHistoryRecord({
    required super.id,
    required super.date,
    required this.name,
    required this.phone,
    required this.email,
    required super.photos,
    required super.pdfs,
    required super.notes,
  }) : super(sectionName: 'conductor');

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({'name': name, 'phone': phone, 'email': email});
    return json;
  }

  factory DriverHistoryRecord.fromJson(Map<String, dynamic> json) {
    return DriverHistoryRecord(
      id: json['id'] ?? const Uuid().v4(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      photos: List<String>.from(json['photos'] ?? []),
      pdfs: List<String>.from(json['pdfs'] ?? []),
      notes: json['notes'] ?? '',
    );
  }

  @override
  DriverHistoryRecord copyWith({
    String? id,
    DateTime? date,
    String? name,
    String? phone,
    String? email,
    String? sectionName,
    DateTime? expirationDate,
    List<String>? photos,
    List<String>? pdfs,
    String? notes,
  }) {
    return DriverHistoryRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photos: photos ?? this.photos,
      pdfs: pdfs ?? this.pdfs,
      notes: notes ?? this.notes,
    );
  }
}
