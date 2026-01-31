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
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
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
          id: 'micro',
          name: 'Microempresa',
          minVehicles: 2,
          maxVehicles: 5,
          pricePerVehicle: 175,
          monthlyTotal: 175, // Ejemplo: 2 vehículos (1 gratis + 1 pagado)
          description: 'Para microempresas y transporte escolar',
          features: [
            '2-5 vehículos',
            'Primer vehículo GRATIS',
            '\$175 MXN por vehículo adicional',
            'Reportes avanzados',
            'Exportar a PDF/Excel',
          ],
        ),
        SubscriptionPlan(
          id: 'small',
          name: 'Pequeña Empresa',
          minVehicles: 6,
          maxVehicles: 10,
          pricePerVehicle: 165,
          monthlyTotal: 990, // Ejemplo: 6 vehículos (1 gratis + 5 pagados)
          description: 'Empresas en crecimiento',
          features: [
            '6-10 vehículos',
            'Primer vehículo GRATIS',
            '\$165 MXN por vehículo adicional',
            'Soporte prioritario',
            'Múltiples usuarios',
          ],
        ),
        SubscriptionPlan(
          id: 'medium',
          name: 'Empresa Mediana',
          minVehicles: 11,
          maxVehicles: 20,
          pricePerVehicle: 155,
          monthlyTotal: 1705, // Ejemplo: 11 vehículos (1 gratis + 10 pagados)
          description: 'Control formal de flotilla',
          features: [
            '11-20 vehículos',
            'Primer vehículo GRATIS',
            '\$155 MXN por vehículo adicional',
            'Dashboard personalizado',
            'Alertas automáticas',
          ],
        ),
        SubscriptionPlan(
          id: 'large',
          name: 'Empresa Grande',
          minVehicles: 21,
          maxVehicles: 35,
          pricePerVehicle: 145,
          monthlyTotal: 3045, // Ejemplo: 21 vehículos (1 gratis + 20 pagados)
          description: 'Escala atractiva con ahorro',
          features: [
            '21-35 vehículos',
            'Primer vehículo GRATIS',
            '\$145 MXN por vehículo adicional',
            'Integraciones API',
            'Soporte dedicado',
          ],
        ),
        SubscriptionPlan(
          id: 'enterprise',
          name: 'Flotilla Grande',
          minVehicles: 36,
          maxVehicles: 50,
          pricePerVehicle: 135,
          monthlyTotal: 4860, // Ejemplo: 36 vehículos (1 gratis + 35 pagados)
          description: 'Máximo control antes de GPS',
          features: [
            '36-50 vehículos',
            'Primer vehículo GRATIS',
            '\$135 MXN por vehículo adicional',
            'Consultor dedicado',
            'Customización avanzada',
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
