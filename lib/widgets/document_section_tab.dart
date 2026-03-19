import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/native_helper.dart';
import '../models/document_section.dart';
import '../models/document_history_record.dart';
import '../services/media_service.dart';
import '../services/firebase_service.dart';
import '../services/share_service.dart';
import '../l10n/app_localizations.dart';
import '../services/employee_service.dart';
import 'photo_gallery_viewer.dart';

// Helper para guardar archivo en Downloads público (Android)
Future<String> _saveFileToDownloads(File sourceFile, String fileName) async {
  if (Platform.isAndroid) {
    try {
      // Usar la ruta directa de Downloads público
      final downloadsPath = '/storage/emulated/0/Download';
      final targetFile = File('$downloadsPath/$fileName');

      // Copiar el archivo
      await sourceFile.copy(targetFile.path);

      debugPrint('✅ Archivo guardado en: ${targetFile.path}');
      return targetFile.path;
    } catch (e) {
      debugPrint('❌ Error al guardar en Downloads: $e');
      // Si falla, intentar crear subdirectorio
      try {
        final downloadsDir = Directory('/storage/emulated/0/Download/Reportes');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        final targetFile = File('${downloadsDir.path}/$fileName');
        await sourceFile.copy(targetFile.path);
        debugPrint('✅ Archivo guardado en: ${targetFile.path}');
        return targetFile.path;
      } catch (e2) {
        debugPrint('❌ Error al crear subdirectorio: $e2');
        // Último recurso: devolver la ruta del archivo temporal
        return sourceFile.path;
      }
    }
  } else {
    // En iOS, el archivo ya está en un lugar accesible
    return sourceFile.path;
  }
}

class DocumentSectionTab extends StatefulWidget {
  final String title;
  final DocumentSection section;
  final String vehicleId;
  final String sectionName;
  final Function(DocumentSection) onUpdate;
  final bool hideButtons;

  const DocumentSectionTab({
    super.key,
    required this.title,
    required this.section,
    required this.vehicleId,
    required this.sectionName,
    required this.onUpdate,
    this.hideButtons = false,
  });

  @override
  State<DocumentSectionTab> createState() => _DocumentSectionTabState();
}

class _DocumentSectionTabState extends State<DocumentSectionTab> {
  final MediaService _mediaService = MediaService();
  final FirebaseService _firebaseService = FirebaseService();
  final ShareService _shareService = ShareService();
  final EmployeeService _employeeService = EmployeeService();
  late TextEditingController _notesController;
  bool _isEmployee = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.section.notes);
    _checkEmployeeStatus();
  }

  @override
  void didUpdateWidget(DocumentSectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el controller si las notas cambiaron
    if (oldWidget.section.notes != widget.section.notes) {
      _notesController.text = widget.section.notes;
    }
  }

  Future<void> _checkEmployeeStatus() async {
    final currentEmployee = await _employeeService.getCurrentEmployee();
    if (mounted) {
      setState(() {
        _isEmployee = currentEmployee != null;
      });
    }
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
              widget.sectionName == 'tarjeta_circulacion' ||
              widget.sectionName == 'otros_documentos' ||
              widget.sectionName == 'engomado_ecologico')
            _buildExpirationBanner(),
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion' ||
              widget.sectionName == 'otros_documentos' ||
              widget.sectionName == 'engomado_ecologico')
            const SizedBox(height: 24),
          // Fecha de Vencimiento
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion' ||
              widget.sectionName == 'otros_documentos' ||
              widget.sectionName == 'engomado_ecologico')
            _buildSection(
              title: AppLocalizations.of(context).expirationDateLabel,
              icon: Icons.calendar_today,
              child: _buildExpirationDatePicker(),
            ),
          if (widget.sectionName == 'seguro' ||
              widget.sectionName == 'tarjeta_circulacion' ||
              widget.sectionName == 'otros_documentos' ||
              widget.sectionName == 'engomado_ecologico')
            const SizedBox(height: 24),
          // Fotos
          _buildSection(
            title: AppLocalizations.of(context).photos,
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
            title: AppLocalizations.of(context).pdfDocuments,
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
            title: AppLocalizations.of(context).notes,
            icon: Icons.note,
            child: Column(
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    ).writeNotesAboutDocument,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                if (!widget.hideButtons) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveNotes,
                      icon: const Icon(Icons.save, size: 20),
                      label: Text(
                        AppLocalizations.of(context).saveInformation,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17A2B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                        shadowColor: const Color(
                          0xFF17A2B8,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botón de ver historial para todos los usuarios
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.section.history.isEmpty
                          ? null
                          : _viewHistory,
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        ).viewHistoryCount(widget.section.history.length),
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF17A2B8),
                        side: const BorderSide(color: Color(0xFF17A2B8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Compartir Documentos - Solo para gerentes
          if (!_isEmployee) ...[
            _buildSection(
              title: AppLocalizations.of(context).shareDocuments,
              icon: Icons.share,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareViaWhatsApp,
                      icon: const Icon(Icons.message, size: 20),
                      label: Text(
                        AppLocalizations.of(context).whatsapp,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                        shadowColor: const Color(
                          0xFF25D366,
                        ).withValues(alpha: 0.4),
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
                      label: Text(
                        AppLocalizations.of(context).email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17A2B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 3,
                        shadowColor: const Color(
                          0xFF17A2B8,
                        ).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ], // Fin del bloque if (!_isEmployee) para compartir documentos
          // Espacio adicional al final para asegurar scroll completo
          const SizedBox(height: 40),
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
                AppLocalizations.of(context).setExpirationDateNotification,
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
      message = AppLocalizations.of(
        context,
      ).expirationBannerExpired(widget.section.daysUntilExpiration.abs());
    } else if (widget.section.isExpiringSoon) {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      icon = Icons.warning;
      message = AppLocalizations.of(
        context,
      ).expirationBannerExpiringSoon(widget.section.daysUntilExpiration);
    } else {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
      message = AppLocalizations.of(
        context,
      ).expirationBannerValid(widget.section.daysUntilExpiration);
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
            const Icon(Icons.event, color: Color(0xFF17A2B8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).expirationDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.section.expirationDate != null
                        ? '${widget.section.expirationDate!.day.toString().padLeft(2, '0')}/${widget.section.expirationDate!.month.toString().padLeft(2, '0')}/${widget.section.expirationDate!.year}'
                        : AppLocalizations.of(context).selectDate,
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
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF17A2B8),
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

        ScaffoldMessenger.of(context).clearSnackBars();
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
                        ? AppLocalizations.of(
                            context,
                          ).expirationDateSavedExpiredWarning
                        : AppLocalizations.of(context).expirationDateSaved,
                  ),
                ),
              ],
            ),
            backgroundColor: isExpired ? Colors.red.shade700 : Colors.green,
            duration: Duration(seconds: isExpired ? 3 : 2),
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
            Icon(icon, color: const Color(0xFF17A2B8)),
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
        child: Center(
          child: Text(
            AppLocalizations.of(context).noPhotos,
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoGalleryViewer(
                      photoUrls: widget.section.photos,
                      initialIndex: index,
                      title: widget.title,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(photoUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Botón de eliminar
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
            // Botón de descarga
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _downloadPhotoMain(photoUrl),
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
              color: const Color(0xFF17A2B8).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: _addPhoto,
          icon: const Icon(Icons.add_a_photo, size: 20),
          label: Text(
            AppLocalizations.of(context).addPhoto,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF17A2B8),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF17A2B8), width: 2),
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
        child: Center(
          child: Text(
            AppLocalizations.of(context).noPdfDocuments,
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
        final pdfUrl = widget.section.pdfs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(AppLocalizations.of(context).documentNumber(index + 1)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Color(0xFF17A2B8)),
                  onPressed: () => _openPdfMain(pdfUrl),
                  tooltip: AppLocalizations.of(context).openPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF17A2B8)),
                  onPressed: () => _downloadPdfMain(pdfUrl, index),
                  tooltip: AppLocalizations.of(context).downloadPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePdf(index),
                  tooltip: AppLocalizations.of(context).delete,
                ),
              ],
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
              color: const Color(0xFF17A2B8).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: _addPdf,
          icon: const Icon(Icons.upload_file, size: 20),
          label: Text(
            AppLocalizations.of(context).addPdf,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF17A2B8),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF17A2B8), width: 2),
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
        final userId = FirebaseAuth.instance.currentUser?.uid;

        final url = userId != null
            ? await _firebaseService.uploadImage(
                photo,
                widget.vehicleId,
                userId,
                widget.sectionName,
              )
            : await _firebaseService.uploadFile(
                photo,
                '',
                'vehicles/${widget.vehicleId}/${widget.sectionName}',
              );

        final updatedSection = widget.section.copyWith(
          photos: [...widget.section.photos, url],
        );

        widget.onUpdate(updatedSection);

        if (mounted) {
          // Los cambios se propagan vía callback onUpdate
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).photoAddedSuccessfully,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).errorUploadingPhoto(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
        title: Text(AppLocalizations.of(context).deletePhoto),
        content: Text(AppLocalizations.of(context).deletePhotoConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).deletePhoto),
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
          // Los cambios se propagan vía callback onUpdate
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).photoDeletedSuccessfully,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).errorDeletingPhoto(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final url = userId != null
            ? await _firebaseService.uploadPdf(
                pdf,
                widget.vehicleId,
                userId,
                widget.sectionName,
              )
            : await _firebaseService.uploadFile(
                pdf,
                '',
                'vehicles/${widget.vehicleId}/${widget.sectionName}',
              );

        final updatedSection = widget.section.copyWith(
          pdfs: [...widget.section.pdfs, url],
        );

        widget.onUpdate(updatedSection);

        if (mounted) {
          // Los cambios se propagan vía callback onUpdate
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).pdfAddedSuccessfully),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).errorUploadingPdf(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
        title: Text(AppLocalizations.of(context).deletePhoto),
        content: Text(AppLocalizations.of(context).deleteDocumentConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).deletePhoto),
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
          // Los cambios se propagan vía callback onUpdate
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).pdfDeletedSuccessfully,
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).errorDeletingPdf(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _saveNotes() {
    final trimmedNotes = _notesController.text.trim();

    // Validar que haya contenido
    if (trimmedNotes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).pleaseWriteNoteBeforeSaving,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Actualizar las notas en la sección
    final updatedSection = widget.section.copyWith(notes: trimmedNotes);

    // Automáticamente guardar también en historial (para todos los usuarios)
    // Crear registro de historial con las notas actualizadas
    final historyRecord = DocumentHistoryRecord(
      id: const Uuid().v4(),
      date: DateTime.now(),
      sectionName: widget.title,
      expirationDate: updatedSection.expirationDate,
      photos: List<String>.from(updatedSection.photos),
      pdfs: List<String>.from(updatedSection.pdfs),
      notes: trimmedNotes, // Usar las notas actualizadas
    );

    final updatedHistory = [historyRecord, ...widget.section.history];
    final sectionWithHistory = updatedSection.copyWith(history: updatedHistory);

    widget.onUpdate(sectionWithHistory);

    if (mounted) {
      // Los cambios se propagan vía callback onUpdate
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).notesSavedAndAddedToHistory,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareViaWhatsApp() async {
    // Capturar traducciones antes de operaciones async
    final loc = AppLocalizations.of(context);

    // Obtener todos los archivos directamente sin mostrar diálogo
    final allFiles = [...widget.section.photos, ...widget.section.pdfs];

    if (allFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.noDocumentsOrPhotosToShare),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(loc.preparingFilesToShare),
            ],
          ),
          duration: Duration(seconds: 10),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );
    }

    try {
      // Construir un mensaje más descriptivo
      String message = '📄 ${widget.title}';

      // Agregar información del vehículo
      final vehicleIdShort = widget.vehicleId.length >= 8
          ? widget.vehicleId.substring(0, 8)
          : widget.vehicleId;
      message += '\n🚗 ${loc.shareMessageVehicleLabel}: $vehicleIdShort';

      // Agregar fecha de vencimiento si existe
      if (widget.section.expirationDate != null) {
        final dateFormatter = DateFormat('dd/MM/yyyy');
        final formattedDate = dateFormatter.format(
          widget.section.expirationDate!,
        );
        message += '\n📅 ${loc.shareMessageExpiresLabel}: $formattedDate';

        // Agregar estado del documento
        if (widget.section.isExpired) {
          message += ' ⚠️ (${loc.shareMessageStatusExpired})';
        } else if (widget.section.isExpiringSoon) {
          final daysLeft = widget.section.daysUntilExpiration;
          message += ' ⏰ (${loc.shareMessageStatusExpiring(daysLeft)})';
        } else {
          message += ' ✅ (${loc.shareMessageStatusValid})';
        }
      }

      // Agregar notas si existen
      if (widget.section.notes.isNotEmpty) {
        final notesPreview = widget.section.notes.length > 50
            ? '${widget.section.notes.substring(0, 50)}...'
            : widget.section.notes;
        message += '\n📝 ${loc.shareMessageNotesLabel}: $notesPreview';
      }

      // Compartir todos los archivos
      if (allFiles.length == 1) {
        await _shareService.shareViaWhatsApp(allFiles.first, message);
      } else {
        await _shareService.shareMultipleFiles(allFiles, message: message);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(loc.sharingViaWhatsapp),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
                Expanded(child: Text(loc.errorSharing('$e'))),
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
    // Capturar traducciones antes de operaciones async
    final loc = AppLocalizations.of(context);
    final vehicleIdShort = widget.vehicleId.length >= 8
        ? widget.vehicleId.substring(0, 8)
        : widget.vehicleId;

    // Obtener todos los archivos directamente sin mostrar diálogo
    final allFiles = [...widget.section.photos, ...widget.section.pdfs];

    if (allFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.noDocumentsOrPhotosToShare),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(loc.preparingFilesToShare),
            ],
          ),
          duration: Duration(seconds: 10),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );
    }

    try {
      // Construir asunto y cuerpo del correo más descriptivos
      final subject = loc.shareEmailSubject(widget.title, vehicleIdShort);

      String body = '${loc.shareEmailBodyIntro(widget.title)}\n';
      body += '${loc.shareEmailVehicleId(vehicleIdShort)}\n';

      // Agregar información de vencimiento
      if (widget.section.expirationDate != null) {
        final dateFormatter = DateFormat('dd/MM/yyyy');
        final formattedDate = dateFormatter.format(
          widget.section.expirationDate!,
        );
        body += '${loc.shareEmailExpirationDate(formattedDate)}\n';

        if (widget.section.isExpired) {
          body += '${loc.shareEmailStatusExpired}\n';
        } else if (widget.section.isExpiringSoon) {
          final daysLeft = widget.section.daysUntilExpiration;
          body += '${loc.shareEmailStatusExpiring(daysLeft)}\n';
        } else {
          body += '${loc.shareEmailStatusValid}\n';
        }
      }

      // Agregar notas si existen
      if (widget.section.notes.isNotEmpty) {
        body += '\n${loc.shareEmailNotesHeader}\n${widget.section.notes}';
      }

      // Compartir todos los archivos
      if (allFiles.length == 1) {
        await _shareService.shareViaEmail(allFiles.first, subject, body, '');
      } else {
        await _shareService.shareMultipleFiles(
          allFiles,
          message: '$subject\n$body',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(loc.sharingViaEmail),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
                Expanded(child: Text(loc.errorSharing(e.toString()))),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DocumentHistoryScreen(
          sectionTitle: widget.title,
          history: widget.section.history,
          vehicleId: widget.vehicleId,
          sectionName: widget.sectionName,
          onUpdate: (updatedHistory) {
            final updatedSection = widget.section.copyWith(
              history: updatedHistory,
            );
            widget.onUpdate(updatedSection);
          },
        ),
      ),
    );
  }

  Future<void> _downloadPhotoMain(String photoUrl) async {
    final loc = AppLocalizations.of(context);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.downloadingPhoto),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

      if (Platform.isAndroid) {
        final status = await NativeHelper.requestStoragePermission();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.storagePermissionDenied),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        // Guardar en directorio temporal primero
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${widget.title}_foto_$timestamp.jpg';
        final tempFilePath = '${tempDir.path}/$fileName';

        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Copiar a Downloads público
        await _saveFileToDownloads(tempFile, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.photoSavedIn('Download/Reportes')),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(loc.errorDownloading);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorDownloadingWithError('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openPdfMain(String pdfUrl) async {
    final loc = AppLocalizations.of(context);
    try {
      // Mostrar indicador de descarga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.downloadingPdf),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

      // Descargar el PDF a la caché temporal
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'documento_$timestamp.pdf';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Abrir el PDF con la aplicación predeterminada del sistema
        final opened = await NativeHelper.openFile(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (!opened) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.errorOpeningPdf),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        throw Exception(loc.errorOpeningPdf);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorOpeningPdf),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdfMain(String pdfUrl, int index) async {
    final loc = AppLocalizations.of(context);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.downloadingPdf),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

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

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        // Guardar en directorio temporal primero
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            '${widget.title}_documento_${index + 1}_$timestamp.pdf';
        final tempFilePath = '${tempDir.path}/$fileName';

        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Copiar a Downloads público
        await _saveFileToDownloads(tempFile, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.pdfSavedIn('Download/Reportes')),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(loc.errorDownloading);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorDownloadingWithError('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// ============================================================
// DOCUMENT HISTORY SCREEN
// ============================================================

class _DocumentHistoryScreen extends StatefulWidget {
  final String sectionTitle;
  final List<DocumentHistoryRecord> history;
  final String vehicleId;
  final String sectionName;
  final Function(List<DocumentHistoryRecord>) onUpdate;

  const _DocumentHistoryScreen({
    required this.sectionTitle,
    required this.history,
    required this.vehicleId,
    required this.sectionName,
    required this.onUpdate,
  });

  @override
  State<_DocumentHistoryScreen> createState() => _DocumentHistoryScreenState();
}

class _DocumentHistoryScreenState extends State<_DocumentHistoryScreen> {
  late List<DocumentHistoryRecord> _history;
  final EmployeeService _employeeService = EmployeeService();
  final ShareService _shareService = ShareService();
  bool _isEmployee = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _history = List<DocumentHistoryRecord>.from(widget.history);
    _checkEmployeeStatus();
  }

  Future<void> _checkEmployeeStatus() async {
    final currentEmployee = await _employeeService.getCurrentEmployee();
    if (mounted) {
      setState(() {
        _isEmployee = currentEmployee != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).historyTitle(widget.sectionTitle),
        ),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).historyEmptyTitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).historyEmptySubtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return _DocumentHistoryCard(
                  record: _history[index],
                  // Solo gerentes pueden borrar y compartir
                  onDelete: _isEmployee ? null : () => _deleteRecord(index),
                  onShare: _isEmployee
                      ? null
                      : () => _shareRecord(_history[index]),
                  onDownload: _isEmployee
                      ? null
                      : () => _downloadRecordZip(_history[index]),
                  onTap: () => _viewRecord(_history[index]),
                );
              },
            ),
    );
  }

  Future<void> _deleteRecord(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deletePhoto),
        content: Text(
          AppLocalizations.of(context).deleteHistoryRecordConfirmation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).deletePhoto),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _history.removeAt(index);
      });

      widget.onUpdate(_history);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).recordDeleted),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareRecord(DocumentHistoryRecord record) async {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final loc = AppLocalizations.of(context);

    final savedDate = formatter.format(record.date);
    String text =
        '📄 ${widget.sectionTitle}\n'
        '🕒 ${loc.historySavedDateLabel}: $savedDate\n\n';

    if (record.expirationDate != null) {
      text +=
          '📅 ${loc.historyExpirationDateLabel}: ${dateFormatter.format(record.expirationDate!)}\n';
    }

    text +=
        '📸 ${loc.historyPhotosLabel}: ${record.photos.length}\n'
        '📎 ${loc.historyPdfsLabel}: ${record.pdfs.length}\n';

    if (record.notes.isNotEmpty) {
      text += '\n📝 ${loc.historyNotesLabel}:\n${record.notes}';
    }

    try {
      // Combinar fotos y PDFs del registro
      final allFiles = [...record.photos, ...record.pdfs];

      if (allFiles.isEmpty) {
        // Si no hay archivos, solo compartir el texto
        await Share.share(
          text,
          subject: AppLocalizations.of(
            context,
          ).historyShareSubject(widget.sectionTitle, savedDate),
        );
      } else {
        // Mostrar indicador de progreso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loc.generatingZip),
                ],
              ),
              backgroundColor: const Color(0xFF17A2B8),
              duration: const Duration(seconds: 10),
            ),
          );
        }

        // Generar archivo ZIP con todos los archivos
        final storage = FirebaseStorage.instance;
        final archive = Archive();

        // Descargar y agregar fotos
        int photoIndex = 1;
        for (final photoUrl in record.photos) {
          try {
            debugPrint('📸 Descargando foto $photoIndex: $photoUrl');
            final ref = storage.refFromURL(photoUrl);
            final data = await ref.getData();

            if (data != null) {
              // Detectar extensión de la foto
              String extension = 'jpg';
              if (photoUrl.toLowerCase().contains('.png')) {
                extension = 'png';
              }
              archive.addFile(
                ArchiveFile('Foto_$photoIndex.$extension', data.length, data),
              );
              debugPrint('✅ Foto $photoIndex agregada al ZIP');
              photoIndex++;
            }
          } catch (e) {
            debugPrint('❌ Error al descargar foto $photoIndex: $e');
          }
        }

        // Descargar y agregar PDFs
        int pdfIndex = 1;
        for (final pdfUrl in record.pdfs) {
          try {
            debugPrint('📄 Descargando PDF $pdfIndex: $pdfUrl');
            final ref = storage.refFromURL(pdfUrl);
            final data = await ref.getData();

            if (data != null) {
              archive.addFile(
                ArchiveFile('Documento_$pdfIndex.pdf', data.length, data),
              );
              debugPrint('✅ PDF $pdfIndex agregado al ZIP');
              pdfIndex++;
            }
          } catch (e) {
            debugPrint('❌ Error al descargar PDF $pdfIndex: $e');
          }
        }

        // Agregar archivo de información
        String infoText =
            '''REGISTRO DE DOCUMENTO
Sección: ${record.sectionName}
Fecha de guardado: ${formatter.format(record.date)}
''';

        if (record.expirationDate != null) {
          infoText +=
              'Fecha de vencimiento: ${dateFormatter.format(record.expirationDate!)}\n';
        }

        infoText +=
            '''\nNotas: ${record.notes.isEmpty ? 'Sin notas' : record.notes}\n\nFotos incluidas: ${record.photos.length}
Documentos PDF incluidos: ${record.pdfs.length}
''';

        archive.addFile(
          ArchiveFile('Informacion.txt', infoText.length, infoText.codeUnits),
        );

        // Codificar ZIP
        final zipEncoder = ZipEncoder();
        final zipData = zipEncoder.encode(archive);

        if (zipData == null || zipData.isEmpty) {
          throw Exception('Error al codificar el archivo ZIP');
        }

        debugPrint('📦 ZIP codificado: ${zipData.length} bytes');

        // Guardar ZIP temporalmente
        final directory = await getTemporaryDirectory();
        final dateFormatFileName = DateFormat('dd-MM-yyyy_HH-mm');
        final sectionNameClean = record.sectionName.replaceAll(
          RegExp(r'[^a-zA-Z0-9]'),
          '_',
        );
        final fileName =
            '${sectionNameClean}_${dateFormatFileName.format(record.date)}.zip';
        final filePath = '${directory.path}/$fileName';

        debugPrint('📦 Guardando ZIP temporal en: $filePath');
        final file = File(filePath);
        await file.writeAsBytes(zipData);

        // Verificar que el archivo existe y es válido
        if (!await file.exists()) {
          throw Exception('No se pudo guardar el archivo ZIP');
        }

        final fileSize = await file.length();
        debugPrint(
          '✅ ZIP guardado: $fileSize bytes - Existe: ${await file.exists()}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        // Compartir el archivo ZIP con un pequeño delay para asegurar que el archivo esté listo
        await Future.delayed(const Duration(milliseconds: 100));
        await _shareService.shareFile(filePath, message: text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(loc.sharingViaWhatsapp),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error en _shareRecord: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppLocalizations.of(context).errorSharing('$e')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadRecordZip(DocumentHistoryRecord record) async {
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

      // No se requieren permisos especiales para escribir en el directorio de la app

      // Crear archivo ZIP
      final archive = Archive();
      final storage = FirebaseStorage.instance;

      // Descargar y agregar fotos al ZIP
      int photoIndex = 1;
      for (String photoUrl in record.photos) {
        try {
          debugPrint('📸 Descargando foto $photoIndex: $photoUrl');

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
            debugPrint('✅ Foto $photoIndex agregada al ZIP');
            photoIndex++;
          }
        } catch (e) {
          debugPrint('❌ Error al descargar foto $photoIndex: $e');
        }
      }

      // Descargar y agregar PDFs al ZIP
      int pdfIndex = 1;
      for (String pdfUrl in record.pdfs) {
        try {
          debugPrint('📄 Descargando PDF $pdfIndex: $pdfUrl');

          // Usar Firebase Storage para descargar
          final ref = storage.refFromURL(pdfUrl);
          final data = await ref.getData();

          if (data != null) {
            archive.addFile(
              ArchiveFile('Documento_$pdfIndex.pdf', data.length, data),
            );
            debugPrint('✅ PDF $pdfIndex agregado al ZIP');
            pdfIndex++;
          }
        } catch (e) {
          debugPrint('❌ Error al descargar PDF $pdfIndex: $e');
          // Continuar con el siguiente PDF si hay error
        }
      }

      // Agregar archivo de texto con la información del documento
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final dateFormatter = DateFormat('dd/MM/yyyy');
      String infoText =
          '''
REGISTRO DE DOCUMENTO
Sección: ${record.sectionName}
Fecha de guardado: ${dateFormat.format(record.date)}
''';

      if (record.expirationDate != null) {
        infoText +=
            'Fecha de vencimiento: ${dateFormatter.format(record.expirationDate!)}\n';
      }

      infoText +=
          '''

Notas: ${record.notes.isEmpty ? 'Sin notas' : record.notes}

Fotos incluidas: ${record.photos.length}
Documentos PDF incluidos: ${record.pdfs.length}
''';

      archive.addFile(
        ArchiveFile('Informacion.txt', infoText.length, infoText.codeUnits),
      );

      // Codificar ZIP
      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      if (zipData == null || zipData.isEmpty) {
        throw Exception('Error al codificar el archivo ZIP');
      }

      debugPrint('📦 ZIP codificado: ${zipData.length} bytes');

      // Crear archivo temporal primero
      final tempDir = await getTemporaryDirectory();
      final dateFormatFileName = DateFormat('dd-MM-yyyy_HH-mm');
      final sectionNameClean = record.sectionName.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '_',
      );
      final fileName =
          '${sectionNameClean}_${dateFormatFileName.format(record.date)}.zip';
      final tempFilePath = '${tempDir.path}/$fileName';

      debugPrint('📦 Guardando ZIP temporal en: $tempFilePath');
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(zipData);

      // Mover a Downloads público
      final finalPath = await _saveFileToDownloads(tempFile, fileName);
      final file = File(finalPath);

      // Verificar que el archivo es un ZIP válido leyendo los primeros bytes
      final savedBytes = await file.readAsBytes();
      final isValidZip =
          savedBytes.length >= 4 &&
          savedBytes[0] == 0x50 &&
          savedBytes[1] == 0x4B &&
          (savedBytes[2] == 0x03 ||
              savedBytes[2] == 0x05 ||
              savedBytes[2] == 0x07);
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

  void _viewRecord(DocumentHistoryRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DocumentRecordViewerScreen(
          record: record,
          sectionTitle: widget.sectionTitle,
        ),
      ),
    );
  }
}

// ============================================================
// DOCUMENT HISTORY CARD
// ============================================================

class _DocumentHistoryCard extends StatelessWidget {
  final DocumentHistoryRecord record;
  final VoidCallback? onDelete; // Ahora opcional
  final VoidCallback? onShare; // Ahora opcional
  final VoidCallback? onDownload; // Nuevo opcional
  final VoidCallback onTap;

  const _DocumentHistoryCard({
    required this.record,
    this.onDelete, // Ahora opcional
    this.onShare, // Ahora opcional
    this.onDownload, // Nuevo opcional
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

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
                      Icons.description,
                      color: Color(0xFF17A2B8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.sectionName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatter.format(record.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Solo mostrar botones si los callbacks están disponibles
                  if (onDownload != null)
                    IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      onPressed: onDownload,
                      color: const Color(0xFF22C55E),
                      tooltip: AppLocalizations.of(context).downloadReportZip,
                    ),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: onShare,
                      color: const Color(0xFF17A2B8),
                      tooltip: AppLocalizations.of(context).share,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      color: Colors.red.shade400,
                      tooltip: AppLocalizations.of(context).delete,
                    ),
                ],
              ),
              if (record.expirationDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).expiresLabel(
                          dateFormatter.format(record.expirationDate!),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.photo,
                    '${record.photos.length} ${record.photos.length == 1 ? AppLocalizations.of(context).photoSingular : AppLocalizations.of(context).photosPlural}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.picture_as_pdf,
                    '${record.pdfs.length} ${record.pdfs.length == 1 ? AppLocalizations.of(context).pdfSingular : AppLocalizations.of(context).pdfsPlural}',
                    Colors.red,
                  ),
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.note,
                      AppLocalizations.of(context).withNotesLabel,
                      Colors.orange,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DOCUMENT RECORD VIEWER SCREEN (READ-ONLY)
// ============================================================

class _DocumentRecordViewerScreen extends StatefulWidget {
  final DocumentHistoryRecord record;
  final String sectionTitle;

  const _DocumentRecordViewerScreen({
    required this.record,
    required this.sectionTitle,
  });

  @override
  State<_DocumentRecordViewerScreen> createState() =>
      _DocumentRecordViewerScreenState();
}

class _DocumentRecordViewerScreenState
    extends State<_DocumentRecordViewerScreen> {
  final EmployeeService _employeeService = EmployeeService();
  bool _isEmployee = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkEmployeeStatus();
  }

  Future<void> _checkEmployeeStatus() async {
    final currentEmployee = await _employeeService.getCurrentEmployee();
    if (mounted) {
      setState(() {
        _isEmployee = currentEmployee != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).recordSaved),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner informativo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isEmployee ? Colors.blue.shade50 : Colors.amber.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: _isEmployee
                        ? Colors.blue.shade200
                        : Colors.amber.shade200,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _isEmployee
                        ? Colors.blue.shade900
                        : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEmployee
                              ? AppLocalizations.of(context).employeeViewTitle
                              : AppLocalizations.of(context).readOnlyViewTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isEmployee
                                ? Colors.blue.shade900
                                : Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context).recordSavedOn(
                            widget.sectionTitle,
                            formatter.format(widget.record.date),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: _isEmployee
                                ? Colors.blue.shade800
                                : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del documento
                  _buildInfoSection(
                    title: AppLocalizations.of(
                      context,
                    ).documentInformationTitle,
                    icon: Icons.info,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          AppLocalizations.of(context).documentLabel,
                          widget.record.sectionName,
                        ),
                        if (widget.record.expirationDate != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            AppLocalizations.of(context).expirationDateLabel,
                            dateFormatter.format(widget.record.expirationDate!),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fotos
                  _buildInfoSection(
                    title: AppLocalizations.of(
                      context,
                    ).photosSectionTitle(widget.record.photos.length),
                    icon: Icons.photo,
                    child: widget.record.photos.isEmpty
                        ? _buildEmptyState(
                            AppLocalizations.of(context).noPhotos,
                          )
                        : _buildPhotoGrid(context),
                  ),

                  const SizedBox(height: 20),

                  // PDFs
                  _buildInfoSection(
                    title: AppLocalizations.of(
                      context,
                    ).pdfsSectionTitle(widget.record.pdfs.length),
                    icon: Icons.picture_as_pdf,
                    child: widget.record.pdfs.isEmpty
                        ? _buildEmptyState(
                            AppLocalizations.of(context).noPdfDocuments,
                          )
                        : _buildPdfList(),
                  ),

                  const SizedBox(height: 20),

                  // Notas
                  _buildInfoSection(
                    title: AppLocalizations.of(context).notes,
                    icon: Icons.note,
                    child: widget.record.notes.isEmpty
                        ? _buildEmptyState(AppLocalizations.of(context).noNotes)
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              widget.record.notes,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                                height: 1.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF17A2B8), size: 22),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.record.photos.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoGalleryViewer(
                      photoUrls: widget.record.photos,
                      initialIndex: index,
                      title: '${widget.sectionTitle} - Historial',
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(widget.record.photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Botón de descarga
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _downloadPhoto(widget.record.photos[index]),
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
    );
  }

  Widget _buildPdfList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.record.pdfs.length,
      itemBuilder: (context, index) {
        final pdfUrl = widget.record.pdfs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(
              AppLocalizations.of(context).pdfDocumentNumber(index + 1),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Color(0xFF17A2B8)),
                  onPressed: () => _openPdf(pdfUrl),
                  tooltip: AppLocalizations.of(context).openPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF17A2B8)),
                  onPressed: () => _downloadPdf(pdfUrl, index),
                  tooltip: AppLocalizations.of(context).downloadPdf,
                ),
              ],
            ),
            dense: true,
          ),
        );
      },
    );
  }

  Future<void> _downloadPhoto(String photoUrl) async {
    final loc = AppLocalizations.of(context);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.downloadingPhoto),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

      if (Platform.isAndroid) {
        final status = await NativeHelper.requestStoragePermission();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.storagePermissionDenied),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        // Guardar en directorio temporal primero
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${widget.sectionTitle}_foto_$timestamp.jpg';
        final tempFilePath = '${tempDir.path}/$fileName';

        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Copiar a Downloads público
        await _saveFileToDownloads(tempFile, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.photoSavedIn('Download/Reportes')),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(loc.errorDownloading);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorDownloadingWithError('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openPdf(String pdfUrl) async {
    final loc = AppLocalizations.of(context);
    try {
      // Mostrar indicador de descarga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.downloadingPdf),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

      // Descargar el PDF a la caché temporal
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'documento_$timestamp.pdf';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Abrir el PDF con la aplicación predeterminada del sistema
        final opened = await NativeHelper.openFile(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          if (!opened) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.errorOpeningPdf),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        throw Exception(loc.errorOpeningPdf);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorOpeningPdf),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPdf(String pdfUrl, int index) async {
    final loc = AppLocalizations.of(context);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.downloadingPdf),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF17A2B8),
        ),
      );

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

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        // Guardar en directorio temporal primero
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName =
            '${widget.sectionTitle}_documento_${index + 1}_$timestamp.pdf';
        final tempFilePath = '${tempDir.path}/$fileName';

        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Copiar a Downloads público
        await _saveFileToDownloads(tempFile, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.pdfSavedIn('Download/Reportes')),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(loc.errorDownloading);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorDownloadingWithError('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
