import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  fuel, // Combustible
  maintenance, // Mantenimiento
  insurance, // Seguro
  toll, // Peaje
  parking, // Estacionamiento
  repair, // Reparación
  other, // Otro
}

class Expense {
  final String id;
  final String userId;
  final String vehicleId;
  final String vehicleName;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? description;
  final String? receiptUrl;
  final String? receiptType; // Tipo de recibo: 'qr', 'photo', 'pdf'
  final int? mileage; // Kilometraje
  final String? mileagePhotoUrl; // URL de foto del odómetro

  // Campos de auditoría
  final DateTime createdAt;
  final DateTime? updatedAt;

  Expense({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.vehicleName,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.receiptUrl,
    this.receiptType,
    this.mileage,
    this.mileagePhotoUrl,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'category': category.name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': description,
      'receiptUrl': receiptUrl,
      'receiptType': receiptType,
      'mileage': mileage,
      'mileagePhotoUrl': mileagePhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = (json['date'] as Timestamp).toDate();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    double parsedAmount;
    try {
      parsedAmount = (json['amount'] as num).toDouble();
    } catch (_) {
      parsedAmount = 0.0;
    }

    return Expense(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      vehicleId: json['vehicleId'] ?? '',
      vehicleName: json['vehicleName'] ?? json['vehicle'] ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amount: parsedAmount,
      date: parsedDate,
      description: json['description'],
      receiptUrl: json['receiptUrl'],
      receiptType: json['receiptType'],
      mileage: json['mileage'],
      mileagePhotoUrl: json['mileagePhotoUrl'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Método para copiar el objeto con cambios
  Expense copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? vehicleName,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? receiptUrl,
    String? receiptType,
    int? mileage,
    String? mileagePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      receiptType: receiptType ?? this.receiptType,
      mileage: mileage ?? this.mileage,
      mileagePhotoUrl: mileagePhotoUrl ?? this.mileagePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Texto de categoría localizable
  String getCategoryKey() {
    switch (category) {
      case ExpenseCategory.fuel:
        return 'expense_category_fuel';
      case ExpenseCategory.maintenance:
        return 'expense_category_maintenance';
      case ExpenseCategory.insurance:
        return 'expense_category_insurance';
      case ExpenseCategory.toll:
        return 'expense_category_toll';
      case ExpenseCategory.parking:
        return 'expense_category_parking';
      case ExpenseCategory.repair:
        return 'expense_category_repair';
      case ExpenseCategory.other:
        return 'expense_category_other';
    }
  }
}
