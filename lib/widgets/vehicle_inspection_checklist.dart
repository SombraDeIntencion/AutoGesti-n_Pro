import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:autogestion_max/models/checklist_item.dart';
import 'package:autogestion_max/models/vehicle.dart';
import 'package:autogestion_max/models/inspection_record.dart';
import 'package:autogestion_max/services/media_service.dart';
import 'package:autogestion_max/services/firebase_service.dart';
import 'package:autogestion_max/services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:autogestion_max/widgets/photo_gallery_viewer.dart';

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
  final MediaService _mediaService = MediaService();
  final FirebaseService _firebaseService = FirebaseService();

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
    _initializeChecklist();
  }

  @override
  void didUpdateWidget(VehicleInspectionChecklist oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el vehículo cambió externamente (no por nuestra propia actualización)
    // actualizar el checklist, pero solo si el ID del vehículo cambió o
    // si la longitud del checklist cambió significativamente
    if (oldWidget.vehicle.id != widget.vehicle.id ||
        (oldWidget.vehicle.maintenance.checklist.length !=
            widget.vehicle.maintenance.checklist.length)) {
      _initializeChecklist();
    } else if (oldWidget.vehicle != widget.vehicle) {
      // Si solo cambió el contenido, actualizar desde el vehículo
      _checklistItems = List<ChecklistItem>.from(
        widget.vehicle.maintenance.checklist,
      );
    }
  }

  void _initializeChecklist() {
    // Si el vehículo ya tiene items, usarlos; si no, crear la lista por defecto
    if (widget.vehicle.maintenance.checklist.isNotEmpty) {
      _checklistItems = List<ChecklistItem>.from(
        widget.vehicle.maintenance.checklist,
      );
    } else {
      _checklistItems = _createDefaultChecklist();
    }
  }

  List<ChecklistItem> _createDefaultChecklist() {
    return [
      // INTERIOR/EXTERIOR
      ChecklistItem(
        id: 'int_ext_1',
        name: 'Cristales / Vidrios',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_2',
        name: 'Espejos',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_3',
        name: 'Luces Exteriores',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_4',
        name: 'Carrocería / Pintura',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_5',
        name: 'Chasis / Marco',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_6',
        name: 'Puertas / Cerraduras',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_7',
        name: 'Parabrisas',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_8',
        name: 'Limpiadores',
        category: ChecklistCategory.exterior,
      ),
      ChecklistItem(
        id: 'int_ext_9',
        name: 'Bocina / Claxon',
        category: ChecklistCategory.interior,
      ),
      ChecklistItem(
        id: 'int_ext_10',
        name: 'Cinturones de Seguridad',
        category: ChecklistCategory.interior,
      ),
      ChecklistItem(
        id: 'int_ext_11',
        name: 'Tapicería / Asientos',
        category: ChecklistCategory.interior,
      ),

      // BAJO EL CAPÓ
      ChecklistItem(
        id: 'hood_1',
        name: 'Aceite del Motor',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_2',
        name: 'Filtro de Aceite',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_3',
        name: 'Líquido de Frenos',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_4',
        name: 'Líquido del Radiador',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_5',
        name: 'Correa(s) / Fajas',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_6',
        name: 'Batería',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_7',
        name: 'Filtro de Aire',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_8',
        name: 'Filtro de Combustible',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_9',
        name: 'Bujías / Cables',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_10',
        name: 'Mangueras',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_11',
        name: 'Carga de Batería',
        category: ChecklistCategory.underhood,
      ),
      ChecklistItem(
        id: 'hood_12',
        name: 'Condición Batería',
        category: ChecklistCategory.underhood,
      ),

      // NEUMÁTICOS
      ChecklistItem(
        id: 'tire_1',
        name: 'Presión Delanteros',
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_2',
        name: 'Presión Traseros',
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_3',
        name: 'Desgaste Delanteros',
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_4',
        name: 'Desgaste Traseros',
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_5',
        name: 'Balanceo',
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_6',
        name: 'Alineación',
        category: ChecklistCategory.tires,
      ),
      ChecklistItem(
        id: 'tire_7',
        name: 'Rotación',
        category: ChecklistCategory.tires,
      ),
    ];
  }

  void _updateItemStatus(int index, ChecklistStatus newStatus) {
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
            'INTERIOR/EXTERIOR',
            ChecklistCategory.exterior,
            ChecklistCategory.interior,
          ),
          const SizedBox(height: 16),
          _buildInspectionSection('BAJO EL CAPÓ', ChecklistCategory.underhood),
          const SizedBox(height: 16),
          _buildInspectionSection('NEUMÁTICOS', ChecklistCategory.tires),
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
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_outlined, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            'Reporte de Inspección Vehicular',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Haz clic en los cuadros de color para cambiar\nel estado de cada componente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDiagram() {
    final inspectionPhotos = widget.vehicle.maintenance.inspectionPhotos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Carrusel de fotos o placeholder
          if (inspectionPhotos.isEmpty)
            _buildEmptyPhotosPlaceholder()
          else
            _buildPhotosCarousel(inspectionPhotos),
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
              color: const Color(0xFF1E40AF).withOpacity(0.3),
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
              'Año: ${widget.vehicle.year}',
              style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toca el botón para agregar fotos',
              style: TextStyle(
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
                                  color: Colors.black.withOpacity(0.2),
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
                              color: Colors.black.withOpacity(0.6),
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
            'Desliza para ver más fotos',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF64748B).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    final inspectionPhotos = widget.vehicle.maintenance.inspectionPhotos;
    final canAddMore = inspectionPhotos.length < 9;

    return ElevatedButton.icon(
      onPressed: canAddMore ? _addInspectionPhoto : null,
      icon: const Icon(Icons.add_a_photo, size: 20),
      label: Text(
        canAddMore
            ? 'Agregar Foto (${inspectionPhotos.length}/9)'
            : 'Máximo de fotos alcanzado',
        style: const TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: canAddMore ? const Color(0xFF1E40AF) : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _addInspectionPhoto() async {
    if (widget.vehicle.maintenance.inspectionPhotos.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Máximo 9 fotos permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Foto'),
        content: const Text('¿Cómo deseas agregar la foto?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final photoUrl = await _firebaseService.uploadFile(
          imageFile,
          userId,
          'vehicles/${widget.vehicle.id}/inspection',
        );

        final updatedPhotos = List<String>.from(
          widget.vehicle.maintenance.inspectionPhotos,
        )..add(photoUrl);

        final updatedMaintenance = widget.vehicle.maintenance.copyWith(
          inspectionPhotos: updatedPhotos,
        );

        widget.onUpdate(
          widget.vehicle.copyWith(maintenance: updatedMaintenance),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Foto agregada'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteInspectionPhoto(int index) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: const Text('¿Estás seguro de eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final photos = widget.vehicle.maintenance.inspectionPhotos;
      final photoToDelete = photos[index];

      // Eliminar del storage
      await _firebaseService.deleteFile(photoToDelete);

      // Actualizar lista
      final updatedPhotos = List<String>.from(photos)..removeAt(index);

      final updatedMaintenance = widget.vehicle.maintenance.copyWith(
        inspectionPhotos: updatedPhotos,
      );

      widget.onUpdate(widget.vehicle.copyWith(maintenance: updatedMaintenance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Foto eliminada'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            'Revisado y\nOK',
            const Color(0xFF22C55E),
            Icons.check,
          ),
          _buildLegendItem(
            'Requiere\nAtención',
            const Color(0xFFFBBF24),
            Icons.priority_high,
          ),
          _buildLegendItem(
            'Atención\nInmediata',
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
                color: color.withOpacity(0.3),
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
            color: Colors.black.withOpacity(0.05),
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
              color: Color(0xFF1E40AF),
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
    final canAddMore = photoCount < 5;

    return GestureDetector(
      onTap: canAddMore
          ? () => _addItemPhoto(index)
          : () => _showMaxPhotosMessage(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: canAddMore ? const Color(0xFF06B6D4) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
          boxShadow: canAddMore
              ? [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.3),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Máximo 5 fotos por componente'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addItemPhoto(int itemIndex) async {
    if (_checklistItems[itemIndex].photos.length >= 5) {
      _showMaxPhotosMessage();
      return;
    }

    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_checklistItems[itemIndex].name),
        content: const Text('¿Cómo deseas agregar la foto?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'camera'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'gallery'),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final photoUrl = await _firebaseService.uploadFile(
          imageFile,
          userId,
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
        setState(() {
          // El estado ya fue actualizado arriba, esto solo fuerza el rebuild
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Foto agregada (${updatedPhotos.length}/5)'),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteItemPhoto(int itemIndex, int photoIndex) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: const Text('¿Estás seguro de eliminar esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
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

      setState(() {
        _checklistItems[itemIndex] = _checklistItems[itemIndex].copyWith(
          photos: updatedPhotos,
        );
      });

      final updatedMaintenance = widget.vehicle.maintenance.copyWith(
        checklist: _checklistItems,
      );

      widget.onUpdate(widget.vehicle.copyWith(maintenance: updatedMaintenance));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Foto eliminada'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                    color: color.withOpacity(0.3),
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
                label: const Text('Reiniciar', style: TextStyle(fontSize: 12)),
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
                label: const Text('Guardar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareAsPdf,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartir', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF06B6D4),
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
              'Ver Historial de Inspecciones (${widget.vehicle.maintenance.inspectionHistory.length})',
              style: const TextStyle(fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF1E40AF)),
              foregroundColor: const Color(0xFF1E40AF),
            ),
          ),
        ),
      ],
    );
  }

  void _resetChecklist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar Checklist'),
        content: const Text(
          '¿Estás seguro de que deseas reiniciar todos los estados a "OK"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (int i = 0; i < _checklistItems.length; i++) {
                  _checklistItems[i] = _checklistItems[i].copyWith(
                    status: ChecklistStatus.ok,
                  );
                }
              });

              final updatedMaintenance = widget.vehicle.maintenance.copyWith(
                checklist: _checklistItems,
              );
              widget.onUpdate(
                widget.vehicle.copyWith(maintenance: updatedMaintenance),
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checklist reiniciado'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
            ),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInspectionToHistory() async {
    // Crear un registro de inspección
    final inspection = InspectionRecord(
      id: const Uuid().v4(),
      date: DateTime.now(),
      checklist: List<ChecklistItem>.from(_checklistItems),
      inspectionPhotos: List<String>.from(
        widget.vehicle.maintenance.inspectionPhotos,
      ),
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Inspección guardada en historial (${history.length} registros)',
          ),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _shareAsPdf() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
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
        inspectionPhotos: List<String>.from(
          widget.vehicle.maintenance.inspectionPhotos,
        ),
        notes: '',
      );

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
            'Reporte de Inspección - ${widget.vehicle.brand} ${widget.vehicle.model}',
      );
    } catch (e) {
      // Cerrar indicador de carga si está abierto
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
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
class _InspectionHistoryScreen extends StatelessWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onUpdate;

  const _InspectionHistoryScreen({
    required this.vehicle,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final history = vehicle.maintenance.inspectionHistory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Inspecciones'),
        backgroundColor: const Color(0xFF1E40AF),
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
                    'No hay inspecciones guardadas',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa el botón "Guardar" para\nregistrar inspecciones',
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
                  vehicle: vehicle,
                  onDelete: () => _deleteInspection(context, inspection),
                  onShare: () => _shareInspection(context, inspection),
                );
              },
            ),
    );
  }

  Future<void> _deleteInspection(
    BuildContext context,
    InspectionRecord inspection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Inspección'),
        content: const Text(
          '¿Estás seguro de eliminar esta inspección del historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final history = List<InspectionRecord>.from(
        vehicle.maintenance.inspectionHistory,
      )..removeWhere((item) => item.id == inspection.id);

      final updatedMaintenance = vehicle.maintenance.copyWith(
        inspectionHistory: history,
      );

      onUpdate(vehicle.copyWith(maintenance: updatedMaintenance));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Inspección eliminada'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  Future<void> _shareInspection(
    BuildContext context,
    InspectionRecord inspection,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generando PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final pdfService = PdfService();
      final pdfFile = await pdfService.generateInspectionReport(
        vehicle,
        inspection,
      );

      if (context.mounted) {
        Navigator.pop(context);
      }

      await Share.shareXFiles([
        XFile(pdfFile.path),
      ], text: 'Reporte de Inspección - ${vehicle.brand} ${vehicle.model}');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Tarjeta de inspección en el historial
class _InspectionHistoryCard extends StatelessWidget {
  final InspectionRecord inspection;
  final Vehicle vehicle;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _InspectionHistoryCard({
    required this.inspection,
    required this.vehicle,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
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
                    color: const Color(0xFF1E40AF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF1E40AF),
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
                        '${inspection.checklist.length} componentes revisados',
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
                  tooltip: 'Eliminar',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Resumen de estados
            Row(
              children: [
                _buildStatusChip(Icons.check, okCount, const Color(0xFF22C55E)),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartir PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
