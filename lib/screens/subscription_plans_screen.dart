import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../services/quiz_analytics_service.dart';
import '../l10n/app_localizations.dart';
import 'subscription_onboarding_screen.dart';

/// Datos de un plan para renderizar las tarjetas de forma data-driven
class _PlanData {
  final String tier;
  final String titleKey;
  final int monthlyPrice; // MXN
  final int annualPrice; // MXN (25% off)
  final int maxVehicles;
  final Color color;
  final String monthlyProductId;
  final String annualProductId;
  final List<String> Function(AppLocalizations l10n) features;

  const _PlanData({
    required this.tier,
    required this.titleKey,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.maxVehicles,
    required this.color,
    required this.monthlyProductId,
    required this.annualProductId,
    required this.features,
  });

  String title(AppLocalizations l10n) => l10n.translate(titleKey);
}

/// Pantalla de planes y suscripciones
class SubscriptionPlansScreen extends StatefulWidget {
  /// Tier recomendado por el quiz de onboarding (null = mostrar todos)
  final String? recommendedTier;

  /// Cantidad de vehículos del quiz (para filtrar planes relevantes)
  final int? vehicleCount;

  const SubscriptionPlansScreen({
    super.key,
    this.recommendedTier,
    this.vehicleCount,
  });

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final QuizAnalyticsService _quizAnalyticsService = QuizAnalyticsService();
  bool _isLoading = true;
  String? _currentTier;
  bool _isAnnual = false;
  bool _showAllPlans = false;
  bool _hasPurchased = false;

  static const _tierOrder = [
    'free',
    'starter2',
    'starter5',
    'small8',
    'small12',
    'medium17',
    'medium23',
    'large30',
    'large40',
    'enterprise50',
  ];

  /// Datos de todos los planes de pago (Free se maneja aparte)
  late final List<_PlanData> _allPlans;

  @override
  void initState() {
    super.initState();
    _allPlans = _buildPlanDataList();
    _initializeSubscriptions();
  }

  List<_PlanData> _buildPlanDataList() {
    return [
      _PlanData(
        tier: 'starter2',
        titleKey: 'plan_name_starter',
        monthlyPrice: 80,
        annualPrice: 720,
        maxVehicles: 3,
        color: Colors.blue.shade400,
        monthlyProductId: SubscriptionService.starter2Id,
        annualProductId: SubscriptionService.starterAnnual2Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '3'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_auto_sync'),
          l10n.translate('feature_ideal_for_starting'),
        ],
      ),
      _PlanData(
        tier: 'starter5',
        titleKey: 'plan_name_starter_plus',
        monthlyPrice: 130,
        annualPrice: 1170,
        maxVehicles: 5,
        color: Colors.blue.shade600,
        monthlyProductId: SubscriptionService.starter5Id,
        annualProductId: SubscriptionService.starterAnnual5Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '5'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_no_limitations'),
          l10n.translate('feature_perfect_micro'),
        ],
      ),
      _PlanData(
        tier: 'small8',
        titleKey: 'plan_name_small',
        monthlyPrice: 200,
        annualPrice: 1800,
        maxVehicles: 8,
        color: Colors.green.shade500,
        monthlyProductId: SubscriptionService.small8Id,
        annualProductId: SubscriptionService.smallAnnual8Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '8'),
          l10n.translate('feature_auto_sync'),
          l10n.translate('feature_expiration_alerts'),
          l10n.translate('feature_cloud_backup'),
        ],
      ),
      _PlanData(
        tier: 'small12',
        titleKey: 'plan_name_small_plus',
        monthlyPrice: 280,
        annualPrice: 2520,
        maxVehicles: 12,
        color: Colors.green.shade700,
        monthlyProductId: SubscriptionService.small12Id,
        annualProductId: SubscriptionService.smallAnnual12Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '12'),
          l10n.translate('feature_auto_sync'),
          l10n.translate('feature_expiration_alerts'),
          l10n.translate('feature_unlimited_history'),
        ],
      ),
      _PlanData(
        tier: 'medium17',
        titleKey: 'plan_name_medium',
        monthlyPrice: 380,
        annualPrice: 3420,
        maxVehicles: 17,
        color: Colors.orange.shade500,
        monthlyProductId: SubscriptionService.medium17Id,
        annualProductId: SubscriptionService.mediumAnnual17Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '17'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_expanded_cloud'),
          l10n.translate('feature_email_support'),
        ],
      ),
      _PlanData(
        tier: 'medium23',
        titleKey: 'plan_name_medium_plus',
        monthlyPrice: 470,
        annualPrice: 4230,
        maxVehicles: 23,
        color: Colors.orange.shade700,
        monthlyProductId: SubscriptionService.medium23Id,
        annualProductId: SubscriptionService.mediumAnnual23Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '23'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_extended_storage'),
        ],
      ),
      _PlanData(
        tier: 'large30',
        titleKey: 'plan_name_large',
        monthlyPrice: 560,
        annualPrice: 5040,
        maxVehicles: 30,
        color: Colors.purple.shade500,
        monthlyProductId: SubscriptionService.large30Id,
        annualProductId: SubscriptionService.largeAnnual30Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '30'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_extended_storage'),
        ],
      ),
      _PlanData(
        tier: 'large40',
        titleKey: 'plan_name_large_plus',
        monthlyPrice: 640,
        annualPrice: 5760,
        maxVehicles: 40,
        color: Colors.purple.shade700,
        monthlyProductId: SubscriptionService.large40Id,
        annualProductId: SubscriptionService.largeAnnual40Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '40'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_extended_storage'),
        ],
      ),
      _PlanData(
        tier: 'enterprise50',
        titleKey: 'plan_name_enterprise',
        monthlyPrice: 680,
        annualPrice: 6120,
        maxVehicles: 50,
        color: Colors.amber.shade700,
        monthlyProductId: SubscriptionService.enterprise50Id,
        annualProductId: SubscriptionService.enterpriseAnnual50Id,
        features: (l10n) => [
          l10n.translate('up_to_vehicles_plural').replaceAll('{count}', '50'),
          l10n.translate('feature_all_functions'),
          l10n.translate('feature_unlimited_storage'),
        ],
      ),
    ];
  }

  /// Devuelve los planes filtrados: recomendado + siguiente tier + Free
  List<_PlanData> _getFilteredPlans() {
    if (widget.recommendedTier == null) return _allPlans;

    final recIdx = _tierOrder.indexOf(widget.recommendedTier!);
    if (recIdx == -1) return _allPlans;

    final filtered = <_PlanData>[];
    for (final plan in _allPlans) {
      final idx = _tierOrder.indexOf(plan.tier);
      // Incluir el recomendado y el siguiente tier arriba
      if (idx == recIdx || idx == recIdx + 1) {
        filtered.add(plan);
      }
    }
    return filtered;
  }

  Future<void> _initializeSubscriptions() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Inicializar servicio de suscripciones
      await _subscriptionService.initialize();

      // Obtener tier actual del usuario
      if (mounted) {
        final authService = AuthService();
        final user = authService.currentUser;
        if (user != null) {
          final appUser = await authService.getAppUser(user.uid);
          _currentTier = appUser?.subscriptionTier ?? 'free';
        } else {
          _currentTier = 'free';
        }
      }
    } catch (e) {
      // Si hay error, mostrar pantalla de todos modos con tier free
      _currentTier = 'free';
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.translate('could_not_load_subscriptions')}: $e',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    // Formatear con separador de miles
    final str = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return '\$$buffer MXN'; // ISO 4217 currency code, not translatable
  }

  void _navigateToRecalculate() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SubscriptionOnboardingScreen(isPostRegistration: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF17A2B8), Color(0xFF0088CC)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final hasRecommendation = widget.recommendedTier != null;
    final filteredPlans = _getFilteredPlans();
    final plansToShow = (hasRecommendation && !_showAllPlans)
        ? filteredPlans
        : _allPlans;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF17A2B8), Color(0xFF0088CC)],
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
                        onPressed: _handleBackNavigation,
                      ),
                      Expanded(
                        child: Text(
                          l10n.translate('plans_and_pricing'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Subtitle / recommendation header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    hasRecommendation
                        ? l10n.translate('based_on_your_answers')
                        : l10n.translate('choose_perfect_plan'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Monthly / Annual Toggle ──
                _buildPeriodToggle(l10n),

                const SizedBox(height: 4),

                // Botón de verificación
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 4,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _verifySubscriptionStatus,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      l10n.translate('verify_subscription_status'),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),

                // Botón para gestionar suscripción (si hay una activa)
                if (_currentTier != null && _currentTier != 'free')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 4,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _openGooglePlaySubscriptions,
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        l10n.translate('manage_in_google_play'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),

                // Información sobre cambios de plan
                if (_currentTier != null && _currentTier != 'free')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 4,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.translate('can_change_plan_anytime'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Lista de planes
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Plan Free siempre visible
                      _buildFreePlanCard(context, l10n),
                      const SizedBox(height: 16),

                      // Planes de pago (filtrados o todos)
                      for (final plan in plansToShow) ...[
                        _buildPlanCard(
                          context: context,
                          plan: plan,
                          l10n: l10n,
                          isRecommended: plan.tier == widget.recommendedTier,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Botón "Ver todos los planes" (solo si hay filtro activo)
                      if (hasRecommendation && !_showAllPlans)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _showAllPlans = true),
                            icon: const Icon(
                              Icons.expand_more,
                              color: Colors.white,
                            ),
                            label: Text(
                              l10n.translate('see_all_plans'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      // Botón "Recalcular mi plan"
                      if (hasRecommendation)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextButton.icon(
                            onPressed: _navigateToRecalculate,
                            icon: const Icon(
                              Icons.autorenew,
                              color: Colors.white70,
                            ),
                            label: Text(
                              l10n.translate('recalculate_my_plan'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Manejar navegación hacia atrás con posible diálogo de retención
  Future<void> _handleBackNavigation() async {
    // Si ya compró, no mostrar retención
    if (_hasPurchased) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Sin recomendación → no hay contexto para retención
    if (widget.recommendedTier == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Verificar cooldown de 7 días
    final canShow = await _quizAnalyticsService.canShowRetention();
    if (!canShow) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Obtener plan recomendado para la oferta
    final recPlan = _allPlans.cast<_PlanData?>().firstWhere(
      (p) => p!.tier == widget.recommendedTier,
      orElse: () => null,
    );
    if (recPlan == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Marcar retención como mostrada
    await _quizAnalyticsService.markRetentionShown();

    if (!mounted) return;
    final accepted = await _showRetentionDialog(recPlan);
    if (accepted == true) return; // Se quedó, no hacer pop
    if (mounted) Navigator.pop(context);
  }

  /// Diálogo de retención: "¡Espera! 50% de descuento"
  Future<bool?> _showRetentionDialog(_PlanData plan) {
    final l10n = AppLocalizations.of(context);
    final discountProductId = _isAnnual
        ? SubscriptionService.getTierProductIds(plan.tier)['annualDiscount']
        : SubscriptionService.getTierProductIds(plan.tier)['monthlyDiscount'];
    final originalPrice = _isAnnual ? plan.annualPrice : plan.monthlyPrice;
    final discountPrice = originalPrice ~/ 2;
    final period = _isAnnual
        ? l10n.translate('per_year')
        : l10n.translate('per_month');

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.orange, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.translate('retention_title'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('retention_body')),
            const SizedBox(height: 16),
            // Plan con descuento
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: plan.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: plan.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.title(l10n)} — 50% OFF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: plan.color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _formatPrice(originalPrice),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPrice(discountPrice),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: plan.color,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        period,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.translate('no_thanks'),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              _handlePurchase(
                context,
                discountProductId,
                '${plan.title(l10n)} 50%',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.translate('claim_discount')),
          ),
        ],
      ),
    );
  }

  /// Toggle Mensual / Anual
  Widget _buildPeriodToggle(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            // Mensual
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isAnnual = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isAnnual ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.translate('monthly_label'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: !_isAnnual
                          ? const Color(0xFF0088CC)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            // Anual
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isAnnual = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isAnnual ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.translate('annual_label'),
                        style: TextStyle(
                          color: _isAnnual
                              ? const Color(0xFF0088CC)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.translate('annual_discount_badge'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta del plan Free
  Widget _buildFreePlanCard(BuildContext context, AppLocalizations l10n) {
    final isCurrentPlan = _currentTier == 'free';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.translate('plan_name_free'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('price_free'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.translate('free_forever'),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...[
              '1 ${l10n.translate('vehicle').toLowerCase()}',
              l10n.translate('feature_local_storage'),
              l10n.translate('feature_unlimited_documents'),
              l10n.translate('feature_try_all_features'),
            ].map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : null, // Free no requiere compra
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentPlan
                      ? Colors.grey.shade300
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCurrentPlan
                      ? l10n.translate('current_plan_btn')
                      : l10n.translate('free_forever'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlan ? Colors.grey.shade600 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required _PlanData plan,
    required AppLocalizations l10n,
    bool isRecommended = false,
  }) {
    final isCurrentPlan = _currentTier == plan.tier;
    final productId = _isAnnual ? plan.annualProductId : plan.monthlyProductId;

    // Precio a mostrar
    final displayPrice = _isAnnual ? plan.annualPrice : plan.monthlyPrice;
    final period = _isAnnual
        ? l10n.translate('per_year')
        : l10n.translate('per_month');

    // Upgrade/downgrade logic
    bool showUpgradeDowngrade = false;
    bool isUpgrade = false;

    if (!isCurrentPlan && _currentTier != null && _currentTier != 'free') {
      final currentIndex = _tierOrder.indexOf(_currentTier ?? 'free');
      final planIndex = _tierOrder.indexOf(plan.tier);
      if (currentIndex != -1 && planIndex != -1 && currentIndex != planIndex) {
        showUpgradeDowngrade = true;
        isUpgrade = planIndex > currentIndex;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isRecommended
            ? Border.all(color: Colors.orange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Badge de recomendado
          if (isRecommended && !showUpgradeDowngrade)
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
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  l10n.translate('recommended'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // Badge de upgrade/downgrade
          if (showUpgradeDowngrade)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isUpgrade
                      ? Colors.green.shade600
                      : Colors.blue.shade600,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUpgrade ? Colors.green : Colors.blue)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUpgrade ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUpgrade
                          ? l10n.translate('upgrade')
                          : l10n.translate('downgrade'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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
                        color: plan.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      plan.title(l10n),
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _formatPrice(displayPrice),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: plan.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Precio mensual tachado + equivalente (solo en modo anual)
                if (_isAnnual) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatPrice(plan.monthlyPrice * 12),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n
                            .translate('equivalent_monthly')
                            .replaceAll(
                              '{price}',
                              _formatPrice(plan.annualPrice ~/ 12),
                            ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Cantidad de vehículos
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: plan.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n
                        .translate('up_to_vehicles_plural')
                        .replaceAll('{count}', plan.maxVehicles.toString()),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: plan.color,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Features
                ...plan
                    .features(l10n)
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: plan.color,
                              size: 20,
                            ),
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
                        : () => _handlePurchase(
                            context,
                            productId,
                            plan.title(l10n),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? Colors.grey.shade300
                          : plan.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCurrentPlan ? 0 : 2,
                    ),
                    child: Text(
                      isCurrentPlan
                          ? l10n.translate('current_plan_btn')
                          : (_currentTier != null && _currentTier != 'free'
                                ? l10n.translate('change_to_this_plan')
                                : l10n.translate('select_plan_btn')),
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
    final l10n = AppLocalizations.of(context);

    if (productId == null) {
      // Plan Enterprise - contactar ventas
      _showContactSalesDialog(context);
      return;
    }

    // Verificar si hay suscripción activa
    final currentSubInfo = await _subscriptionService
        .getCurrentSubscriptionInfo();
    final isChangingPlan = currentSubInfo != null;

    String dialogTitle;
    String dialogMessage;

    if (isChangingPlan) {
      final currentProductId = currentSubInfo['productId'] as String?;
      if (currentProductId != null) {
        final comparison = _subscriptionService.comparePlans(
          currentProductId,
          productId,
        );

        if (comparison > 0) {
          // Upgrade
          dialogTitle = l10n
              .translate('upgrade_to')
              .replaceAll('{plan}', planName);
          dialogMessage = l10n
              .translate('upgrade_message')
              .replaceAll('{plan}', planName);
        } else if (comparison < 0) {
          // Downgrade
          dialogTitle = l10n
              .translate('change_to')
              .replaceAll('{plan}', planName);
          dialogMessage = l10n
              .translate('downgrade_message')
              .replaceAll('{plan}', planName);
        } else {
          // Mismo nivel (no debería pasar)
          dialogTitle = l10n
              .translate('change_to')
              .replaceAll('{plan}', planName);
          dialogMessage = l10n
              .translate('subscribe_message')
              .replaceAll('{plan}', planName);
        }
      } else {
        dialogTitle = l10n
            .translate('change_to')
            .replaceAll('{plan}', planName);
        dialogMessage = l10n
            .translate('subscribe_message')
            .replaceAll('{plan}', planName);
      }
    } else {
      // Nueva suscripción
      dialogTitle = l10n
          .translate('subscribe_to')
          .replaceAll('{plan}', planName);
      dialogMessage = l10n
          .translate('subscribe_message')
          .replaceAll('{plan}', planName);
    }

    // Mostrar diálogo de confirmación
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(dialogTitle),
        content: Text(dialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: Text(l10n.translate('continue')),
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
      // Intentar comprar o cambiar la suscripción
      final success = await _subscriptionService.purchaseSubscription(
        productId,
        isChanging: isChangingPlan,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga

      if (success) {
        // Éxito - actualizar UI
        _hasPurchased = true;
        await _quizAnalyticsService.markConversion();
        await _initializeSubscriptions();

        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isChangingPlan ? Icons.swap_horiz : Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                Text(
                  isChangingPlan
                      ? l10n.translate('change_processed')
                      : l10n.translate('purchase_processed'),
                ),
              ],
            ),
            content: Text(
              isChangingPlan
                  ? l10n
                        .translate('change_sent_message')
                        .replaceAll('{plan}', planName)
                  : l10n
                        .translate('purchase_sent_message')
                        .replaceAll('{plan}', planName),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Volver a pantalla anterior
                },
                child: Text(l10n.translate('understood')),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog(context, l10n.translate('purchase_not_completed'));
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga
      _showErrorDialog(context, 'Error: $e');
    }
  }

  Future<void> _verifySubscriptionStatus() async {
    final l10n = AppLocalizations.of(context);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.translate('verifying_with_google_play'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      // Restaurar y validar compras con Google Play
      final success = await _subscriptionService.restoreAndValidatePurchases();

      if (!mounted) return;
      Navigator.pop(context); // Cerrar indicador de carga

      if (success) {
        // Recargar datos del usuario
        await _initializeSubscriptions();

        if (!mounted) return;

        // Mostrar resultado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Text(l10n.translate('verification_complete')),
              ],
            ),
            content: Text(
              _currentTier != null && _currentTier != 'free'
                  ? l10n
                        .translate('subscription_active')
                        .replaceAll('{tier}', _currentTier!.toUpperCase())
                  : l10n.translate('no_active_subscriptions'),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.translate('understood')),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        _showErrorDialog(context, l10n.translate('could_not_verify_status'));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(
        context,
        l10n.translate('verify_error').replaceAll('{error}', e.toString()),
      );
    }
  }

  void _showContactSalesDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            Text(l10n.translate('plan_enterprise_title')),
          ],
        ),
        content: Text(l10n.translate('enterprise_contact_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('close')),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí se podría abrir el email o el teléfono
              Navigator.pop(context);
            },
            child: Text(l10n.translate('contact')),
          ),
        ],
      ),
    );
  }

  void _openGooglePlaySubscriptions() {
    final l10n = AppLocalizations.of(context);

    // Mostrar diálogo informativo sobre cómo gestionar la suscripción
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFF17A2B8)),
            const SizedBox(width: 12),
            Text(l10n.translate('manage_subscription')),
          ],
        ),
        content: Text(l10n.translate('manage_subscription_instructions')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // En producción, aquí abrirías el deep link a Google Play:
              // launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: Text(l10n.translate('understood')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Text(l10n.translate('error')),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('understood')),
          ),
        ],
      ),
    );
  }
}
