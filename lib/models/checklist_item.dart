enum ChecklistCategory { interior, exterior, underhood, tires }

enum ChecklistStatus { ok, attention, urgent }

class ChecklistItem {
  final String id;
  String name;
  ChecklistCategory category;
  ChecklistStatus status;
  List<String> photos; // URLs o paths de las fotos del componente
  String notes; // Notas adicionales del item

  // Alias para compatibilidad
  String get title => name;
  set title(String value) => name = value;

  ChecklistItem({
    required this.id,
    required this.name,
    required this.category,
    this.status = ChecklistStatus.ok,
    this.photos = const [],
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'status': status.name,
      'photos': photos,
      'notes': notes,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: ChecklistCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ChecklistCategory.exterior,
      ),
      status: ChecklistStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChecklistStatus.ok,
      ),
      photos: List<String>.from(json['photos'] ?? []),
      notes: json['notes'] ?? '',
    );
  }

  ChecklistItem copyWith({
    String? id,
    String? name,
    ChecklistCategory? category,
    ChecklistStatus? status,
    List<String>? photos,
    String? notes,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
    );
  }
}
