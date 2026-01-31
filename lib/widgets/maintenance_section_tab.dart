import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';
import '../models/maintenance_item.dart';
import '../models/maintenance_section_data.dart';
import '../services/media_service.dart';
import '../services/firebase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'vehicle_inspection_checklist.dart';
import 'photo_gallery_viewer.dart';

class MaintenanceSectionTab extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onUpdate;

  const MaintenanceSectionTab({
    super.key,
    required this.vehicle,
    required this.onUpdate,
  });

  @override
  State<MaintenanceSectionTab> createState() => _MaintenanceSectionTabState();
}

class _MaintenanceSectionTabState extends State<MaintenanceSectionTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E40AF),
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: const Color(0xFF1E40AF),
            tabs: const [
              Tab(text: 'Checklist de Inspección'),
              Tab(text: 'Mantenimiento Detallado'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ChecklistView(
                vehicle: widget.vehicle,
                onUpdate: widget.onUpdate,
              ),
              _DetailedMaintenanceView(
                vehicle: widget.vehicle,
                onUpdate: widget.onUpdate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Vista del Checklist de Inspección
class _ChecklistView extends StatelessWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onUpdate;

  const _ChecklistView({required this.vehicle, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return VehicleInspectionChecklist(vehicle: vehicle, onUpdate: onUpdate);
  }
}

// Vista de Mantenimiento Detallado
class _DetailedMaintenanceView extends StatelessWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onUpdate;

  const _DetailedMaintenanceView({
    required this.vehicle,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con descripción
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8FAFC),
          child: const Text(
            'Gestiona el mantenimiento detallado por\nsección. Incluye fotos, fechas y seguimiento de kilometraje',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        // Lista de secciones
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicle.maintenance.sections.length,
            itemBuilder: (context, index) {
              final section = vehicle.maintenance.sections[index];
              return _MaintenanceSectionCard(
                section: section,
                vehicleId: vehicle.id,
                onUpdate: (updatedSection) {
                  final sections = List<MaintenanceSectionData>.from(
                    vehicle.maintenance.sections,
                  );
                  sections[index] = updatedSection;
                  final updatedMaintenance = vehicle.maintenance.copyWith(
                    sections: sections,
                  );
                  onUpdate(vehicle.copyWith(maintenance: updatedMaintenance));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Tarjeta de cada sección de mantenimiento
class _MaintenanceSectionCard extends StatelessWidget {
  final dynamic section; // MaintenanceSectionData
  final String vehicleId;
  final Function(dynamic) onUpdate;

  const _MaintenanceSectionCard({
    required this.section,
    required this.vehicleId,
    required this.onUpdate,
  });

  IconData _getSectionIcon(String sectionId) {
    switch (sectionId) {
      case 'motor':
        return Icons.settings;
      case 'direccion':
        return Icons.turn_right;
      case 'pintura':
        return Icons.format_paint;
      case 'radiador':
        return Icons.thermostat;
      case 'suspension':
        return Icons.vertical_align_center;
      case 'ac':
        return Icons.ac_unit;
      case 'electrico':
        return Icons.bolt;
      case 'frenos':
        return Icons.do_not_disturb_on;
      case 'transmision':
        return Icons.sync;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = section.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            _getSectionIcon(section.id),
            color: const Color(0xFF1E40AF),
          ),
          title: Text(
            section.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Text(
            '$itemCount ${itemCount == 1 ? 'registro' : 'registros'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          children: [
            if (itemCount > 0)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final item = section.items[index];
                  return _MaintenanceItemTile(
                    item: item,
                    onTap: () => _editItem(context, item),
                    onDelete: () => _deleteItem(context, item),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: OutlinedButton.icon(
                  onPressed: () => _addNewItem(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Agregar Registro',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E40AF),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF1E40AF), width: 2),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MaintenanceFormScreen(
          sectionName: section.name,
          vehicleId: vehicleId,
          onSave: (item) {
            final items = List<MaintenanceItem>.from(section.items)..add(item);
            final updatedSection = section.copyWith(items: items);
            onUpdate(updatedSection);
          },
        ),
      ),
    );
  }

  void _editItem(BuildContext context, MaintenanceItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MaintenanceFormScreen(
          sectionName: section.name,
          vehicleId: vehicleId,
          item: item,
          onSave: (updatedItem) {
            final items = List<MaintenanceItem>.from(section.items);
            final index = items.indexWhere((i) => i.id == item.id);
            if (index != -1) {
              items[index] = updatedItem;
              final updatedSection = section.copyWith(items: items);
              onUpdate(updatedSection);
            }
          },
        ),
      ),
    );
  }

  void _deleteItem(BuildContext context, MaintenanceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Estás seguro de eliminar este registro?'),
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

    if (confirmed == true && context.mounted) {
      final items = List<MaintenanceItem>.from(section.items)
        ..removeWhere((i) => i.id == item.id);
      final updatedSection = section.copyWith(items: items);
      onUpdate(updatedSection);
    }
  }
}

// Widget para mostrar cada item de mantenimiento
class _MaintenanceItemTile extends StatelessWidget {
  final MaintenanceItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MaintenanceItemTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return ListTile(
      leading: const Icon(Icons.build_circle, color: Color(0xFF06B6D4)),
      title: Text(item.what),
      subtitle: Text(
        'Fecha: ${dateFormat.format(item.date)} | KM: ${item.currentKm}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

// Pantalla de formulario para agregar/editar mantenimiento
class _MaintenanceFormScreen extends StatefulWidget {
  final String sectionName;
  final String vehicleId;
  final MaintenanceItem? item;
  final Function(MaintenanceItem) onSave;

  const _MaintenanceFormScreen({
    required this.sectionName,
    required this.vehicleId,
    this.item,
    required this.onSave,
  });

  @override
  State<_MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<_MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MediaService _mediaService = MediaService();
  final FirebaseService _firebaseService = FirebaseService();

  late TextEditingController _whatController;
  late TextEditingController _currentKmController;
  late TextEditingController _nextChangeKmController;
  late DateTime _selectedDate;

  List<String> _problemPhotos = [];
  List<String> _oldPartsPhotos = [];
  List<String> _newPartsPhotos = [];
  List<String> _afterPhotos = [];

  @override
  void initState() {
    super.initState();
    _whatController = TextEditingController(text: widget.item?.what ?? '');
    _currentKmController = TextEditingController(
      text: widget.item?.currentKm.toString() ?? '0',
    );
    _nextChangeKmController = TextEditingController(
      text: widget.item?.nextChangeKm.toString() ?? '0',
    );
    _selectedDate = widget.item?.date ?? DateTime.now();

    if (widget.item != null) {
      _problemPhotos = List<String>.from(widget.item!.problemPhotos);
      _oldPartsPhotos = List<String>.from(widget.item!.oldPartsPhotos);
      _newPartsPhotos = List<String>.from(widget.item!.newPartsPhotos);
      _afterPhotos = List<String>.from(widget.item!.afterPhotos);
    }
  }

  @override
  void dispose() {
    _whatController.dispose();
    _currentKmController.dispose();
    _nextChangeKmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'Agregar Registro de Mantenimiento'
              : 'Editar Registro',
        ),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.sectionName} - Motor',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 20),
              // ¿Qué problema tiene o qué trabajo se realizó?
              TextFormField(
                controller: _whatController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '¿Qué problema tiene o qué trabajo se realizó?',
                  hintText: 'Describe el problema o el trabajo realizado...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Secciones de fotos
              _buildPhotoSection('Fotos del Problema', _problemPhotos),
              const SizedBox(height: 16),
              _buildPhotoSection('Fotos de Piezas Viejas', _oldPartsPhotos),
              const SizedBox(height: 16),
              _buildPhotoSection('Fotos de Piezas Nuevas', _newPartsPhotos),
              const SizedBox(height: 16),
              _buildPhotoSection('Fotos del Resultado Final', _afterPhotos),
              const SizedBox(height: 20),
              // Kilometraje Actual
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentKmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Kilometraje Actual (km)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nextChangeKmController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Próximo Cambio (km)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Fecha del Servicio
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha del Servicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              const SizedBox(height: 30),
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveMaintenanceItem,
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text(
                    'Guardar Registro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shadowColor: const Color(0xFF06B6D4).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection(String title, List<String> photos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Fotos existentes
              if (photos.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PhotoGalleryViewer(
                                photoUrls: photos,
                                initialIndex: index,
                                title: title,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(photos[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Align(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 32,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // Botón para agregar foto
              InkWell(
                onTap: () => _addPhoto(photos),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1E40AF)),
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addPhoto(List<String> photoList) async {
    final photo = await _mediaService.takePhoto();
    if (photo != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final url = await _firebaseService.uploadImage(
          photo,
          widget.vehicleId,
          userId,
          'mantenimiento',
        );

        setState(() {
          photoList.add(url);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir foto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveMaintenanceItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final item = MaintenanceItem(
      id: widget.item?.id ?? const Uuid().v4(),
      what: _whatController.text.trim(),
      problemPhotos: _problemPhotos,
      oldPartsPhotos: _oldPartsPhotos,
      newPartsPhotos: _newPartsPhotos,
      afterPhotos: _afterPhotos,
      currentKm: int.tryParse(_currentKmController.text) ?? 0,
      nextChangeKm: int.tryParse(_nextChangeKmController.text) ?? 0,
      date: _selectedDate,
    );

    widget.onSave(item);
    Navigator.pop(context);
  }
}
