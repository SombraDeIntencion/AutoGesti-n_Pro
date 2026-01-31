class DocumentSection {
  List<String> photos;
  List<String> pdfs;
  String notes;
  DateTime? expirationDate;

  DocumentSection({
    this.photos = const [],
    this.pdfs = const [],
    this.notes = '',
    this.expirationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'photos': photos,
      'pdfs': pdfs,
      'notes': notes,
      'expirationDate': expirationDate?.toIso8601String(),
    };
  }

  factory DocumentSection.fromJson(Map<String, dynamic> json) {
    return DocumentSection(
      photos: List<String>.from(json['photos'] ?? []),
      pdfs: List<String>.from(json['pdfs'] ?? []),
      notes: json['notes'] ?? '',
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'])
          : null,
    );
  }

  DocumentSection copyWith({
    List<String>? photos,
    List<String>? pdfs,
    String? notes,
    DateTime? expirationDate,
  }) {
    return DocumentSection(
      photos: photos ?? this.photos,
      pdfs: pdfs ?? this.pdfs,
      notes: notes ?? this.notes,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }

  // Verificar si el documento está vencido
  bool get isExpired {
    if (expirationDate == null) return false;
    return DateTime.now().isAfter(expirationDate!);
  }

  // Verificar si está próximo a vencer (30 días)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    return !isExpired &&
        expirationDate!.isAfter(now) &&
        expirationDate!.isBefore(thirtyDaysFromNow);
  }

  // Días restantes hasta el vencimiento
  int get daysUntilExpiration {
    if (expirationDate == null) return -1;
    final now = DateTime.now();
    return expirationDate!.difference(now).inDays;
  }

  // Estado de vigencia
  String get expirationStatus {
    if (expirationDate == null) return 'Sin fecha';
    if (isExpired) return 'Vencido';
    if (isExpiringSoon) return 'Por vencer';
    return 'Vigente';
  }
}
