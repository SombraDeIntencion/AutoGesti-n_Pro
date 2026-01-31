import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../services/media_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Vehículo' : 'Agregar Vehículo'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
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
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: _vehiclePhotoUrl != null
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
                                color: Color(0xFF06B6D4),
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
                          label: 'Nombre del Vehículo',
                          icon: Icons.label,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _brandController,
                          label: 'Marca',
                          icon: Icons.branding_watermark,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _modelController,
                          label: 'Modelo',
                          icon: Icons.car_repair,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _yearController,
                          label: 'Año',
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa el año';
                            }
                            final year = int.tryParse(value);
                            if (year == null || year < 1900 || year > 2100) {
                              return 'Año inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _plateController,
                          label: 'Placa',
                          icon: Icons.credit_card,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa la placa';
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
                      backgroundColor: const Color(0xFF06B6D4),
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
                            isEditing ? 'Actualizar' : 'Guardar',
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
        prefixIcon: Icon(icon, color: const Color(0xFF1E40AF)),
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
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Future<void> _takeVehiclePhoto() async {
    try {
      final photoFile = await _mediaService.takePhoto();
      if (photoFile != null) {
        // Generar ID temporal para nuevo vehículo si no existe
        final tempVehicleId = widget.vehicle?.id ?? const Uuid().v4();
        
        // Subir foto a Firebase Storage
        final photoUrl = await _vehicleService.uploadImage(
          photoFile,
          tempVehicleId,
          'photos',
        );

        setState(() {
          _vehiclePhotoUrl = photoUrl;
        });
      }
    } catch (e) {
      // Error al capturar foto
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Guardando vehículo
      final vehicleId = widget.vehicle?.id ?? const Uuid().v4();
      final userId = _vehicleService.currentUserId ?? '';
      
      final vehicle = Vehicle(
        id: vehicleId,
        userId: userId,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        plate: _plateController.text.trim().toUpperCase(),
        photo: _vehiclePhotoUrl,
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
        success = await _vehicleService.saveVehicle(vehicle);
        
        // Si no se pudo guardar por límites freemium
        if (!success && mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Has alcanzado el límite de vehículos de tu plan.\n'
                'Actualiza tu suscripción para agregar más vehículos.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.vehicle != null
                  ? 'Vehículo actualizado correctamente'
                  : 'Vehículo agregado correctamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
