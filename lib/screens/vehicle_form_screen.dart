import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../services/media_service.dart';
import '../utils/permissions_helper.dart';
import '../l10n/app_localizations.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();
  final MediaService _mediaService = MediaService();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateController;

  String? _vehiclePhotoUrl;
  File? _tempPhotoFile; // Archivo temporal antes de guardar
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vehicle?.name ?? '');
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(
      text: widget.vehicle?.year.toString() ?? DateTime.now().year.toString(),
    );
    _plateController = TextEditingController(text: widget.vehicle?.plate ?? '');
    _vehiclePhotoUrl = widget.vehicle?.photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editVehicle : l10n.newVehicle),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF17A2B8), Color(0xFF0088CC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icono del vehículo / Foto
                  Center(
                    child: GestureDetector(
                      onTap: _takeVehiclePhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: _tempPhotoFile != null
                                  ? Image.file(
                                      _tempPhotoFile!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    )
                                  : _vehiclePhotoUrl != null
                                  ? (_vehiclePhotoUrl!.startsWith('http')
                                        ? Image.network(
                                            _vehiclePhotoUrl!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.directions_car,
                                                    size: 60,
                                                    color: Colors.white,
                                                  );
                                                },
                                          )
                                        : Image.file(
                                            File(_vehiclePhotoUrl!),
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.directions_car,
                                                    size: 60,
                                                    color: Colors.white,
                                                  );
                                                },
                                          ))
                                  : const Icon(
                                      Icons.directions_car,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF17A2B8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: l10n.vehicleName,
                          icon: Icons.label,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _brandController,
                          label: l10n.brand,
                          icon: Icons.branding_watermark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _modelController,
                          label: l10n.model,
                          icon: Icons.car_repair,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _yearController,
                          label: l10n.year,
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterYear;
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < 1900 || year > 2100) {
                              return l10n.invalidYear;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _plateController,
                          label: l10n.plate,
                          icon: Icons.credit_card,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.pleaseEnterPlate;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botón Guardar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveVehicle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17A2B8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing ? l10n.updateButton : l10n.saveButton,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF17A2B8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF17A2B8), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _takeVehiclePhoto() async {
    // Solicitar permiso de cámara antes de tomar foto
    if (!mounted) return;

    final hasPermission = await PermissionsHelper.requestCameraPermission(
      context,
    );
    if (!hasPermission) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cameraPermissionNeeded),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      final photoFile = await _mediaService.takePhoto();
      if (photoFile != null) {
        // Guardar archivo temporalmente, se subirá cuando se guarde el vehículo
        if (mounted) {
          setState(() {
            _tempPhotoFile = photoFile;
            // Si es edición y ya tiene foto, mantener la URL existente
            // Si es nuevo, la foto se subirá al guardar
          });
        }
      }
    } catch (e) {
      // Error al capturar foto
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorCapturingPhoto}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capturar l10n y messenger ANTES de cualquier async
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      // Guardando vehículo
      final vehicleId = widget.vehicle?.id ?? const Uuid().v4();
      final userId = _vehicleService.currentUserId ?? '';

      // Si hay una foto temporal, subirla primero
      String? finalPhotoUrl = _vehiclePhotoUrl;
      if (_tempPhotoFile != null) {
        // Para nuevo vehículo, crear el vehículo primero sin foto
        // luego actualizar con la foto
        if (widget.vehicle == null) {
          // Crear vehículo temporal sin foto
          final tempVehicle = Vehicle(
            id: vehicleId,
            userId: userId,
            name: _nameController.text.trim(),
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            year: int.parse(_yearController.text.trim()),
            plate: _plateController.text.trim().toUpperCase(),
          );

          final success = await _vehicleService.saveVehicle(tempVehicle);
          if (!success && mounted) {
            final l10n = AppLocalizations.of(context);
            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.limitReachedUpgradeMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
        }

        // Ahora subir la foto
        try {
          finalPhotoUrl = await _vehicleService.uploadImage(
            _tempPhotoFile!,
            vehicleId,
            'photos',
          );
        } catch (e) {
          // Si falla la subida de foto, continuar sin ella
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.warningCouldNotUploadPhoto}: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      final vehicle = Vehicle(
        id: vehicleId,
        userId: userId,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        plate: _plateController.text.trim().toUpperCase(),
        photo: finalPhotoUrl,
        insurance: widget.vehicle?.insurance,
        driver: widget.vehicle?.driver,
        contract: widget.vehicle?.contract,
        circulationCard: widget.vehicle?.circulationCard,
        maintenance: widget.vehicle?.maintenance,
      );

      bool success;
      if (widget.vehicle != null) {
        success = await _vehicleService.updateVehicle(vehicle);
      } else {
        // Si ya creamos el vehículo arriba, actualizarlo con la foto
        if (_tempPhotoFile != null) {
          success = await _vehicleService.updateVehicle(vehicle);
        } else {
          success = await _vehicleService.saveVehicle(vehicle);

          // Si no se pudo guardar por límites freemium
          if (!success && mounted) {
            setState(() {
              _isLoading = false;
            });

            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.limitReachedUpgradeMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
        }
      }

      if (mounted) {
        navigator.pop();
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicle != null ? l10n.vehicleUpdated : l10n.vehicleAdded,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
