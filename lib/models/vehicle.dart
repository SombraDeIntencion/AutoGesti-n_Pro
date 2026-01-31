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
  MaintenanceData maintenance;

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
    MaintenanceData? maintenance,
  }) : insurance = insurance ?? DocumentSection(),
       driver = driver ?? DriverSection(),
       contract = contract ?? DocumentSection(),
       circulationCard = circulationCard ?? DocumentSection(),
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
      'maintenance': maintenance.toJson(),
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      userId: json['userId'] ?? '', // Compatibilidad con datos antiguos
      name: json['name'],
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year'],
      plate: json['plate'],
      photo: json['photo'],
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
      maintenance: json['maintenance'] != null
          ? MaintenanceData.fromJson(json['maintenance'])
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
    MaintenanceData? maintenance,
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
      maintenance: maintenance ?? this.maintenance,
    );
  }
}
