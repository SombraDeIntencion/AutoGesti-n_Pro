import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';

/// Pantalla de planes y suscripciones
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = true;
  String? _currentTier;

  @override
  void initState() {
    super.initState();
    _initializeSubscriptions();
  }

  Future<void> _initializeSubscriptions() async {
    setState(() => _isLoading = true);

    // Inicializar servicio de suscripciones
    await _subscriptionService.initialize();

    // Obtener tier actual del usuario
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final appUser = await authService.getAppUser(user.uid);
      _currentTier = appUser?.subscriptionTier ?? 'free';
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF06B6D4)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E40AF), // Azul oscuro
              Color(0xFF3B82F6), // Azul medio
              Color(0xFF06B6D4), // Cyan
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Planes y Precios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balancear el back button
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Elige el plan perfecto para tu negocio',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Lista de planes
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Plan Free
                    _buildPlanCard(
                      context: context,
                      title: 'Free',
                      price: '\$0',
                      period: 'Gratis para siempre',
                      maxVehicles: 1,
                      pricePerVehicle: null,
                      features: [
                        '1 vehículo',
                        'Almacenamiento local',
                        'Documentos ilimitados',
                        'Funciona como prueba o demo',
                      ],
                      color: Colors.grey,
                      isCurrentPlan: _currentTier == 'free',
                      productId: null,
                    ),
                    const SizedBox(height: 16),

                    // Plan Starter (2-5 vehículos)
                    _buildPlanCard(
                      context: context,
                      title: 'Starter',
                      price: '\$10-\$40',
                      period: 'por mes',
                      maxVehicles: 5,
                      pricePerVehicle: '\$175 MXN/adicional',
                      features: [
                        '1 gratis + hasta 4 adicionales',
                        '2-5 vehículos totales',
                        'Sincronización en la nube',
                        'Ideal para microempresas',
                      ],
                      color: Colors.blue,
                      isRecommended: true,
                      isCurrentPlan: _currentTier == 'starter',
                      productId: SubscriptionService.starterMonthlyId,
                    ),
                    const SizedBox(height: 16),

                    // Plan Small (6-10 vehículos)
                    _buildPlanCard(
                      context: context,
                      title: 'Small',
                      price: '\$46-\$83',
                      period: 'por mes',
                      maxVehicles: 10,
                      pricePerVehicle: '\$165 MXN/adicional',
                      features: [
                        '1 gratis + hasta 9 adicionales',
                        '6-10 vehículos totales',
                        'Reportes básicos',
                        'Pequeñas empresas en crecimiento',
                      ],
                      color: Colors.green,
                      isCurrentPlan: _currentTier == 'small',
                      productId: SubscriptionService.smallMonthlyId,
                    ),
                    const SizedBox(height: 16),

                    // Plan Medium (11-20 vehículos)
                    _buildPlanCard(
                      context: context,
                      title: 'Medium',
                      price: '\$86-\$164',
                      period: 'por mes',
                      maxVehicles: 20,
                      pricePerVehicle: '\$155 MXN/adicional',
                      features: [
                        '1 gratis + hasta 19 adicionales',
                        '11-20 vehículos totales',
                        'Reportes avanzados',
                        'Empresas medianas con orden',
                      ],
                      color: Colors.orange,
                      isCurrentPlan: _currentTier == 'medium',
                      productId: SubscriptionService.mediumMonthlyId,
                    ),
                    const SizedBox(height: 16),

                    // Plan Large (21-35 vehículos)
                    _buildPlanCard(
                      context: context,
                      title: 'Large',
                      price: '\$161-\$274',
                      period: 'por mes',
                      maxVehicles: 35,
                      pricePerVehicle: '\$145 MXN/adicional',
                      features: [
                        '1 gratis + hasta 34 adicionales',
                        '21-35 vehículos totales',
                        'API para integraciones',
                        'Escala atractiva con descuento',
                      ],
                      color: Colors.purple,
                      isCurrentPlan: _currentTier == 'large',
                      productId: SubscriptionService.largeMonthlyId,
                    ),
                    const SizedBox(height: 16),

                    // Plan Enterprise (36-50 vehículos)
                    _buildPlanCard(
                      context: context,
                      title: 'Enterprise',
                      price: '\$263-\$368',
                      period: 'por mes',
                      maxVehicles: 50,
                      pricePerVehicle: '\$135 MXN/adicional',
                      features: [
                        '1 gratis + hasta 49 adicionales',
                        '36-50 vehículos totales',
                        'Soporte dedicado 24/7',
                        'Límite superior para GPS',
                      ],
                      color: Colors.amber.shade700,
                      isCurrentPlan: _currentTier == 'enterprise',
                      productId: SubscriptionService.enterpriseMonthlyId,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    required int? maxVehicles,
    String? pricePerVehicle,
    required List<String> features,
    required Color color,
    required String? productId,
    bool isCurrentPlan = false,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Badge de recomendado
          if (isRecommended)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'RECOMENDADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del plan
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Precio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Precio por vehículo (si existe)
                if (pricePerVehicle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      pricePerVehicle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Cantidad de vehículos
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    maxVehicles != null
                        ? 'Hasta $maxVehicles vehículo${maxVehicles > 1 ? 's' : ''}'
                        : 'Vehículos ilimitados',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Features
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan
                        ? null
                        : () => _handlePurchase(context, productId, title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? Colors.grey.shade300
                          : color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCurrentPlan ? 0 : 2,
                    ),
                    child: Text(
                      isCurrentPlan ? 'Plan Actual' : 'Seleccionar Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCurrentPlan
                            ? Colors.grey.shade600
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(
    BuildContext context,
    String? productId,
    String planName,
  ) async {
    if (productId == null) {
      // Plan Enterprise - contactar ventas
      _showContactSalesDialog(context);
      return;
    }

    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Suscribirse a $planName'),
        content: Text(
          '¿Deseas suscribirte al plan $planName?\n\n'
          'Se te redirigirá a Google Play para completar el pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostrar indicador de carga
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Intentar comprar la suscripción
      final success = await _subscriptionService.purchaseSubscription(
        productId,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga

      if (success) {
        // Éxito - actualizar UI
        setState(() {
          _currentTier = planName.toLowerCase();
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('¡Suscripción Activada!'),
              ],
            ),
            content: Text(
              'Tu plan $planName ha sido activado exitosamente.\n\n'
              'Ahora puedes disfrutar de todas las funciones premium.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Volver a pantalla anterior
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog(
          context,
          'No se pudo completar la compra. Inténtalo de nuevo.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      _showErrorDialog(context, 'Error: $e');
    }
  }

  void _showContactSalesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            const Text('Plan Enterprise'),
          ],
        ),
        content: const Text(
          'Para contratar el plan Enterprise, por favor contacta con nuestro equipo de ventas:\n\n'
          'Email: ventas@autogestion.pro\n'
          'Teléfono: +1 (555) 123-4567\n\n'
          'Te ofreceremos una solución personalizada para tu empresa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí se podría abrir el email o el teléfono
              Navigator.pop(context);
            },
            child: const Text('Contactar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('Próximamente'),
          ],
        ),
        content: const Text(
          'Los pagos y suscripciones estarán disponibles en una próxima versión.\n\n'
          'Por ahora, puedes disfrutar de todas las funciones de forma gratuita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
