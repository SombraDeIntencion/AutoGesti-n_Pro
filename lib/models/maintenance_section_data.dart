import 'maintenance_item.dart';

class MaintenanceSectionData {
  final String id;
  String name;
  List<MaintenanceItem> items;

  MaintenanceSectionData({
    required this.id,
    required this.name,
    this.items = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory MaintenanceSectionData.fromJson(Map<String, dynamic> json) {
    return MaintenanceSectionData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      items:
          (json['items'] as List?)
              ?.map((item) {
                try {
                  return MaintenanceItem.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<MaintenanceItem>()
              .toList() ??
          [],
    );
  }

  MaintenanceSectionData copyWith({
    String? id,
    String? name,
    List<MaintenanceItem>? items,
  }) {
    return MaintenanceSectionData(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}
