import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../services/media_service.dart';
import '../services/auth_service.dart';
import '../screens/vehicle_details_screen.dart';
import '../screens/vehicle_form_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/expiration_alerts_widget.dart';
import '../widgets/vehicle_limit_indicator.dart';
import '../widgets/upgrade_banner.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final VehicleService _vehicleService = VehicleService();
  final MediaService _mediaService = MediaService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
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
                            child: const Text(
                              'AutoGestión\nPro',
                              style: TextStyle(
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
                            child: const Text(
                              'Gestión de Flotilla de\nVehículos',
                              style: TextStyle(
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
                          color: Colors.white.withOpacity(0.2),
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
                          case 'logout':
                            _handleLogout(context);
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
                              const Text('Mi Perfil'),
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
                              const Text('Ver Planes'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Cerrar Sesión',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Widget de límites de vehículos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _vehicleService.getVehicleLimits(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final limits = snapshot.data!;
                    return VehicleLimitIndicator(
                      currentVehicles: limits['current'] ?? 0,
                      maxVehicles: limits['max'] ?? 1,
                      subscriptionTier: limits['tier'] ?? 'free',
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Banner de actualización para usuarios free
              FutureBuilder<Map<String, dynamic>>(
                future: _vehicleService.getVehicleLimits(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  final limits = snapshot.data!;
                  return UpgradeBanner(
                    subscriptionTier: limits['tier'] ?? 'free',
                    onUpgradeTap: () => _navigateToSubscriptionPlans(context),
                  );
                },
              ),

              // Lista de vehículos
              Expanded(
                child: StreamBuilder<List<Vehicle>>(
                  stream: _vehicleService.getVehicles(),
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

                    final vehicles = snapshot.data ?? [];

                    if (vehicles.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay vehículos',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca el botón de arriba para agregar uno',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
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
                        // Lista de vehículos
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: vehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = vehicles[index];
                              return _VehicleCard(
                                vehicle: vehicle,
                                onTap: () =>
                                    _navigateToVehicleDetails(context, vehicle),
                                onDelete: () => _deleteVehicle(vehicle.id),
                                onUpdatePhoto: () =>
                                    _updateVehiclePhoto(vehicle),
                              );
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
        future: _vehicleService.getVehicleLimits(),
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
              isAtLimit ? 'Límite alcanzado' : 'Agregar Vehículo',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: isAtLimit
                ? Colors.orange
                : const Color(0xFF06B6D4),
            elevation: 6,
          );
        },
      ),
    );
  }

  void _showLimitReachedDialog(BuildContext context) {
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
            const Expanded(child: Text('Límite Alcanzado')),
          ],
        ),
        content: const Text(
          'Has alcanzado el límite de vehículos de tu plan actual.\n\n'
          '¿Quieres ver los planes disponibles para agregar más vehículos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  void _navigateToSubscriptionPlans(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionPlansScreen()),
    );
  }

  void _navigateToAddVehicle(BuildContext context) async {
    // Verificar límites antes de navegar
    final canAdd = await _vehicleService.canAddVehicle();

    if (!canAdd && context.mounted) {
      _showLimitReachedDialog(context);
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VehicleFormScreen()),
      );
    }
  }

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión?\n\n'
          'Tus datos están guardados de forma segura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _authService.signOut();
      // El AuthGate detectará el cambio y redirigirá al login
    }
  }

  void _navigateToVehicleDetails(BuildContext context, Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
      ),
    );
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehículo eliminado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar vehículo: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _updateVehiclePhoto(Vehicle vehicle) async {
    try {
      final photoFile = await _mediaService.takePhoto();
      if (photoFile != null) {
        // Mostrar indicador de carga
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(width: 16),
                  Text('Subiendo foto...'),
                ],
              ),
              duration: Duration(seconds: 30),
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
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto actualizada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar foto: $e'),
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
    return AlertDialog(
      title: const Text('Eliminar vehículo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Esta acción no se puede deshacer.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Para confirmar la eliminación, escribe el siguiente código:',
            ),
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
              decoration: const InputDecoration(
                labelText: 'Escribe el código',
                border: OutlineInputBorder(),
                hintText: 'Código de confirmación',
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
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: isCodeCorrect ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            disabledForegroundColor: Colors.grey,
          ),
          child: const Text('Eliminar'),
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
            Color(0xFF06B6D4), // Cyan
            Color(0xFF3B82F6), // Azul medio
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                      color: Colors.white.withOpacity(0.15),
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
                          color: Colors.black.withOpacity(0.4),
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
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
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
                    Text(
                      'Placa: ${vehicle.plate}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
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
