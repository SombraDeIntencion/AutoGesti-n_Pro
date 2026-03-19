/// Modelo para empleados/técnicos que trabajan en la cuenta
class Employee {
  final String id; // Número de empleado (único)
  final String name; // Nombre completo
  final DateTime createdAt;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Employee copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Employee(id: $id, name: $name)';
}
