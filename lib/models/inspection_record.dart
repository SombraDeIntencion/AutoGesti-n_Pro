import 'checklist_item.dart';

/// Registro de una inspección específica con fecha y hora
class InspectionRecord {
  final String id;
  final DateTime date;
  final List<ChecklistItem> checklist;
  final List<String> inspectionPhotos;
  final String notes;

  InspectionRecord({
    required this.id,
    required this.date,
    required this.checklist,
    required this.inspectionPhotos,
    this.notes = '',
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'inspectionPhotos': inspectionPhotos,
      'notes': notes,
    };
  }

  // Crear desde JSON
  factory InspectionRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return InspectionRecord(
      id: json['id'] as String? ?? '',
      date: parsedDate,
      checklist:
          (json['checklist'] as List?)
              ?.map(
                (item) => ChecklistItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      inspectionPhotos: List<String>.from(json['inspectionPhotos'] ?? []),
      notes: json['notes'] as String? ?? '',
    );
  }

  // Crear copia con modificaciones
  InspectionRecord copyWith({
    String? id,
    DateTime? date,
    List<ChecklistItem>? checklist,
    List<String>? inspectionPhotos,
    String? notes,
  }) {
    return InspectionRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checklist: checklist ?? this.checklist,
      inspectionPhotos: inspectionPhotos ?? this.inspectionPhotos,
      notes: notes ?? this.notes,
    );
  }
}
