/// Modelo de usuario para AutoGestión Max
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Información de suscripción
  final String subscriptionTier; // 'free', 'basic', 'pro', 'enterprise'
  final int maxVehicles; // Número máximo de vehículos permitidos
  final int currentVehicles; // Número actual de vehículos
  final DateTime? subscriptionExpiresAt;
  final bool isSubscriptionActive;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.subscriptionTier = 'free',
    this.maxVehicles = 1, // 1 vehículo gratis
    this.currentVehicles = 0,
    this.subscriptionExpiresAt,
    this.isSubscriptionActive = true,
  });

  /// Crear desde documento de Firestore
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'])
          : null,
      subscriptionTier: data['subscriptionTier'] ?? 'free',
      maxVehicles: data['maxVehicles'] ?? 1,
      currentVehicles: data['currentVehicles'] ?? 0,
      subscriptionExpiresAt: data['subscriptionExpiresAt'] != null
          ? DateTime.parse(data['subscriptionExpiresAt'])
          : null,
      isSubscriptionActive: data['isSubscriptionActive'] ?? true,
    );
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'subscriptionTier': subscriptionTier,
      'maxVehicles': maxVehicles,
      'currentVehicles': currentVehicles,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'isSubscriptionActive': isSubscriptionActive,
    };
  }

  /// Verificar si puede agregar más vehículos
  bool canAddVehicle() {
    return currentVehicles < maxVehicles;
  }

  /// Obtener vehículos disponibles para agregar
  int vehiclesAvailable() {
    return maxVehicles - currentVehicles;
  }

  /// Verificar si tiene suscripción activa (más de 1 vehículo)
  bool hasActiveSubscription() {
    return isSubscriptionActive &&
        subscriptionTier != 'free' &&
        (subscriptionExpiresAt == null ||
            subscriptionExpiresAt!.isAfter(DateTime.now()));
  }

  /// Copiar con modificaciones
  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
    String? subscriptionTier,
    int? maxVehicles,
    int? currentVehicles,
    DateTime? subscriptionExpiresAt,
    bool? isSubscriptionActive,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      maxVehicles: maxVehicles ?? this.maxVehicles,
      currentVehicles: currentVehicles ?? this.currentVehicles,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, tier: $subscriptionTier, vehicles: $currentVehicles/$maxVehicles)';
  }
}

/// Modelo para planes de suscripción
class SubscriptionPlan {
  final String id;
  final String name;
  final int minVehicles;
  final int maxVehicles;
  final double pricePerVehicle; // MXN
  final double monthlyTotal;
  final String description;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.minVehicles,
    required this.maxVehicles,
    required this.pricePerVehicle,
    required this.monthlyTotal,
    required this.description,
    required this.features,
  });

  /// Planes predefinidos según la tabla de precios
  static List<SubscriptionPlan> get allPlans => [
    SubscriptionPlan(
      id: 'free',
      name: 'Plan Gratuito',
      minVehicles: 1,
      maxVehicles: 1,
      pricePerVehicle: 0,
      monthlyTotal: 0,
      description: 'Ideal para prueba o uso personal',
      features: [
        '1 vehículo gratis',
        'Gestión básica de gastos',
        'Historial de mantenimiento',
        'Reportes básicos',
      ],
    ),
    SubscriptionPlan(
      id: 'starter2',
      name: 'Starter',
      minVehicles: 2,
      maxVehicles: 3,
      pricePerVehicle: 40,
      monthlyTotal: 80,
      description: 'Ideal para iniciar',
      features: [
        '2-3 vehículos',
        'Primer vehículo GRATIS',
        'Sincronización automática',
      ],
    ),
    SubscriptionPlan(
      id: 'starter5',
      name: 'Starter Plus',
      minVehicles: 4,
      maxVehicles: 5,
      pricePerVehicle: 33,
      monthlyTotal: 130,
      description: 'Perfecto para microempresas',
      features: ['4-5 vehículos', 'Primer vehículo GRATIS', 'Sin limitaciones'],
    ),
    SubscriptionPlan(
      id: 'small8',
      name: 'Small',
      minVehicles: 6,
      maxVehicles: 8,
      pricePerVehicle: 29,
      monthlyTotal: 200,
      description: 'Empresas en crecimiento',
      features: [
        '6-8 vehículos',
        'Primer vehículo GRATIS',
        'Alertas de vencimiento',
        'Respaldo en la nube',
      ],
    ),
    SubscriptionPlan(
      id: 'small12',
      name: 'Small Plus',
      minVehicles: 9,
      maxVehicles: 12,
      pricePerVehicle: 25,
      monthlyTotal: 280,
      description: 'Historial ilimitado',
      features: [
        '9-12 vehículos',
        'Primer vehículo GRATIS',
        'Historial ilimitado',
        'Alertas de vencimiento',
      ],
    ),
    SubscriptionPlan(
      id: 'medium17',
      name: 'Medium',
      minVehicles: 13,
      maxVehicles: 17,
      pricePerVehicle: 24,
      monthlyTotal: 380,
      description: 'Espacio ampliado en nube',
      features: [
        '13-17 vehículos',
        'Primer vehículo GRATIS',
        'Soporte por email',
      ],
    ),
    SubscriptionPlan(
      id: 'medium23',
      name: 'Medium Plus',
      minVehicles: 18,
      maxVehicles: 23,
      pricePerVehicle: 21,
      monthlyTotal: 470,
      description: 'Almacenamiento extendido',
      features: [
        '18-23 vehículos',
        'Primer vehículo GRATIS',
        'Almacenamiento extendido',
      ],
    ),
    SubscriptionPlan(
      id: 'large30',
      name: 'Large',
      minVehicles: 24,
      maxVehicles: 30,
      pricePerVehicle: 19,
      monthlyTotal: 560,
      description: 'Todas las funciones',
      features: [
        '24-30 vehículos',
        'Primer vehículo GRATIS',
        'Almacenamiento extendido',
      ],
    ),
    SubscriptionPlan(
      id: 'large40',
      name: 'Large Plus',
      minVehicles: 31,
      maxVehicles: 40,
      pricePerVehicle: 16,
      monthlyTotal: 640,
      description: 'Todas las funciones',
      features: [
        '31-40 vehículos',
        'Primer vehículo GRATIS',
        'Almacenamiento extendido',
      ],
    ),
    SubscriptionPlan(
      id: 'enterprise50',
      name: 'Enterprise',
      minVehicles: 41,
      maxVehicles: 50,
      pricePerVehicle: 14,
      monthlyTotal: 680,
      description: 'Solución completa',
      features: [
        '41-50 vehículos',
        'Primer vehículo GRATIS',
        'Almacenamiento ilimitado',
      ],
    ),
  ];

  /// Calcular precio total según número de vehículos
  /// Recuerda: el primer vehículo siempre es gratis
  static double calculateMonthlyPrice(int numberOfVehicles) {
    if (numberOfVehicles <= 1) return 0;

    final plan = getPlanForVehicles(numberOfVehicles);
    if (plan == null) return 0;

    // Restar 1 porque el primer vehículo es gratis
    return (numberOfVehicles - 1) * plan.pricePerVehicle;
  }

  /// Obtener plan según número de vehículos
  static SubscriptionPlan? getPlanForVehicles(int vehicles) {
    for (var plan in allPlans) {
      if (vehicles >= plan.minVehicles && vehicles <= plan.maxVehicles) {
        return plan;
      }
    }
    return null;
  }
}
