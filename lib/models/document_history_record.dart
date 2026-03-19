import 'package:uuid/uuid.dart';

/// Registro de historial de documento
class DocumentHistoryRecord {
  final String id;
  final DateTime date;
  final String
  sectionName; // seguro, tarjeta_circulacion, tenencia, verificacion
  final DateTime? expirationDate;
  final List<String> photos;
  final List<String> pdfs;
  final String notes;

  DocumentHistoryRecord({
    required this.id,
    required this.date,
    required this.sectionName,
    this.expirationDate,
    required this.photos,
    required this.pdfs,
    required this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'sectionName': sectionName,
      'expirationDate': expirationDate?.toIso8601String(),
      'photos': photos,
      'pdfs': pdfs,
      'notes': notes,
    };
  }

  factory DocumentHistoryRecord.fromJson(Map<String, dynamic> json) {
    return DocumentHistoryRecord(
      id: json['id'] ?? const Uuid().v4(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      sectionName: json['sectionName'] ?? '',
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
      photos: List<String>.from(json['photos'] ?? []),
      pdfs: List<String>.from(json['pdfs'] ?? []),
      notes: json['notes'] ?? '',
    );
  }

  DocumentHistoryRecord copyWith({
    String? id,
    DateTime? date,
    String? sectionName,
    DateTime? expirationDate,
    List<String>? photos,
    List<String>? pdfs,
    String? notes,
  }) {
    return DocumentHistoryRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      sectionName: sectionName ?? this.sectionName,
      expirationDate: expirationDate ?? this.expirationDate,
      photos: photos ?? this.photos,
      pdfs: pdfs ?? this.pdfs,
      notes: notes ?? this.notes,
    );
  }
}
