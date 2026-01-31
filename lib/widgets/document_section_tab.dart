import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/document_section.dart';
import '../services/media_service.dart';
import '../services/firebase_service.dart';
import '../services/share_service.dart';

class DocumentSectionTab extends StatefulWidget {
  final String title;
  final DocumentSection section;
  final String vehicleId;
  final String sectionName;
  final Function(DocumentSection) onUpdate;

  const DocumentSectionTab({
    super.key,
    required this.title,
    required this.section,
    required this.vehicleId,
    required this.sectionName,
    required this.onUpdate,
  });

  @override
  State<DocumentSectionTab> createState() => _DocumentSectionTabState();
}

class _DocumentSectionTabState extends State<DocumentSectionTab> {
  final MediaService _mediaService = MediaService();
  final FirebaseService _firebaseService = FirebaseService();
  final ShareService _shareService = ShareService();
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.section.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de vigencia
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion')
            _buildExpirationBanner(),
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion')
            const SizedBox(height: 24),
          // Fecha de Vencimiento
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion')
            _buildSection(
              title: 'Fecha de Vencimiento',
              icon: Icons.calendar_today,
              child: _buildExpirationDatePicker(),
            ),
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion')
            const SizedBox(height: 24),
          // Fotos
          _buildSection(
            title: 'Fotos',
            icon: Icons.photo_camera,
            child: Column(
              children: [
                _buildPhotoGrid(),
                const SizedBox(height: 12),
                _buildAddPhotoButton(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Documentos PDF
          _buildSection(
            title: 'Documentos PDF',
            icon: Icons.picture_as_pdf,
            child: Column(
              children: [
                _buildPdfList(),
                const SizedBox(height: 12),
                _buildAddPdfButton(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Notas
          _buildSection(
            title: 'Notas',
            icon: Icons.note,
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Escribe notas sobre este documento...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveNotes,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text(
                      'Guardar Notas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
          const SizedBox(height: 24),
          // Compartir Documentos
          _buildSection(
            title: 'Compartir Documentos',
            icon: Icons.share,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareViaWhatsApp,
                    icon: const Icon(Icons.message, size: 20),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: const Color(0xFF25D366).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareViaEmail,
                    icon: const Icon(Icons.email, size: 20),
                    label: const Text(
                      'Correo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: const Color(0xFF1E40AF).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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

  Widget _buildExpirationBanner() {
    if (widget.section.expirationDate == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Establece la fecha de vencimiento para recibir notificaciones',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String message;

    if (widget.section.isExpired) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade900;
      icon = Icons.error;
      message =
          '¡VENCIDO! Este documento expiró hace ${widget.section.daysUntilExpiration.abs()} días';
    } else if (widget.section.isExpiringSoon) {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      icon = Icons.warning;
      message =
          '⚠️ Vence en ${widget.section.daysUntilExpiration} días - ¡Renueva pronto!';
    } else {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      message =
          '✓ Vigente - ${widget.section.daysUntilExpiration} días restantes';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationDatePicker() {
    return InkWell(
      onTap: _selectExpirationDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: Color(0xFF1E40AF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fecha de vencimiento',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.section.expirationDate != null
                        ? '${widget.section.expirationDate!.day.toString().padLeft(2, '0')}/${widget.section.expirationDate!.month.toString().padLeft(2, '0')}/${widget.section.expirationDate!.year}'
                        : 'Seleccionar fecha',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.section.expirationDate ?? DateTime.now(),
      firstDate: DateTime(
        2020,
      ), // Permite fechas desde 2020 para poder probar fechas vencidas
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 años
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final updatedSection = widget.section.copyWith(expirationDate: picked);
      widget.onUpdate(updatedSection);

      if (mounted) {
        // Verificar si la fecha seleccionada está vencida
        final isExpired = picked.isBefore(DateTime.now());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isExpired ? Icons.error : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpired
                        ? '⚠️ Fecha vencida guardada - El documento está VENCIDO'
                        : 'Fecha de vencimiento guardada',
                  ),
                ),
              ],
            ),
            backgroundColor: isExpired ? Colors.red.shade700 : Colors.green,
            duration: Duration(seconds: isExpired ? 4 : 2),
          ),
        );
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1E40AF)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildPhotoGrid() {
    if (widget.section.photos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No hay fotos',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.section.photos.length,
      itemBuilder: (context, index) {
        final photoUrl = widget.section.photos[index];
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(photoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddPhotoButton() {
    return SizedBox(
      width: double.infinity,
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
          onPressed: _addPhoto,
          icon: const Icon(Icons.add_a_photo, size: 20),
          label: const Text(
            'Tomar Foto',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E40AF),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF1E40AF), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfList() {
    if (widget.section.pdfs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No hay documentos PDF',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.section.pdfs.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text('Documento ${index + 1}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePdf(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddPdfButton() {
    return SizedBox(
      width: double.infinity,
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
          onPressed: _addPdf,
          icon: const Icon(Icons.upload_file, size: 20),
          label: const Text(
            'Agregar PDF',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E40AF),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF1E40AF), width: 2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final photo = await _mediaService.takePhoto();
    if (photo != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final url = await _firebaseService.uploadImage(
          photo,
          widget.vehicleId,
          userId,
          widget.sectionName,
        );

        final updatedSection = widget.section.copyWith(
          photos: [...widget.section.photos, url],
        );

        widget.onUpdate(updatedSection);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto agregada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Future<void> _deletePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de eliminar esta foto?'),
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
      try {
        await _firebaseService.deleteFile(widget.section.photos[index]);

        final photos = List<String>.from(widget.section.photos);
        photos.removeAt(index);

        final updatedSection = widget.section.copyWith(photos: photos);
        widget.onUpdate(updatedSection);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar foto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addPdf() async {
    final pdf = await _mediaService.pickPdf();
    if (pdf != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final url = await _firebaseService.uploadPdf(
          pdf,
          widget.vehicleId,
          userId,
          widget.sectionName,
        );

        final updatedSection = widget.section.copyWith(
          pdfs: [...widget.section.pdfs, url],
        );

        widget.onUpdate(updatedSection);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF agregado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePdf(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar PDF'),
        content: const Text('¿Estás seguro de eliminar este documento?'),
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
      try {
        await _firebaseService.deleteFile(widget.section.pdfs[index]);

        final pdfs = List<String>.from(widget.section.pdfs);
        pdfs.removeAt(index);

        final updatedSection = widget.section.copyWith(pdfs: pdfs);
        widget.onUpdate(updatedSection);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _saveNotes() {
    final updatedSection = widget.section.copyWith(
      notes: _notesController.text.trim(),
    );
    widget.onUpdate(updatedSection);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notas guardadas correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    final selectedFiles = await _showFileSelectionDialog();

    if (selectedFiles == null || selectedFiles.isEmpty) {
      return;
    }

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparando archivos para compartir...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Color(0xFF06B6D4),
        ),
      );
    }

    try {
      final message =
          '${widget.title} del vehículo ${widget.vehicleId.substring(0, 8)}';

      if (selectedFiles.length == 1) {
        await _shareService.shareViaWhatsApp(selectedFiles.first, message);
      } else {
        await _shareService.shareMultipleFiles(selectedFiles, message: message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Compartiendo por WhatsApp...'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al compartir: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _shareViaEmail() async {
    final selectedFiles = await _showFileSelectionDialog();

    if (selectedFiles == null || selectedFiles.isEmpty) {
      return;
    }

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparando archivos para compartir...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Color(0xFF06B6D4),
        ),
      );
    }

    try {
      final subject =
          '${widget.title} - Vehículo ${widget.vehicleId.substring(0, 8)}';
      final body = 'Adjunto documentos de ${widget.title}';

      if (selectedFiles.length == 1) {
        await _shareService.shareViaEmail(
          selectedFiles.first,
          subject,
          body,
          '',
        );
      } else {
        await _shareService.shareMultipleFiles(
          selectedFiles,
          message: '$subject\n$body',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Compartiendo por correo...'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al compartir: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<List<String>?> _showFileSelectionDialog() async {
    final allFiles = [...widget.section.photos, ...widget.section.pdfs];

    if (allFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay documentos ni fotos para compartir'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    final fileSelection = List<bool>.filled(allFiles.length, false);

    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Seleccionar Archivos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allFiles.length,
                  itemBuilder: (context, index) {
                    final file = allFiles[index];
                    final isPdf =
                        file.toLowerCase().contains('.pdf') ||
                        file.contains('pdf') ||
                        index >= widget.section.photos.length;
                    final isPhoto = index < widget.section.photos.length;

                    final fileName = _getFileName(file, index, isPdf, isPhoto);

                    return CheckboxListTile(
                      value: fileSelection[index],
                      onChanged: (bool? value) {
                        setState(() {
                          fileSelection[index] = value ?? false;
                        });
                      },
                      title: Text(
                        fileName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        isPdf ? 'PDF' : 'Foto',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPdf
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                      secondary: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.image,
                        color: isPdf ? Colors.red : Colors.blue,
                      ),
                      activeColor: const Color(0xFF06B6D4),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (int i = 0; i < fileSelection.length; i++) {
                            fileSelection[i] = true;
                          }
                        });
                      },
                      child: const Text('Todos'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final selected = <String>[];
                        for (int i = 0; i < fileSelection.length; i++) {
                          if (fileSelection[i]) {
                            selected.add(allFiles[i]);
                          }
                        }
                        if (selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecciona al menos un archivo'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(selected);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Compartir'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getFileName(String url, int index, bool isPdf, bool isPhoto) {
    // Intentar extraer el nombre del archivo de la URL
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      if (segments.isNotEmpty) {
        String fileName = segments.last;
        // Decodificar caracteres especiales
        fileName = Uri.decodeComponent(fileName);

        // Si el nombre es muy largo, acortarlo
        if (fileName.length > 40) {
          final extension = fileName.substring(fileName.lastIndexOf('.'));
          fileName = '${fileName.substring(0, 35)}...$extension';
        }

        return fileName;
      }
    } catch (e) {
      // Si hay error al parsear, usar nombre genérico
    }

    // Nombre genérico si no se puede extraer
    if (isPdf) {
      return 'Documento PDF ${index - widget.section.photos.length + 1}';
    } else {
      return 'Foto ${index + 1}';
    }
  }
}
