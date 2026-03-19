import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/native_helper.dart';
import '../models/driver_section.dart';
import '../models/driver_history_record.dart';
import '../models/document_history_record.dart';
import 'document_section_tab.dart';
import 'photo_gallery_viewer.dart';
import '../l10n/app_localizations.dart';
import '../services/share_service.dart';

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

class DriverSectionTab extends StatefulWidget {
  final DriverSection driver;
  final String vehicleId;
  final Function(DriverSection) onUpdate;

  const DriverSectionTab({
    super.key,
    required this.driver,
    required this.vehicleId,
    required this.onUpdate,
  });

  @override
  State<DriverSectionTab> createState() => _DriverSectionTabState();
}

class _DriverSectionTabState extends State<DriverSectionTab> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _phoneController = TextEditingController(text: widget.driver.phone);
    _emailController = TextEditingController(text: widget.driver.email);
  }

  @override
  void didUpdateWidget(DriverSectionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar los controllers si los datos cambiaron
    if (oldWidget.driver.name != widget.driver.name) {
      _nameController.text = widget.driver.name;
    }
    if (oldWidget.driver.phone != widget.driver.phone) {
      _phoneController.text = widget.driver.phone;
    }
    if (oldWidget.driver.email != widget.driver.email) {
      _emailController.text = widget.driver.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del Conductor
          _buildSection(
            title: AppLocalizations.of(context).driverInformationTitle,
            icon: Icons.person,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: AppLocalizations.of(context).fullNameLabel,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildPhoneField(
                  controller: _phoneController,
                  label: AppLocalizations.of(context).phoneLabel,
                  icon: Icons.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: AppLocalizations.of(context).emailLabel,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          // Sección de documentos (fotos, PDFs, notas compartidas)
          _DocumentsSection(
            driver: widget.driver,
            vehicleId: widget.vehicleId,
            onUpdate: widget.onUpdate,
          ),
          const SizedBox(height: 24),
          // Botones unificados al final para toda la información
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveAllDriverInfo,
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
                shadowColor: const Color(0xFF17A2B8).withValues(alpha: 0.4),
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
              onPressed: widget.driver.history.isEmpty ? null : _viewHistory,
              icon: const Icon(Icons.list_alt, size: 18),
              label: Text(
                AppLocalizations.of(
                  context,
                ).viewHistoryCount(widget.driver.history.length),
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
      ),
    );
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
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
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: widget.driver.phone.isNotEmpty
            ? InkWell(
                onTap: () => _makePhoneCall(controller.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: const Color(0xFF25D366)),
                ),
              )
            : Icon(icon, color: const Color(0xFF17A2B8)),
        suffixIcon: widget.driver.phone.isNotEmpty
            ? Tooltip(
                message: AppLocalizations.of(context).callTooltip,
                child: IconButton(
                  icon: const Icon(
                    Icons.phone_in_talk,
                    color: Color(0xFF25D366),
                  ),
                  onPressed: () => _makePhoneCall(controller.text),
                ),
              )
            : null,
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
      keyboardType: TextInputType.phone,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).noPhoneSaved),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Limpiar el número de caracteres no numéricos excepto +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).cannotMakeCall),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorCalling('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveAllDriverInfo() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    // Guardar automáticamente en historial (para todos los usuarios)
    // con toda la información del conductor incluyendo fotos, pdfs y notas
    final record = DriverHistoryRecord(
      id: const Uuid().v4(),
      date: DateTime.now(),
      name: name,
      phone: phone,
      email: email,
      photos: List<String>.from(widget.driver.photos),
      pdfs: List<String>.from(widget.driver.pdfs),
      notes: widget.driver.notes,
    );

    // Agregar al historial
    final updatedHistory = <DocumentHistoryRecord>[
      record,
      ...widget.driver.history,
    ];

    final updatedDriver = widget.driver.copyWith(
      name: name,
      phone: phone,
      email: email,
      history: updatedHistory,
    );

    widget.onUpdate(updatedDriver);

    if (mounted) {
      // No necesitamos setState aquí porque los cambios se propagan vía callback
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).driverInfoSavedHistory(updatedHistory.length),
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

  void _viewHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DriverHistoryScreen(
          driver: widget.driver,
          vehicleId: widget.vehicleId,
          onUpdate: widget.onUpdate,
        ),
      ),
    );
  }
}

// Widget interno para manejar la sección de documentos
class _DocumentsSection extends StatelessWidget {
  final DriverSection driver;
  final String vehicleId;
  final Function(DriverSection) onUpdate;

  const _DocumentsSection({
    required this.driver,
    required this.vehicleId,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Convertimos DriverSection a DocumentSection temporalmente para usar el widget existente
    return DocumentSectionTab(
      title: AppLocalizations.of(context).driverDocumentsTitle,
      section: driver,
      vehicleId: vehicleId,
      sectionName: 'conductor',
      hideButtons: true, // Ocultar botones porque se manejan desde el padre
      onUpdate: (updatedSection) {
        // Actualizamos el DriverSection manteniendo la información del conductor
        final updatedDriver = DriverSection(
          name: driver.name,
          phone: driver.phone,
          email: driver.email,
          history: updatedSection
              .history, // Usar el historial actualizado de la sección
          photos: updatedSection.photos,
          pdfs: updatedSection.pdfs,
          notes: updatedSection.notes,
        );
        onUpdate(updatedDriver);
      },
    );
  }
}

// Pantalla de historial de conductores
class _DriverHistoryScreen extends StatefulWidget {
  final DriverSection driver;
  final String vehicleId;
  final Function(DriverSection) onUpdate;

  const _DriverHistoryScreen({
    required this.driver,
    required this.vehicleId,
    required this.onUpdate,
  });

  @override
  State<_DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<_DriverHistoryScreen> {
  late DriverSection _currentDriver;

  @override
  void initState() {
    super.initState();
    _currentDriver = widget.driver;
  }

  @override
  Widget build(BuildContext context) {
    final history = _currentDriver.history.cast<DriverHistoryRecord>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).driverHistoryTitle),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noHistoryRecords,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final record = history[history.length - 1 - index];
                return _DriverHistoryCard(
                  record: record,
                  onTap: () => _viewRecord(record),
                  onDelete: () => _deleteRecord(record),
                  onShare: () => _shareRecord(record),
                  onDownload: () => _downloadRecordZip(record),
                );
              },
            ),
    );
  }

  void _viewRecord(DriverHistoryRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DriverRecordViewerScreen(
          record: record,
          vehicleId: widget.vehicleId,
        ),
      ),
    );
  }

  Future<void> _deleteRecord(DriverHistoryRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteRecordTitle),
        content: Text(AppLocalizations.of(context).deleteRecordConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final history = List<DriverHistoryRecord>.from(_currentDriver.history)
        ..removeWhere((item) => item.id == record.id);

      final updatedDriver = _currentDriver.copyWith(history: history);

      setState(() {
        _currentDriver = updatedDriver;
      });

      widget.onUpdate(updatedDriver);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).recordDeletedMessage),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareRecord(DriverHistoryRecord record) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final loc = AppLocalizations.of(context);
    final notesText = record.notes.isEmpty ? loc.noNotes : record.notes;
    final nameText = record.name.isEmpty ? loc.noName : record.name;
    final phoneText = record.phone.isEmpty ? loc.notSpecified : record.phone;
    final emailText = record.email.isEmpty ? loc.notSpecified : record.email;
    final text = loc.driverShareRecordText(
      date: dateFormat.format(record.date),
      name: nameText,
      phone: phoneText,
      email: emailText,
      notes: notesText,
      photosCount: record.photos.length.toString(),
      pdfsCount: record.pdfs.length.toString(),
    );

    try {
      // Combinar fotos y PDFs del registro
      final allFiles = [...record.photos, ...record.pdfs];

      if (allFiles.isEmpty) {
        // Si no hay archivos, solo compartir el texto
        await Share.share(text);
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
            '''REGISTRO DE CONDUCTOR
Fecha de guardado: ${dateFormat.format(record.date)}
Nombre: $nameText
Teléfono: $phoneText
Email: $emailText

Notas: $notesText

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

        // Guardar ZIP temporalmente
        final directory = await getTemporaryDirectory();
        final dateFormatFileName = DateFormat('dd-MM-yyyy_HH-mm');
        final fileName =
            'Conductor_${dateFormatFileName.format(record.date)}.zip';
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
        final shareService = ShareService();
        await shareService.shareFile(filePath, message: text);

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
                Expanded(child: Text(loc.errorSharing('$e'))),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _downloadRecordZip(DriverHistoryRecord record) async {
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
          debugPrint('📸 Descargando foto conductor $photoIndex: $photoUrl');

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
          debugPrint('📄 Descargando PDF conductor $pdfIndex: $pdfUrl');

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
        }
      }

      // Agregar archivo de texto con la información del conductor
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      final infoText =
          '''
REGISTRO DE CONDUCTOR
Fecha: ${dateFormat.format(record.date)}

Información:
Nombre: ${record.name.isEmpty ? 'No especificado' : record.name}
Teléfono: ${record.phone.isEmpty ? 'No especificado' : record.phone}
Email: ${record.email.isEmpty ? 'No especificado' : record.email}

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
      final fileName =
          'Conductor_${dateFormatFileName.format(record.date)}.zip';
      final tempFilePath = '${tempDir.path}/$fileName';

      debugPrint('📦 Guardando ZIP temporal en: $tempFilePath');
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(zipData);

      // Mover a Downloads público
      final filePath = await _saveFileToDownloads(tempFile, fileName);
      final file = File(filePath);

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

// Tarjeta de registro en el historial
class _DriverHistoryCard extends StatelessWidget {
  final DriverHistoryRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  const _DriverHistoryCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
                    child: const Icon(Icons.person, color: Color(0xFF17A2B8)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.name.isEmpty
                              ? AppLocalizations.of(context).noName
                              : record.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          dateFormat.format(record.date),
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
                    tooltip: AppLocalizations.of(context).delete,
                  ),
                ],
              ),
              if (record.phone.isNotEmpty || record.email.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (record.phone.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                if (record.email.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
              ],
              if (record.photos.isNotEmpty || record.pdfs.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (record.photos.isNotEmpty) ...[
                      const Icon(
                        Icons.photo_library,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.photos.length} ${record.photos.length == 1 ? AppLocalizations.of(context).photoSingular : AppLocalizations.of(context).photosPlural}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (record.pdfs.isNotEmpty) ...[
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.pdfs.length} ${record.pdfs.length == 1 ? AppLocalizations.of(context).pdfSingular : AppLocalizations.of(context).pdfsPlural}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
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
                      label: Text(AppLocalizations.of(context).share),
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
                      label: Text(
                        AppLocalizations.of(context).downloadReportZip,
                      ),
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
}

// Pantalla de visualización de registro (solo lectura)
class _DriverRecordViewerScreen extends StatelessWidget {
  final DriverHistoryRecord record;
  final String vehicleId;

  const _DriverRecordViewerScreen({
    required this.record,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).driverRecordTitle),
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
                        AppLocalizations.of(context).driverRecordBannerTitle(
                          dateFormat.format(record.date),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).readOnlyCannotModify,
                        style: TextStyle(
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
          // Contenido
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 20),
                  if (record.photos.isNotEmpty) ...[
                    _buildPhotosSection(context),
                    const SizedBox(height: 20),
                  ],
                  if (record.pdfs.isNotEmpty) ...[
                    _buildPdfsSection(context),
                    const SizedBox(height: 20),
                  ],
                  if (record.notes.isNotEmpty) _buildNotesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).driverInformationTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.person,
              AppLocalizations.of(context).name,
              record.name,
            ),
            if (record.phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.phone,
                AppLocalizations.of(context).phoneLabel,
                record.phone,
              ),
            ],
            if (record.email.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                Icons.email,
                AppLocalizations.of(context).emailLabel,
                record.email,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF17A2B8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                value.isEmpty
                    ? AppLocalizations.of(context).notSpecified
                    : value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).photos,
          style: TextStyle(
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
            itemCount: record.photos.length,
            itemBuilder: (context, index) {
              final photoUrl = record.photos[index];
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoGalleryViewer(
                            initialIndex: index,
                            photoUrls: record.photos,
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
                      onTap: () => _downloadPhoto(context, photoUrl),
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

  Widget _buildPdfsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).pdfDocuments,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        ...record.pdfs.asMap().entries.map((entry) {
          final index = entry.key;
          final pdfUrl = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(
                AppLocalizations.of(context).pdfDocumentNumber(index + 1),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.open_in_new,
                      color: Color(0xFF17A2B8),
                    ),
                    onPressed: () => _openPdf(context, pdfUrl),
                    tooltip: AppLocalizations.of(context).openPdf,
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF17A2B8)),
                    onPressed: () => _downloadPdf(context, pdfUrl, index),
                    tooltip: AppLocalizations.of(context).downloadPdf,
                  ),
                ],
              ),
              dense: true,
            ),
          );
        }),
      ],
    );
  }

  static Future<void> _downloadPhoto(
    BuildContext context,
    String photoUrl,
  ) async {
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
          if (context.mounted) {
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
        final fileName = 'conductor_foto_$timestamp.jpg';
        final tempFilePath = '${tempDir.path}/$fileName';

        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Copiar a Downloads público
        await _saveFileToDownloads(tempFile, fileName);

        if (context.mounted) {
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
      if (context.mounted) {
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

  static Future<void> _openPdf(BuildContext context, String pdfUrl) async {
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
        final fileName = 'documento_conductor_$timestamp.pdf';
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Abrir el PDF con la aplicación predeterminada del sistema
        final opened = await NativeHelper.openFile(filePath);

        if (context.mounted) {
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
      if (context.mounted) {
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

  static Future<void> _downloadPdf(
    BuildContext context,
    String pdfUrl,
    int index,
  ) async {
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
          if (context.mounted) {
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

      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode == 200) {
        // Guardar en directorio temporal primero
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'conductor_documento_${index + 1}_$timestamp.pdf';
        final tempFilePath = '${tempDir.path}/$fileName';

        final tempFile = File(tempFilePath);
        await tempFile.writeAsBytes(response.bodyBytes);

        // Copiar a Downloads público
        await _saveFileToDownloads(tempFile, fileName);

        if (context.mounted) {
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
      if (context.mounted) {
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

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).notesLabel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              record.notes,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
