import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../services/media_service.dart';
import '../screens/vehicle_details_screen.dart';
import '../screens/vehicle_form_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/subscription_onboarding_screen.dart';
import '../services/quiz_analytics_service.dart';
import '../screens/profile_screen.dart';
import '../widgets/expiration_alerts_widget.dart';
import '../widgets/vehicle_limit_indicator.dart';
import '../l10n/app_localizations.dart';
import '../utils/rate_limiter.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _vehicleService = VehicleService();
  final MediaService _mediaService = MediaService();

  // Cache para evitar múltiples llamadas a getVehicleLimits
  Future<Map<String, dynamic>>? _vehicleLimitsFuture;

  // Cache del stream de vehículos para evitar recrearlo en cada build
  late final Stream<List<Vehicle>> _vehiclesStream;

  // Para rastrear el número anterior de vehículos
  int _previousVehicleCount = 0;

  // Controlador para el campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Cache del stream para evitar recrearlo en cada build
    _vehiclesStream = _vehicleService.getVehicles();
    // Sincronizar contador de vehículos al iniciar
    _syncVehicleCount();
    // Inicializar cache de límites
    _vehicleLimitsFuture = _vehicleService.getVehicleLimits();
    // Listener para búsqueda con debouncing
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();

    // Crear nuevo timer con delay de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncVehicleCount() async {
    try {
      await _vehicleService.syncVehicleCount();
      // Actualizar cache después de sincronizar
      if (mounted) {
        setState(() {
          _vehicleLimitsFuture = _vehicleService.getVehicleLimits();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al sincronizar contador: $e');
      }
    }
  }

  // Sincronizar sin setState para evitar problemas en callbacks
  Future<void> _syncVehicleCountSilent() async {
    try {
      await _vehicleService.syncVehicleCount();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al sincronizar contador: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF17A2B8), // Cyan/turquesa
              Color(0xFF0088CC), // Azul
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título a la izquierda
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.appName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.fleetManagement,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Menú de usuario
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                            break;
                          case 'plans':
                            _navigateToSubscriptionPlans(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.myProfile),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'plans',
                          child: Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.viewPlans),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Widget de límites de vehículos (fusionado con upgrade banner)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _vehicleLimitsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final limits = snapshot.data!;
                    return VehicleLimitIndicator(
                      currentVehicles: limits['current'] ?? 0,
                      maxVehicles: limits['max'] ?? 1,
                      subscriptionTier: limits['tier'] ?? 'free',
                      onUpgradeTap: () => _navigateToSubscriptionPlans(context),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Adaptar altura para tablets
                    final isTablet = constraints.maxWidth > 600;
                    return Container(
                      height: isTablet ? 56 : 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                        decoration: InputDecoration(
                          hintText: l10n.searchVehicle,
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: isTablet ? 16 : 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: const Color(0xFF17A2B8),
                            size: isTablet ? 24 : 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[600],
                                    size: isTablet ? 22 : 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: isTablet ? 18 : 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Lista de vehículos
              Expanded(
                child: StreamBuilder<List<Vehicle>>(
                  stream: _vehiclesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    List<Vehicle> vehicles = snapshot.data ?? [];

                    // Filtrar vehículos según la búsqueda
                    if (_searchQuery.isNotEmpty) {
                      vehicles = vehicles.where((vehicle) {
                        final plate = vehicle.plate.toLowerCase();
                        final name = vehicle.name.toLowerCase();
                        final brand = vehicle.brand.toLowerCase();
                        final model = vehicle.model.toLowerCase();
                        final year = vehicle.year.toString();

                        return plate.contains(_searchQuery) ||
                            name.contains(_searchQuery) ||
                            brand.contains(_searchQuery) ||
                            model.contains(_searchQuery) ||
                            year.contains(_searchQuery);
                      }).toList();
                    }

                    // Actualizar límites si el número de vehículos cambió
                    final currentCount = (snapshot.data ?? []).length;
                    if (currentCount != _previousVehicleCount) {
                      // Sincronizar después del build para evitar llamadas durante el render
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _previousVehicleCount = currentCount;
                          _syncVehicleCountSilent();
                        }
                      });
                    }

                    if ((snapshot.data ?? []).isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noVehicles,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tapButtonToAddOne,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (vehicles.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.translate('no_vehicles_found'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.translate('try_another_search'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Widget de alertas de vencimiento
                        ExpirationAlertsWidget(vehicles: vehicles),
                        // Lista de vehículos - Responsivo para tablets
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Determinar si es tablet o celular
                              final isTablet = constraints.maxWidth > 600;

                              if (isTablet) {
                                // Grid para tablets
                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            constraints.maxWidth > 900 ? 3 : 2,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: vehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = vehicles[index];
                                    return _VehicleCard(
                                      key: ValueKey(vehicle.id),
                                      vehicle: vehicle,
                                      onTap: () => _navigateToVehicleDetails(
                                        context,
                                        vehicle,
                                      ),
                                      onDelete: () =>
                                          _deleteVehicle(vehicle.id),
                                      onUpdatePhoto: () =>
                                          _updateVehiclePhoto(vehicle),
                                    );
                                  },
                                );
                              } else {
                                // Lista para celulares
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: vehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = vehicles[index];
                                    return _VehicleCard(
                                      key: ValueKey(vehicle.id),
                                      vehicle: vehicle,
                                      onTap: () => _navigateToVehicleDetails(
                                        context,
                                        vehicle,
                                      ),
                                      onDelete: () =>
                                          _deleteVehicle(vehicle.id),
                                      onUpdatePhoto: () =>
                                          _updateVehiclePhoto(vehicle),
                                    );
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: _vehicleLimitsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final limits = snapshot.data!;
          final canAdd = limits['canAdd'] ?? false;
          final isAtLimit = !canAdd;

          return FloatingActionButton.extended(
            onPressed: canAdd
                ? () => _navigateToAddVehicle(context)
                : () => _showLimitReachedDialog(context),
            icon: Icon(isAtLimit ? Icons.lock : Icons.add, color: Colors.white),
            label: Text(
              isAtLimit ? l10n.limitReached : l10n.addVehicle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: isAtLimit
                ? Colors.orange
                : const Color(0xFF17A2B8),
            elevation: 6,
          );
        },
      ),
    );
  }

  void _showLimitReachedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.limitReached)),
          ],
        ),
        content: Text(l10n.limitReachedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToSubscriptionPlans(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.seePlans),
          ),
        ],
      ),
    );
  }

  /// Diálogo proactivo cuando el usuario alcanza su límite tras agregar un vehículo
  void _showUpgradeSuggestionDialog(
    BuildContext context,
    Map<String, dynamic> limits,
  ) {
    final l10n = AppLocalizations.of(context);
    final currentCount = limits['current'] as int? ?? 0;
    final nextTier = QuizAnalyticsService.getRecommendedTier(currentCount + 1);

    // Si ya está en enterprise50 o superior, no sugerir
    if (nextTier == 'enterprise50+') return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.rocket_launch, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.translate('upgrade_suggestion_title'),
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          l10n
              .translate('upgrade_suggestion_body')
              .replaceAll('{count}', currentCount.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('later')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToSubscriptionPlans(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.translate('see_plans_now')),
          ),
        ],
      ),
    );
  }

  void _navigateToSubscriptionPlans(BuildContext context) async {
    final quizService = QuizAnalyticsService();
    final quizCompleted = await quizService.isQuizCompleted();

    if (!context.mounted) return;

    if (quizCompleted) {
      // Quiz ya completado → ir directo a planes con recomendación guardada
      final vehicleCount = await quizService.getLastVehicleCount();
      final recommendedTier = vehicleCount != null
          ? QuizAnalyticsService.getRecommendedTier(vehicleCount)
          : null;

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionPlansScreen(
            recommendedTier: recommendedTier,
            vehicleCount: vehicleCount,
          ),
        ),
      );
    } else {
      // Quiz no completado → onboarding primero
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionOnboardingScreen(),
        ),
      );
    }
  }

  void _navigateToAddVehicle(BuildContext context) async {
    // Verificar límites antes de navegar
    final canAdd = await _vehicleService.canAddVehicle();

    if (!canAdd && context.mounted) {
      _showLimitReachedDialog(context);
      return;
    }

    if (context.mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VehicleFormScreen()),
      );

      // Si se agregó un vehículo, actualizar cache de límites
      if (result == true && mounted) {
        final newLimits = _vehicleService.getVehicleLimits();
        setState(() {
          _vehicleLimitsFuture = newLimits;
        });

        // Verificar si ahora está al límite → sugerir upgrade
        final limits = await newLimits;
        if (mounted && context.mounted && limits['canAdd'] == false) {
          _showUpgradeSuggestionDialog(context, limits);
        }
      }
    }
  }

  void _navigateToVehicleDetails(BuildContext context, Vehicle vehicle) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
      ),
    );

    // Actualizar límites al regresar (por si se eliminó el vehículo)
    if (mounted) {
      setState(() {
        _vehicleLimitsFuture = _vehicleService.getVehicleLimits();
      });
    }
  }

  String _generateRandomCode() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    // Rate limiting: evitar llamadas masivas
    if (!RateLimiter().canProceed(
      'deleteVehicle',
      minInterval: const Duration(seconds: 3),
    )) {
      return;
    }

    // Capturar l10n y messenger ANTES de cualquier async
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmationCode = _generateRandomCode();
    final textController = TextEditingController();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteConfirmationDialog(
        confirmationCode: confirmationCode,
        textController: textController,
        onCodeChanged: (correct) {
          // Callback para actualizar estado en el diálogo
        },
      ),
    );

    textController.dispose();

    if (confirmed == true && mounted) {
      try {
        await _vehicleService.deleteVehicle(vehicleId);

        // Actualizar cache de límites después de eliminar
        if (mounted) {
          setState(() {
            _vehicleLimitsFuture = _vehicleService.getVehicleLimits();
          });

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.translate('vehicle_deleted_successfully')),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.errorDeletingVehicle),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _updateVehiclePhoto(Vehicle vehicle) async {
    // Rate limiting: evitar subidas masivas
    if (!RateLimiter().canProceed(
      'uploadPhoto',
      minInterval: const Duration(seconds: 3),
    )) {
      return;
    }

    // Capturar l10n y messenger ANTES de cualquier async
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final photoFile = await _mediaService.takePhoto();
      if (photoFile != null) {
        // Mostrar indicador de carga
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(width: 16),
                  Text(l10n.uploadingPhoto),
                ],
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }

        // Subir foto a Firebase Storage
        final photoUrl = await _vehicleService.uploadImage(
          photoFile,
          vehicle.id,
          'photos',
        );

        // Actualizar vehículo con la nueva foto
        final updatedVehicle = vehicle.copyWith(photo: photoUrl);
        await _vehicleService.updateVehicle(updatedVehicle);

        if (mounted) {
          setState(() {
            _vehicleLimitsFuture = _vehicleService.getVehicleLimits();
          });

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.photoUpdated),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorUpdatingPhoto),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final String confirmationCode;
  final TextEditingController textController;
  final ValueChanged<bool> onCodeChanged;

  const _DeleteConfirmationDialog({
    required this.confirmationCode,
    required this.textController,
    required this.onCodeChanged,
  });

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  bool isCodeCorrect = false;

  @override
  void dispose() {
    // El TextEditingController se maneja en el padre, no lo dispose aquí
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.deleteVehicle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.actionCannotBeUndone,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.enterCodeToConfirm),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: SelectableText(
                widget.confirmationCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.textController,
              decoration: InputDecoration(
                labelText: l10n.enterCode,
                border: const OutlineInputBorder(),
                hintText: l10n.confirmationCode,
              ),
              onChanged: (value) {
                setState(() {
                  isCodeCorrect = value == widget.confirmationCode;
                });
                widget.onCodeChanged(isCodeCorrect);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: isCodeCorrect ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            disabledForegroundColor: Colors.grey,
          ),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onUpdatePhoto;

  const _VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onDelete,
    required this.onUpdatePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF17A2B8), // Cyan/turquesa
            Color(0xFF0088CC), // Azul
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Área del encabezado con imagen del vehículo
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: vehicle.photo != null && vehicle.photo!.isNotEmpty
                          ? (vehicle.photo!.startsWith('http')
                                ? Image.network(
                                    vehicle.photo!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 140,
                                    cacheWidth: 400, // Optimizar para Android
                                    cacheHeight: 280,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      // Error al cargar imagen desde red
                                      return const Center(
                                        child: Icon(
                                          Icons.directions_car,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(vehicle.photo!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 140,
                                    cacheWidth: 400, // Optimizar para Android
                                    cacheHeight: 280,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Error al cargar archivo local
                                      return const Center(
                                        child: Icon(
                                          Icons.directions_car,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ))
                          : const Center(
                              child: Icon(
                                Icons.directions_car,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  // Botón de cámara (izquierda)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: onUpdatePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Botón de menú (derecha)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      itemBuilder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(l10n.delete),
                              ],
                            ),
                          ),
                        ];
                      },
                      onSelected: (value) {
                        if (value == 'delete') {
                          // Usar SchedulerBinding para asegurar que el popup se cierre antes de abrir el diálogo
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onDelete();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Información del vehículo
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.brand} ${vehicle.model} ${vehicle.year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Text(
                          '${l10n.plate}: ${vehicle.plate}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
