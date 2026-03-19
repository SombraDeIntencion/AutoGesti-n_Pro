import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/native_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import '../models/checklist_item.dart';
import '../models/vehicle.dart';
import '../models/inspection_record.dart';
import '../services/media_service.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'photo_gallery_viewer.dart';

// Helper para obtener el directorio de descargas visible para el usuario
Future<Directory> _getDownloadsDirectory() async {
  if (Platform.isAndroid) {
    // Usar carpeta pública de Downloads
    // Ruta resultante: /storage/emulated/0/Download/Reportes
    final downloadsDir = Directory('/storage/emulated/0/Download/Reportes');

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    return downloadsDir;
  } else {
    // En iOS/otros, usar documentos de la app
    return await getApplicationDocumentsDirectory();
  }
}

/// Widget interactivo para el checklist de inspección vehicular
class VehicleInspectionChecklist extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onUpdate;

  const VehicleInspectionChecklist({
    super.key,
    required this.vehicle,
    required this.onUpdate,
  });

  @override
  State<VehicleInspectionChecklist> createState() =>
      _VehicleInspectionChecklistState();
}

class _VehicleInspectionChecklistState
    extends State<VehicleInspectionChecklist> {
  late List<ChecklistItem> _checklistItems;
  List<String> _localPhotos = []; // Fotos locales temporales (archivos o URLs)
  final MediaService _mediaService = MediaService();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitialized = false; // Bandera para saber si ya se inicializó

  // Helper para determinar si una ruta es una URL de red
  bool _isNetworkUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  // Helper para construir un widget de imagen según el tipo de ruta
  Widget _buildImageWidget(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (_isNetworkUrl(path)) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar foto',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      final photoFile = File(path);
      if (!photoFile.existsSync()) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                'Foto no encontrada',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }
      return Image.file(
        photoFile,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 60, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'Error al cargar foto',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Solo cargar items sin traducir en initState
    if (widget.vehicle.maintenance.checklist.isNotEmpty) {
      _checklistItems = List<ChecklistItem>.from(
        widget.vehicle.maintenance.checklist,
      );
    } else {
      _checklistItems = []; // Se creará en didChangeDependencies
    }
    _localPhotos = [];
  }

  @override
  void didUpdateWidget(VehicleInspectionChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo actualizar si el vehículo cambió y está montado
    if (!mounted) return;

    // Si el vehículo cambió externamente (no por nuestra propia actualización)
    // actualizar el checklist, pero solo si el ID del vehículo cambió
    if (oldWidget.vehicle.id != widget.vehicle.id) {
      setState(() {
        if (widget.vehicle.maintenance.checklist.isNotEmpty) {
          _checklistItems = List<ChecklistItem>.from(
            widget.vehicle.maintenance.checklist,
          );
          _updateItemTranslations();
        } else {
          _checklistItems = _createDefaultChecklist(context);
        }
        _localPhotos = [];
      });
    } else if (oldWidget.vehicle.maintenance.checklist.length !=
        widget.vehicle.maintenance.checklist.length) {
      // Si la longitud del checklist cambió, reinicializar
      setState(() {
        _checklistItems = List<ChecklistItem>.from(
          widget.vehicle.maintenance.checklist,
        );
        _updateItemTranslations();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inicializar en el primer didChangeDependencies
    if (!_isInitialized) {
      _isInitialized = true;
      if (_checklistItems.isEmpty) {
        // Crear checklist por defecto con traducciones
        _checklistItems = _createDefaultChecklist(context);
      } else {
        // Actualizar traducciones de items existentes
        _updateItemTranslations();
      }
    }
  }

  /// Actualiza los nombres de los items del checklist con las traducciones actuales
  /// basándose en los IDs de los items
  void _updateItemTranslations() {
    final l10n = AppLocalizations.of(context);

    for (int i = 0; i < _checklistItems.length; i++) {
      final item = _checklistItems[i];
      String translatedName =
          item.name; // Por defecto, mantener el nombre actual

      // Mapear IDs a traducciones
      switch (item.id) {
        case 'int_ext_1':
          translatedName = l10n.checkItemWindowsGlass;
          break;
        case 'int_ext_2':
          translatedName = l10n.checkItemMirrors;
          break;
        case 'int_ext_3':
          translatedName = l10n.checkItemExteriorLights;
          break;
        case 'int_ext_4':
          translatedName = l10n.checkItemBodyPaint;
          break;
        case 'int_ext_5':
          translatedName = l10n.checkItemChassis;
          break;
        case 'int_ext_6':
          translatedName = l10n.checkItemDoors;
          break;
        case 'int_ext_7':
          translatedName = l10n.checkItemWindshield;
          break;
        case 'int_ext_8':
          translatedName = l10n.checkItemWipers;
          break;
        case 'int_ext_9':
          translatedName = l10n.checkItemHorn;
          break;
        case 'int_ext_10':
          translatedName = l10n.checkItemSeatbelts;
          break;
        case 'int_ext_11':
          translatedName = l10n.checkItemUpholstery;
          break;
        case 'int_ext_12':
          translatedName = l10n.checkItemOdometer;
          break;
        case 'hood_1':
          translatedName = l10n.checkItemEngineOil;
          break;
        case 'hood_2':
          translatedName = l10n.checkItemOilFilter;
          break;
        case 'hood_3':
          translatedName = l10n.checkItemBrakeFluid;
          break;
        case 'hood_4':
          translatedName = l10n.checkItemCoolant;
          break;
        case 'hood_5':
          translatedName = l10n.checkItemBelts;
          break;
        case 'hood_6':
          translatedName = l10n.checkItemBattery;
          break;
        case 'hood_7':
          translatedName = l10n.checkItemAirFilter;
          break;
        case 'hood_8':
          translatedName = l10n.checkItemFuelFilter;
          break;
        case 'hood_9':
          translatedName = l10n.checkItemSparkPlugs;
          break;
        case 'hood_10':
          translatedName = l10n.checkItemHoses;
          break;
        case 'hood_11':
          translatedName = l10n.checkItemBatteryCharge;
          break;
        case 'hood_12':
          translatedName = l10n.checkItemBatteryCondition;
          break;
        case 'tire_1':
          translatedName = l10n.checkItemFrontTirePressure;
          break;
        case 'tire_2':
          translatedName = l10n.checkItemRearTirePressure;
          break;
        case 'tire_3':
          translatedName = l10n.checkItemFrontTireWear;
          break;
        case 'tire_4':
          translatedName = l10n.checkItemRearTireWear;
          break;
        case 'tire_5':
          translatedName = l10n.checkItemWheelBalance;
          break;
        case 'tire_6':
          translatedName = l10n.checkItemWheelAlignment;
          break;
        case 'tire_7':
          translatedName = l10n.checkItemTireRotation;
          break;
      }

      // Actualizar el item con el nombre traducido
      if (translatedName != item.name) {
        _checklistItems[i] = item.copyWith(name: translatedName);
      }
    }
  }

  List<ChecklistItem> _createDefaultChecklist(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      // INTERIOR/EXTERIOR
      ChecklistItem(
        id: 'int_ext_1',
        name: l10n.checkItemWindowsGlass,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_2',
        name: l10n.checkItemMirrors,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_3',
        name: l10n.checkItemExteriorLights,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_4',
        name: l10n.checkItemBodyPaint,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_5',
        name: l10n.checkItemChassis,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_6',
        name: l10n.checkItemDoors,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_7',
        name: l10n.checkItemWindshield,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_8',
        name: l10n.checkItemWipers,
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_9',
        name: l10n.checkItemHorn,
        category: ChecklistCategory.interior,
      ),
      ChecklistItem(
        id: 'int_ext_10',
        name: l10n.checkItemSeatbelts,
        category: ChecklistCategory.interior,
      ),
      ChecklistItem(
        id: 'int_ext_11',
        name: l10n.checkItemUpholstery,
        category: ChecklistCategory.interior,
      ),
      ChecklistItem(
        id: 'int_ext_12',
        name: l10n.checkItemOdometer,
        category: ChecklistCategory.interior,
      ),

      // BAJO EL CAPÓ
      ChecklistItem(
        id: 'hood_1',
        name: l10n.checkItemEngineOil,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_2',
        name: l10n.checkItemOilFilter,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_3',
        name: l10n.checkItemBrakeFluid,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_4',
        name: l10n.checkItemCoolant,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_5',
        name: l10n.checkItemBelts,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_6',
        name: l10n.checkItemBattery,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_7',
        name: l10n.checkItemAirFilter,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_8',
        name: l10n.checkItemFuelFilter,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_9',
        name: l10n.checkItemSparkPlugs,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_10',
        name: l10n.checkItemHoses,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_11',
        name: l10n.checkItemBatteryCharge,
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_12',
        name: l10n.checkItemBatteryCondition,
        category: ChecklistCategory.underhood,
      ),

      // NEUMÁTICOS
      ChecklistItem(
        id: 'tire_1',
        name: l10n.checkItemFrontTirePressure,
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_2',
        name: l10n.checkItemRearTirePressure,
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_3',
        name: l10n.checkItemFrontTireWear,
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_4',
        name: l10n.checkItemRearTireWear,
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_5',
        name: l10n.checkItemWheelBalance,
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_6',
        name: l10n.checkItemWheelAlignment,
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_7',
        name: l10n.checkItemTireRotation,
        category: ChecklistCategory.tires,
      ),
    ];
  }

  void _updateItemStatus(int index, ChecklistStatus newStatus) {
    if (!mounted) return;

    setState(() {
      _checklistItems[index] = _checklistItems[index].copyWith(
        status: newStatus,
      );
    });

    // Actualizar el vehículo
    final updatedMaintenance = widget.vehicle.maintenance.copyWith(
      checklist: _checklistItems,
    );
    widget.onUpdate(widget.vehicle.copyWith(maintenance: updatedMaintenance));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 24),
          // Diagrama del vehículo
          _buildVehicleDiagram(),
          const SizedBox(height: 24),
          // Leyenda
          _buildLegend(),
          const SizedBox(height: 24),
          // Secciones de inspección
          _buildInspectionSection(
            AppLocalizations.of(context).sectionInteriorExterior,
            ChecklistCategory.exterior,
            ChecklistCategory.interior,
          ),
          const SizedBox(height: 16),
          _buildInspectionSection(
            AppLocalizations.of(context).sectionUnderHood,
            ChecklistCategory.underhood,
          ),
          const SizedBox(height: 16),
          _buildInspectionSection(
            AppLocalizations.of(context).sectionTires,
            ChecklistCategory.tires,
          ),
          const SizedBox(height: 24),
          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17A2B8), Color(0xFF0088CC)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).vehicleInspectionReport,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).clickBoxesToChangeStatus,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDiagram() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Carrusel de fotos o placeholder
          if (_localPhotos.isEmpty)
            _buildEmptyPhotosPlaceholder()
          else
            _buildPhotosCarousel(_localPhotos),
          const SizedBox(height: 12),
          // Botón para agregar fotos
          _buildAddPhotoButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotosPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 80,
              color: const Color(0xFF17A2B8).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.vehicle.brand} ${widget.vehicle.model}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              '${AppLocalizations.of(context).year}: ${widget.vehicle.year}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).tapButtonToAddPhotos,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCarousel(List<String> photos) {
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photoPath = photos[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    children: [
                      // Foto
                      GestureDetector(
                        onTap: () => _viewFullImage(photoPath),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(
                            photoPath,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Botón eliminar
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _deleteInspectionPhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Indicador de página
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${index + 1} / ${photos.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).swipeToSeeMore,
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF64748B).withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    final canAddMore = _localPhotos.length < 9;
    final l10n = AppLocalizations.of(context);

    return ElevatedButton.icon(
      onPressed: canAddMore ? _addInspectionPhoto : null,
      icon: const Icon(Icons.add_a_photo, size: 20),
      label: Text(
        canAddMore
            ? l10n.addPhotoCount(_localPhotos.length)
            : l10n.maxPhotosReached,
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canAddMore ? const Color(0xFF17A2B8) : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _addInspectionPhoto() async {
    final l10n = AppLocalizations.of(context);

    if (_localPhotos.length >= 9) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.maxPhotosAllowed),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addPhoto),
        content: Text(l10n.howToAddPhoto),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.camera),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: Text(l10n.gallery),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (option == null) return;

    try {
      File? imageFile;
      if (option == 'camera') {
        imageFile = await _mediaService.takePhoto();
      } else {
        imageFile = await _mediaService.pickImageFromGallery();
      }

      if (imageFile != null && mounted) {
        // Guardar localmente la ruta del archivo (NO subir a Firebase aún)
        setState(() {
          _localPhotos.add(imageFile!.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.photoAddedNotSaved),
              backgroundColor: const Color(0xFF17A2B8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorAddingPhoto),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteInspectionPhoto(int index) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePhoto),
        content: Text(l10n.confirmDeletePhoto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Eliminar solo de la lista local (no de Firebase)
    setState(() {
      _localPhotos.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoDeleted),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _viewFullImage(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: _isNetworkUrl(imagePath)
                  ? Image.network(
                      imagePath,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            l10n.statusGood,
            const Color(0xFF22C55E),
            Icons.check,
          ),
          _buildLegendItem(
            l10n.statusAttention,
            const Color(0xFFFBBF24),
            Icons.priority_high,
          ),
          _buildLegendItem(
            l10n.statusImmediate,
            const Color(0xFFEF4444),
            Icons.close,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionSection(
    String title,
    ChecklistCategory category1, [
    ChecklistCategory? category2,
  ]) {
    final items = _checklistItems.where((item) {
      return item.category == category1 ||
          (category2 != null && item.category == category2);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la sección
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF17A2B8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.checklist_rtl, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Items de la sección
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (context, index) {
              final item = items[index];
              final globalIndex = _checklistItems.indexOf(item);
              return _buildChecklistItem(item, globalIndex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    final hasPhotos = item.photos.isNotEmpty;

    // Debug: mostrar cantidad de fotos
    // Debug log removed for production

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Nombre del componente
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botones de estado
              Row(
                children: [
                  _buildStatusButton(
                    ChecklistStatus.ok,
                    item.status,
                    () => _updateItemStatus(index, ChecklistStatus.ok),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    ChecklistStatus.attention,
                    item.status,
                    () => _updateItemStatus(index, ChecklistStatus.attention),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    ChecklistStatus.urgent,
                    item.status,
                    () => _updateItemStatus(index, ChecklistStatus.urgent),
                  ),
                  const SizedBox(width: 8),
                  // Botón de cámara
                  _buildCameraButton(item, index),
                ],
              ),
            ],
          ),
          // Miniaturas de fotos si existen
          if (hasPhotos) ...[
            const SizedBox(height: 8),
            _buildItemPhotoThumbnails(item, index),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraButton(ChecklistItem item, int index) {
    final photoCount = item.photos.length;
    final canAddMore = photoCount < 9;

    return GestureDetector(
      onTap: canAddMore
          ? () => _addItemPhoto(index)
          : () => _showMaxPhotosMessage(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: canAddMore ? const Color(0xFF17A2B8) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          boxShadow: canAddMore
              ? [
                  BoxShadow(
                    color: const Color(0xFF17A2B8).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: canAddMore ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            if (photoCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$photoCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPhotoThumbnails(ChecklistItem item, int index) {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: item.photos.length,
        itemBuilder: (context, photoIndex) {
          final photoPath = item.photos[photoIndex];

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _viewItemPhotos(item, photoIndex),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageWidget(
                      photoPath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => _deleteItemPhoto(index, photoIndex),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMaxPhotosMessage() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.maxPhotosPerComponent),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addItemPhoto(int itemIndex) async {
    final l10n = AppLocalizations.of(context);

    if (_checklistItems[itemIndex].photos.length >= 9) {
      _showMaxPhotosMessage();
      return;
    }

    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_checklistItems[itemIndex].name),
        content: Text(l10n.howToAddPhoto),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: Text(l10n.camera),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: Text(l10n.gallery),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (option == null) return;

    try {
      File? imageFile;
      if (option == 'camera') {
        imageFile = await _mediaService.takePhoto();
      } else {
        imageFile = await _mediaService.pickImageFromGallery();
      }

      if (imageFile != null && mounted) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final photoUrl = userId != null
            ? await _firebaseService.uploadFile(
                imageFile,
                userId,
                'vehicles/${widget.vehicle.id}/checklist/${_checklistItems[itemIndex].id}',
              )
            : await _firebaseService.uploadFile(
                imageFile,
                '',
                'vehicles/${widget.vehicle.id}/checklist/${_checklistItems[itemIndex].id}',
              );

        final updatedPhotos = List<String>.from(
          _checklistItems[itemIndex].photos,
        )..add(photoUrl);

        // Actualizar el item con la nueva foto
        _checklistItems[itemIndex] = _checklistItems[itemIndex].copyWith(
          photos: updatedPhotos,
        );

        // Debug
        // Debug removed for production
        // Debug removed for production

        // Actualizar el vehículo con el checklist modificado
        final updatedMaintenance = widget.vehicle.maintenance.copyWith(
          checklist: _checklistItems,
        );

        final updatedVehicle = widget.vehicle.copyWith(
          maintenance: updatedMaintenance,
        );

        // Actualizar el vehículo en el padre
        widget.onUpdate(updatedVehicle);

        // Actualizar el estado local DESPUÉS de actualizar el padre
        if (mounted) {
          setState(() {
            // El estado ya fue actualizado arriba, esto solo fuerza el rebuild
          });
        }

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.photoAddedCount(updatedPhotos.length)),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteItemPhoto(int itemIndex, int photoIndex) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePhoto),
        content: Text(l10n.confirmDeletePhoto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final photoToDelete = _checklistItems[itemIndex].photos[photoIndex];

      await _firebaseService.deleteFile(photoToDelete);

      final updatedPhotos = List<String>.from(_checklistItems[itemIndex].photos)
        ..removeAt(photoIndex);

      if (mounted) {
        setState(() {
          _checklistItems[itemIndex] = _checklistItems[itemIndex].copyWith(
            photos: updatedPhotos,
          );
        });
      }

      final updatedMaintenance = widget.vehicle.maintenance.copyWith(
        checklist: _checklistItems,
      );

      widget.onUpdate(widget.vehicle.copyWith(maintenance: updatedMaintenance));

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.photoDeleted),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _viewItemPhotos(ChecklistItem item, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryViewer(
          photoUrls: item.photos,
          initialIndex: initialIndex,
          title: item.name,
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    ChecklistStatus status,
    ChecklistStatus currentStatus,
    VoidCallback onTap,
  ) {
    final isSelected = status == currentStatus;
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: color, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: isSelected ? Colors.white : color, size: 24),
      ),
    );
  }

  Color _getStatusColor(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ok:
        return const Color(0xFF22C55E);
      case ChecklistStatus.attention:
        return const Color(0xFFFBBF24);
      case ChecklistStatus.urgent:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ok:
        return Icons.check;
      case ChecklistStatus.attention:
        return Icons.priority_high;
      case ChecklistStatus.urgent:
        return Icons.close;
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Fila principal con 3 botones
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetChecklist,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  AppLocalizations.of(context).reset,
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Color(0xFF64748B)),
                  foregroundColor: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saveInspectionToHistory,
                icon: const Icon(Icons.save, size: 18),
                label: Text(
                  AppLocalizations.of(context).save,
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF17A2B8),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareAsPdf,
                icon: const Icon(Icons.share, size: 18),
                label: Text(
                  AppLocalizations.of(context).share,
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF17A2B8),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Botón de historial
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _viewInspectionHistory,
            icon: const Icon(Icons.history),
            label: Text(
              AppLocalizations.of(context).viewInspectionHistoryCount(
                widget.vehicle.maintenance.inspectionHistory.length,
              ),
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF17A2B8)),
              foregroundColor: const Color(0xFF17A2B8),
            ),
          ),
        ),
      ],
    );
  }

  void _resetChecklist() {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetChecklist),
        content: Text(l10n.resetChecklistConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Restablecer todos los estados a OK y limpiar fotos y notas
                for (int i = 0; i < _checklistItems.length; i++) {
                  _checklistItems[i] = _checklistItems[i].copyWith(
                    status: ChecklistStatus.ok,
                    photos: [], // Limpiar las fotos de cada ítem
                    notes: '', // Limpiar las notas de cada ítem
                  );
                }
                // Limpiar todas las fotos locales
                _localPhotos.clear();
              });

              final updatedMaintenance = widget.vehicle.maintenance.copyWith(
                checklist: _checklistItems,
              );
              widget.onUpdate(
                widget.vehicle.copyWith(maintenance: updatedMaintenance),
              );

              Navigator.pop(dialogContext);
              messenger.clearSnackBars();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.checklistResetPhotosCleared),
                  backgroundColor: const Color(0xFF22C55E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF17A2B8),
            ),
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInspectionToHistory() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).savingInspection),
                ],
              ),
            ),
          ),
        ),
      );

      // Subir fotos locales a Firebase
      List<String> uploadedPhotoUrls = [];
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      for (String photoPath in _localPhotos) {
        // Si la ruta es local (archivo), subirla a Firebase
        if (!_isNetworkUrl(photoPath)) {
          final file = File(photoPath);
          if (file.existsSync()) {
            final photoUrl = await _firebaseService.uploadFile(
              file,
              userId,
              'vehicles/${widget.vehicle.id}/inspection',
            );
            uploadedPhotoUrls.add(photoUrl);
          }
        } else {
          // Si ya es una URL, mantenerla
          uploadedPhotoUrls.add(photoPath);
        }
      }

      // Crear un registro de inspección con las URLs de Firebase
      final inspection = InspectionRecord(
        id: const Uuid().v4(),
        date: DateTime.now(),
        checklist: List<ChecklistItem>.from(_checklistItems),
        inspectionPhotos: uploadedPhotoUrls,
        notes: '',
      );

      // Agregar al historial
      final history = List<InspectionRecord>.from(
        widget.vehicle.maintenance.inspectionHistory,
      )..add(inspection);

      final updatedMaintenance = widget.vehicle.maintenance.copyWith(
        inspectionHistory: history,
      );

      widget.onUpdate(widget.vehicle.copyWith(maintenance: updatedMaintenance));

      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      // Limpiar fotos locales después de guardar
      if (mounted) {
        setState(() {
          _localPhotos.clear();
        });
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inspectionSavedHistory(history.length)),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingInspection),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareAsPdf() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).generatingPdf),
                ],
              ),
            ),
          ),
        ),
      );

      // Crear inspección actual
      final inspection = InspectionRecord(
        id: const Uuid().v4(),
        date: DateTime.now(),
        checklist: List<ChecklistItem>.from(_checklistItems),
        inspectionPhotos: List<String>.from(_localPhotos),
        notes: '',
      );

      // Obtener localización antes del gap async
      final l10n = AppLocalizations.of(context);

      // Generar PDF
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateInspectionReport(
        widget.vehicle,
        inspection,
      );

      // Cerrar indicador de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Compartir PDF
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text:
            '${l10n.vehicleInspectionReport} - ${widget.vehicle.brand} ${widget.vehicle.model}',
      );
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneratingPdf),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewInspectionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _InspectionHistoryScreen(
          vehicle: widget.vehicle,
          onUpdate: widget.onUpdate,
        ),
      ),
    );
  }
}

// Widget para ver fotos en pantalla completa con carrusel
class _PhotoViewerScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final String title;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photoPath = widget.photos[index];
                final isNetworkUrl =
                    photoPath.startsWith('http://') ||
                    photoPath.startsWith('https://');

                return InteractiveViewer(
                  child: Center(
                    child: isNetworkUrl
                        ? Image.network(
                            photoPath,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error al cargar foto',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Image.file(
                            File(photoPath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error al cargar foto',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  color: Colors.white,
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentIndex + 1} / ${widget.photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _currentIndex < widget.photos.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  color: Colors.white,
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de historial de inspecciones
class _InspectionHistoryScreen extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onUpdate;

  const _InspectionHistoryScreen({
    required this.vehicle,
    required this.onUpdate,
  });

  @override
  State<_InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<_InspectionHistoryScreen> {
  late Vehicle _currentVehicle;

  @override
  void initState() {
    super.initState();
    _currentVehicle = widget.vehicle;
  }

  @override
  Widget build(BuildContext context) {
    final history = _currentVehicle.maintenance.inspectionHistory;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inspectionHistory),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noInspectionsSaved,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.useButtonToRecord,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final inspection = history[history.length - 1 - index];
                return _InspectionHistoryCard(
                  inspection: inspection,
                  vehicle: _currentVehicle,
                  onTap: () => _viewInspection(inspection),
                  onDelete: () => _deleteInspection(inspection),
                  onShare: () => _shareInspection(inspection),
                  onDownload: () => _downloadInspectionZip(inspection),
                );
              },
            ),
    );
  }

  void _viewInspection(InspectionRecord inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _InspectionViewerScreen(
          inspection: inspection,
          vehicle: _currentVehicle,
        ),
      ),
    );
  }

  Future<void> _deleteInspection(InspectionRecord inspection) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInspection),
        content: Text(l10n.confirmDeleteInspection),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final history = List<InspectionRecord>.from(
        _currentVehicle.maintenance.inspectionHistory,
      )..removeWhere((item) => item.id == inspection.id);

      final updatedMaintenance = _currentVehicle.maintenance.copyWith(
        inspectionHistory: history,
      );

      final updatedVehicle = _currentVehicle.copyWith(
        maintenance: updatedMaintenance,
      );

      // Actualizar estado local
      setState(() {
        _currentVehicle = updatedVehicle;
      });

      // Notificar al padre
      widget.onUpdate(updatedVehicle);

      // Mostrar confirmación solo una vez
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.inspectionDeleted),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareInspection(InspectionRecord inspection) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).generatingPdf),
                ],
              ),
            ),
          ),
        ),
      );

      // Obtener localización antes del gap async
      final l10n = AppLocalizations.of(context);

      // Generar PDF
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateInspectionReport(
        _currentVehicle,
        inspection,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text:
            '${l10n.vehicleInspectionReport} - ${_currentVehicle.brand} ${_currentVehicle.model}',
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadInspectionZip(InspectionRecord inspection) async {
    try {
      final l10n = AppLocalizations.of(context);

      // Mostrar indicador de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.generatingZip),
                ],
              ),
            ),
          ),
        ),
      );

      // Solicitar permisos en Android
      if (Platform.isAndroid) {
        final status = await NativeHelper.requestStoragePermission();
        if (!status.isGranted) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).storagePermissionDenied,
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // 1. Generar PDF del reporte
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateInspectionReport(
        _currentVehicle,
        inspection,
      );

      // 2. Crear archivo ZIP
      final archive = Archive();
      final storage = FirebaseStorage.instance;

      // Agregar PDF al ZIP
      final pdfBytes = await pdfFile.readAsBytes();
      archive.addFile(
        ArchiveFile('Reporte_Inspeccion.pdf', pdfBytes.length, pdfBytes),
      );

      // 3. Descargar y agregar fotos al ZIP
      int photoIndex = 1;
      for (String photoUrl in inspection.inspectionPhotos) {
        try {
          debugPrint('📸 Descargando foto inspección $photoIndex: $photoUrl');

          // Usar Firebase Storage para descargar
          final ref = storage.refFromURL(photoUrl);
          final data = await ref.getData();

          if (data != null) {
            // Obtener extensión del nombre del archivo
            String extension = 'jpg';
            try {
              final fileName = ref.name;
              if (fileName.contains('.')) {
                extension = fileName.split('.').last.toLowerCase();
              }
            } catch (e) {
              debugPrint('⚠️ Error al obtener extensión: $e');
            }

            archive.addFile(
              ArchiveFile('Foto_$photoIndex.$extension', data.length, data),
            );
            debugPrint('✅ Foto inspección $photoIndex agregada al ZIP');
            photoIndex++;
          }
        } catch (e) {
          debugPrint('❌ Error al descargar foto inspección $photoIndex: $e');
        }
      }

      // 4. Descargar y agregar fotos de componentes del checklist
      for (var item in inspection.checklist) {
        if (item.photos.isNotEmpty) {
          int componentPhotoIndex = 1;
          final componentName = item.name.replaceAll(
            RegExp(r'[^a-zA-Z0-9]'),
            '_',
          );
          for (String photoUrl in item.photos) {
            try {
              debugPrint(
                '📸 Descargando foto componente ${item.name} $componentPhotoIndex: $photoUrl',
              );

              // Usar Firebase Storage para descargar
              final ref = storage.refFromURL(photoUrl);
              final data = await ref.getData();

              if (data != null) {
                // Obtener extensión del nombre del archivo
                String extension = 'jpg';
                try {
                  final fileName = ref.name;
                  if (fileName.contains('.')) {
                    extension = fileName.split('.').last.toLowerCase();
                  }
                } catch (e) {
                  debugPrint('⚠️ Error al obtener extensión: $e');
                }

                archive.addFile(
                  ArchiveFile(
                    'Componente_${componentName}_$componentPhotoIndex.$extension',
                    data.length,
                    data,
                  ),
                );
                debugPrint('✅ Foto componente agregada al ZIP');
                componentPhotoIndex++;
              }
            } catch (e) {
              debugPrint('❌ Error al descargar foto componente: $e');
            }
          }
        }
      }

      // 5. Codificar ZIP
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      if (zipData == null || zipData.isEmpty) {
        throw Exception('Error al codificar el archivo ZIP');
      }

      debugPrint('📦 ZIP de inspección codificado: ${zipData.length} bytes');

      // 6. Guardar ZIP en descargas
      final directory = await _getDownloadsDirectory();

      final dateFormat = DateFormat('dd-MM-yyyy_HH-mm');
      final fileName = 'Inspeccion_${dateFormat.format(inspection.date)}.zip';
      final filePath = '${directory.path}/$fileName';

      debugPrint('📦 Guardando ZIP de inspección en: $filePath');
      final file = File(filePath);
      await file.writeAsBytes(zipData);

      // Verificar que el archivo es un ZIP válido
      final savedBytes = await file.readAsBytes();
      final isValidZip =
          savedBytes.length >= 4 &&
          savedBytes[0] == 0x50 &&
          savedBytes[1] == 0x4B;
      final fileSize = await file.length();
      debugPrint(
        '✅ ZIP guardado: ${await file.exists()} - Tamaño: $fileSize bytes - Es ZIP válido: $isValidZip',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportDownloaded('Download/Reportes')),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorDownloadingReport}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// Tarjeta de inspección en el historial
class _InspectionHistoryCard extends StatelessWidget {
  final InspectionRecord inspection;
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  const _InspectionHistoryCard({
    required this.inspection,
    required this.vehicle,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final l10n = AppLocalizations.of(context);
    final okCount = inspection.checklist
        .where((item) => item.status == ChecklistStatus.ok)
        .length;
    final attentionCount = inspection.checklist
        .where((item) => item.status == ChecklistStatus.attention)
        .length;
    final urgentCount = inspection.checklist
        .where((item) => item.status == ChecklistStatus.urgent)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17A2B8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF17A2B8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(inspection.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          l10n.componentsReviewed(inspection.checklist.length),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: l10n.delete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Resumen de estados
              Row(
                children: [
                  _buildStatusChip(
                    Icons.check,
                    okCount,
                    const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    Icons.priority_high,
                    attentionCount,
                    const Color(0xFFFBBF24),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    Icons.close,
                    urgentCount,
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
              if (inspection.inspectionPhotos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.photo_library,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${inspection.inspectionPhotos.length} foto${inspection.inspectionPhotos.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(l10n.sharePdf),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17A2B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 18),
                      label: Text(l10n.downloadReportZip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de visualización de inspección guardada (solo lectura)
class _InspectionViewerScreen extends StatefulWidget {
  final InspectionRecord inspection;
  final Vehicle vehicle;

  const _InspectionViewerScreen({
    required this.inspection,
    required this.vehicle,
  });

  @override
  State<_InspectionViewerScreen> createState() =>
      _InspectionViewerScreenState();
}

class _InspectionViewerScreenState extends State<_InspectionViewerScreen> {
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inspectionSaved),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Banner informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).inspectionFromDate(
                          dateFormat.format(widget.inspection.date),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).readOnlyCannotModify,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de items del checklist
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Fotos de inspección si existen
                if (widget.inspection.inspectionPhotos.isNotEmpty) ...[
                  _buildPhotosSection(context),
                  const SizedBox(height: 24),
                ],
                // Checklist items
                ...widget.inspection.checklist.asMap().entries.map((entry) {
                  return _buildChecklistItem(context, entry.value, entry.key);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPhoto(String photoUrl) async {
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).downloadingPhoto),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

      // Solicitar permisos de almacenamiento
      if (Platform.isAndroid) {
        final status = await NativeHelper.requestStoragePermission();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context).storagePermissionDenied,
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Descargar la imagen
      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        // Obtener directorio de descargas
        final directory = await _getDownloadsDirectory();

        // Generar nombre único para la foto
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'inspeccion_${widget.vehicle.plate}_$timestamp.jpg';
        final filePath = '${directory.path}/$fileName';

        // Guardar la imagen
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Foto guardada en: Download/Reportes'),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Error al descargar la foto');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDownloading),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPhotosSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inspectionPhotos,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.inspection.inspectionPhotos.length,
            itemBuilder: (context, index) {
              final photoUrl = widget.inspection.inspectionPhotos[index];
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoGalleryViewer(
                            initialIndex: index,
                            photoUrls: widget.inspection.inspectionPhotos,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),
                  // Botón de descarga
                  Positioned(
                    bottom: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _downloadPhoto(photoUrl),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF17A2B8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    ChecklistItem item,
    int index,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (item.status) {
      case ChecklistStatus.ok:
        statusColor = const Color(0xFF22C55E);
        statusIcon = Icons.check_circle;
        statusText = 'OK';
        break;
      case ChecklistStatus.attention:
        statusColor = const Color(0xFFFBBF24);
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'ATENCIÓN';
        break;
      case ChecklistStatus.urgent:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error;
        statusText = 'URGENTE';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Notas:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.notes,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
            if (item.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.photos.length,
                  itemBuilder: (context, photoIndex) {
                    final photoUrl = item.photos[photoIndex];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoGalleryViewer(
                              initialIndex: photoIndex,
                              photoUrls: item.photos,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                ),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
