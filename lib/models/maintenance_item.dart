class MaintenanceItem {
  final String id;
  String what;
  List<String> problemPhotos;
  List<String> oldPartsPhotos;
  List<String> newPartsPhotos;
  List<String> afterPhotos;
  int currentKm;
  int nextChangeKm;
  DateTime date;

  MaintenanceItem({
    required this.id,
    this.what = '',
    this.problemPhotos = const [],
    this.oldPartsPhotos = const [],
    this.newPartsPhotos = const [],
    this.afterPhotos = const [],
    this.currentKm = 0,
    this.nextChangeKm = 0,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'what': what,
      'problemPhotos': problemPhotos,
      'oldPartsPhotos': oldPartsPhotos,
      'newPartsPhotos': newPartsPhotos,
      'afterPhotos': afterPhotos,
      'currentKm': currentKm,
      'nextChangeKm': nextChangeKm,
      'date': date.toIso8601String(),
    };
  }

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceItem(
      id: json['id'],
      what: json['what'] ?? '',
      problemPhotos: List<String>.from(json['problemPhotos'] ?? []),
      oldPartsPhotos: List<String>.from(json['oldPartsPhotos'] ?? []),
      newPartsPhotos: List<String>.from(json['newPartsPhotos'] ?? []),
      afterPhotos: List<String>.from(json['afterPhotos'] ?? []),
      currentKm: json['currentKm'] ?? 0,
      nextChangeKm: json['nextChangeKm'] ?? 0,
      date: DateTime.parse(json['date']),
    );
  }

  MaintenanceItem copyWith({
    String? id,
    String? what,
    List<String>? problemPhotos,
    List<String>? oldPartsPhotos,
    List<String>? newPartsPhotos,
    List<String>? afterPhotos,
    int? currentKm,
    int? nextChangeKm,
    DateTime? date,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      what: what ?? this.what,
      problemPhotos: problemPhotos ?? this.problemPhotos,
      oldPartsPhotos: oldPartsPhotos ?? this.oldPartsPhotos,
      newPartsPhotos: newPartsPhotos ?? this.newPartsPhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      currentKm: currentKm ?? this.currentKm,
      nextChangeKm: nextChangeKm ?? this.nextChangeKm,
      date: date ?? this.date,
    );
  }
}
