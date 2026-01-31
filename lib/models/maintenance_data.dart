import 'checklist_item.dart';
import 'maintenance_section_data.dart';
import 'inspection_record.dart';

class MaintenanceData {
  List<ChecklistItem> checklist;
  List<MaintenanceSectionData> sections;
  List<String> inspectionPhotos; // Fotos generales del vehículo (hasta 9)
  List<InspectionRecord>
  inspectionHistory; // Historial de inspecciones guardadas

  MaintenanceData({
    this.checklist = const [],
    List<MaintenanceSectionData>? sections,
    this.inspectionPhotos = const [],
    this.inspectionHistory = const [],
  }) : sections =
           sections ??
           [
             MaintenanceSectionData(id: 'motor', name: 'Motor'),
             MaintenanceSectionData(id: 'direccion', name: 'Dirección'),
             MaintenanceSectionData(
               id: 'pintura',
               name: 'Pintura y Hojalatería',
             ),
             MaintenanceSectionData(id: 'radiador', name: 'Radiador'),
             MaintenanceSectionData(id: 'suspension', name: 'Suspensión'),
             MaintenanceSectionData(id: 'ac', name: 'A/C'),
             MaintenanceSectionData(id: 'electrico', name: 'Sistema Eléctrico'),
             MaintenanceSectionData(id: 'frenos', name: 'Frenos'),
             MaintenanceSectionData(id: 'transmision', name: 'Transmisión'),
           ];

  Map<String, dynamic> toJson() {
    return {
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'sections': sections.map((section) => section.toJson()).toList(),
      'inspectionPhotos': inspectionPhotos,
      'inspectionHistory': inspectionHistory
          .map((record) => record.toJson())
          .toList(),
    };
  }

  factory MaintenanceData.fromJson(Map<String, dynamic> json) {
    return MaintenanceData(
      checklist:
          (json['checklist'] as List?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      sections:
          (json['sections'] as List?)
              ?.map((section) => MaintenanceSectionData.fromJson(section))
              .toList() ??
          [],
      inspectionPhotos: List<String>.from(json['inspectionPhotos'] ?? []),
      inspectionHistory:
          (json['inspectionHistory'] as List?)
              ?.map((record) => InspectionRecord.fromJson(record))
              .toList() ??
          [],
    );
  }

  MaintenanceData copyWith({
    List<ChecklistItem>? checklist,
    List<MaintenanceSectionData>? sections,
    List<String>? inspectionPhotos,
    List<InspectionRecord>? inspectionHistory,
  }) {
    return MaintenanceData(
      checklist: checklist ?? this.checklist,
      sections: sections ?? this.sections,
      inspectionPhotos: inspectionPhotos ?? this.inspectionPhotos,
      inspectionHistory: inspectionHistory ?? this.inspectionHistory,
    );
  }
}
