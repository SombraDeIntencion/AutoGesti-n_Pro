class MaintenanceItem {
  final String id;
  String what;
  List<String> problemPhotos;
  List<String> oldPartsPhotos;
  List<String> newPartsPhotos;
  List<String> afterPhotos;
  String? odometerPhoto; // Nueva: foto del odómetro
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
    this.odometerPhoto,
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
      'odometerPhoto': odometerPhoto,
      'currentKm': currentKm,
      'nextChangeKm': nextChangeKm,
      'date': date.toIso8601String(),
    };
  }

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date']);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return MaintenanceItem(
      id: json['id'] ?? '',
      what: json['what'] ?? '',
      problemPhotos: List<String>.from(json['problemPhotos'] ?? []),
      oldPartsPhotos: List<String>.from(json['oldPartsPhotos'] ?? []),
      newPartsPhotos: List<String>.from(json['newPartsPhotos'] ?? []),
      afterPhotos: List<String>.from(json['afterPhotos'] ?? []),
      odometerPhoto: json['odometerPhoto'],
      currentKm: json['currentKm'] ?? 0,
      nextChangeKm: json['nextChangeKm'] ?? 0,
      date: parsedDate,
    );
  }

  MaintenanceItem copyWith({
    String? id,
    String? what,
    List<String>? problemPhotos,
    List<String>? oldPartsPhotos,
    List<String>? newPartsPhotos,
    List<String>? afterPhotos,
    String? odometerPhoto,
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
      odometerPhoto: odometerPhoto ?? this.odometerPhoto,
      currentKm: currentKm ?? this.currentKm,
      nextChangeKm: nextChangeKm ?? this.nextChangeKm,
      date: date ?? this.date,
    );
  }
}
