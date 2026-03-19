import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/quiz_analytics_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import 'subscription_plans_screen.dart';

/// Pantalla de onboarding con quiz de 2 pasos antes de mostrar planes
class SubscriptionOnboardingScreen extends StatefulWidget {
  /// Si es true, es el onboarding post-registro (obligatorio)
  /// Si es false, se accedió desde "Ver planes"
  final bool isPostRegistration;

  const SubscriptionOnboardingScreen({
    super.key,
    this.isPostRegistration = false,
  });

  @override
  State<SubscriptionOnboardingScreen> createState() =>
      _SubscriptionOnboardingScreenState();
}

class _SubscriptionOnboardingScreenState
    extends State<SubscriptionOnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _vehicleCountController = TextEditingController();
  final QuizAnalyticsService _quizService = QuizAnalyticsService();

  int _currentPage = 0;
  int _vehicleCount = 0;
  String? _usageType;

  @override
  void dispose() {
    _pageController.dispose();
    _vehicleCountController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _usageType == null) return;
    if (_currentPage == 1 && _vehicleCount <= 0) return;

    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == 1) {
      _completeQuiz();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _completeQuiz() async {
    try {
      await _quizService.saveQuizResponse(
        vehicleCount: _vehicleCount,
        usageType: _usageType!,
      );
    } catch (_) {
      // Si falla guardar en Firestore, continuar de todas formas
    }

    if (!mounted) return;

    // Si dijo 1 vehículo y es post-registro → directo a la app
    if (_vehicleCount == 1 && widget.isPostRegistration) {
      Navigator.pop(context, {'completed': true, 'vehicleCount': 1});
      return;
    }

    // Si dijo >50 → contacto
    if (_vehicleCount > 50) {
      _showContactDialog();
      return;
    }

    // Ir a pantalla de planes con recomendación
    final recommendedTier = QuizAnalyticsService.getRecommendedTier(
      _vehicleCount,
    );

    if (!mounted) return;

    // Reemplazar esta pantalla con la de planes
    final result = await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionPlansScreen(
          recommendedTier: recommendedTier,
          vehicleCount: _vehicleCount,
        ),
      ),
    );

    // Si es post-registro y volvió sin comprar → resultado al caller
    if (widget.isPostRegistration && mounted) {
      Navigator.pop(context, result ?? {'completed': true});
    }
  }

  void _showContactDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.business, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.translate('enterprise_solution'))),
          ],
        ),
        content: Text(l10n.translate('enterprise_contact_50plus')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Volver con 50 para mostrar enterprise
              setState(() => _vehicleCount = 50);
              _vehicleCountController.text = '50';
            },
            child: Text(l10n.translate('see_enterprise_plan')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.isPostRegistration) {
                Navigator.pop(context, {
                  'completed': true,
                  'vehicleCount': _vehicleCount,
                });
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: Text(l10n.translate('contact_us')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header con botón atrás
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (!widget.isPostRegistration || _currentPage > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _previousPage,
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    // Botón saltar (solo en post-registro)
                    if (widget.isPostRegistration)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            'completed': true,
                            'skipped': true,
                          });
                        },
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('skip_for_now'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Contenido
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [_buildStep2UsageType(), _buildStep1VehicleCount()],
                ),
              ),
              // Indicadores de paso + botón
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Paso 1: ¿Cuántos vehículos administras?
  Widget _buildStep1VehicleCount() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Ícono grande con animación sutil
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),

          // Título
          Text(
            l10n.translate('personalize_experience'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Pregunta
          Text(
            l10n.translate('how_many_vehicles'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Campo de entrada numérico limpio
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                  blurRadius: 40,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Campo numérico centrado
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _vehicleCountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade300,
                        letterSpacing: 2,
                      ),
                      filled: false,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _vehicleCount = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                // Línea decorativa debajo del número
                Container(
                  width: 100,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withValues(alpha: 0.2),
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlue.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.translate('vehicles').toLowerCase(),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Texto motivador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('well_recommend_ideal_plan'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Paso 2: ¿Cómo usarás AutoGestión Max?
  Widget _buildStep2UsageType() {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Ícono grande
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Pregunta
          Text(
            l10n.translate('how_will_you_use'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Opciones
          _buildUsageOption(
            icon: Icons.directions_car,
            title: l10n.translate('personal_vehicle'),
            subtitle: l10n.translate('personal_vehicle_desc'),
            value: 'personal',
          ),
          const SizedBox(height: 16),
          _buildUsageOption(
            icon: Icons.business,
            title: l10n.translate('small_business'),
            subtitle: l10n.translate('small_business_desc'),
            value: 'business',
          ),
          const SizedBox(height: 16),
          _buildUsageOption(
            icon: Icons.local_shipping,
            title: l10n.translate('fleet'),
            subtitle: l10n.translate('fleet_desc'),
            value: 'fleet',
          ),
        ],
      ),
    );
  }

  Widget _buildUsageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _usageType == value;

    return GestureDetector(
      onTap: () => setState(() => _usageType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentOrange : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.accentOrange.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentOrange.withValues(alpha: 0.1)
                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppTheme.accentOrange
                    : AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.accentOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final l10n = AppLocalizations.of(context);
    final isValid = _currentPage == 0 ? _usageType != null : _vehicleCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
      child: Column(
        children: [
          // Indicadores de paso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentPage
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Botón continuar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isValid ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isValid
                    ? AppTheme.accentOrange
                    : Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: isValid ? 4 : 0,
              ),
              child: Text(
                _currentPage == 0
                    ? l10n.translate('continue')
                    : l10n.translate('see_my_ideal_plan'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
