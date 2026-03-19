import 'document_section.dart';
import 'driver_section.dart';
import 'maintenance_data.dart';

class Vehicle {
  final String id;
  final String userId; // ID del usuario propietario
  String name;
  String brand;
  String model;
  int year;
  String plate;
  String? photo;
  DocumentSection insurance;
  DriverSection driver;
  DocumentSection contract;
  DocumentSection circulationCard;
  DocumentSection ecologicalSticker;
  DocumentSection otherDocuments;
  MaintenanceData maintenance;

  // Campos de auditoría
  String? lastEditedBy; // Nombre del empleado que editó
  String? lastEditedById; // ID del empleado
  DateTime? lastEditedAt; // Fecha de última edición

  Vehicle({
    required this.id,
    required this.userId,
    required this.name,
    this.brand = '',
    this.model = '',
    required this.year,
    required this.plate,
    this.photo,
    DocumentSection? insurance,
    DriverSection? driver,
    DocumentSection? contract,
    DocumentSection? circulationCard,
    DocumentSection? ecologicalSticker,
    DocumentSection? otherDocuments,
    MaintenanceData? maintenance,
    this.lastEditedBy,
    this.lastEditedById,
    this.lastEditedAt,
  }) : insurance = insurance ?? DocumentSection(),
       driver = driver ?? DriverSection(),
       contract = contract ?? DocumentSection(),
       circulationCard = circulationCard ?? DocumentSection(),
       ecologicalSticker = ecologicalSticker ?? DocumentSection(),
       otherDocuments = otherDocuments ?? DocumentSection(),
       maintenance = maintenance ?? MaintenanceData();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'plate': plate,
      'photo': photo,
      'insurance': insurance.toJson(),
      'driver': driver.toJson(),
      'contract': contract.toJson(),
      'circulationCard': circulationCard.toJson(),
      'ecologicalSticker': ecologicalSticker.toJson(),
      'otherDocuments': otherDocuments.toJson(),
      'maintenance': maintenance.toJson(),
      'lastEditedBy': lastEditedBy,
      'lastEditedById': lastEditedById,
      'lastEditedAt': lastEditedAt?.toIso8601String(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    String vehicleName = json['name'] as String? ?? '';
    if (vehicleName.isEmpty) {
      final b = json['brand'] as String? ?? '';
      final m = json['model'] as String? ?? '';
      vehicleName = '$b $m'.trim();
    }
    if (vehicleName.isEmpty) {
      vehicleName = json['plate'] as String? ?? 'Sin nombre';
    }

    return Vehicle(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: vehicleName,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? DateTime.now().year,
      plate: json['plate'] ?? '',
      photo: json['photo'] ?? json['photoUrl'],
      insurance: json['insurance'] != null
          ? DocumentSection.fromJson(json['insurance'])
          : null,
      driver: json['driver'] != null
          ? DriverSection.fromJson(json['driver'])
          : null,
      contract: json['contract'] != null
          ? DocumentSection.fromJson(json['contract'])
          : null,
      circulationCard: json['circulationCard'] != null
          ? DocumentSection.fromJson(json['circulationCard'])
          : null,
      ecologicalSticker: json['ecologicalSticker'] != null
          ? DocumentSection.fromJson(json['ecologicalSticker'])
          : null,
      otherDocuments: json['otherDocuments'] != null
          ? DocumentSection.fromJson(json['otherDocuments'])
          : null,
      maintenance: json['maintenance'] != null
          ? MaintenanceData.fromJson(json['maintenance'])
          : null,
      lastEditedBy: json['lastEditedBy'],
      lastEditedById: json['lastEditedById'],
      lastEditedAt: json['lastEditedAt'] != null
          ? DateTime.parse(json['lastEditedAt'])
          : null,
    );
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? model,
    int? year,
    String? plate,
    String? photo,
    DocumentSection? insurance,
    DriverSection? driver,
    DocumentSection? contract,
    DocumentSection? circulationCard,
    DocumentSection? ecologicalSticker,
    DocumentSection? otherDocuments,
    MaintenanceData? maintenance,
    String? lastEditedBy,
    String? lastEditedById,
    DateTime? lastEditedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      plate: plate ?? this.plate,
      photo: photo ?? this.photo,
      insurance: insurance ?? this.insurance,
      driver: driver ?? this.driver,
      contract: contract ?? this.contract,
      circulationCard: circulationCard ?? this.circulationCard,
      ecologicalSticker: ecologicalSticker ?? this.ecologicalSticker,
      otherDocuments: otherDocuments ?? this.otherDocuments,
      maintenance: maintenance ?? this.maintenance,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      lastEditedById: lastEditedById ?? this.lastEditedById,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
    );
  }
}
