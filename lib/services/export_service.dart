import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '../models/vehicle.dart';
import 'package:intl/intl.dart';
import 'pdf_service.dart';

/// Servicio para exportar reportes de vehículos en archivos ZIP
class ExportService {
  final PdfService _pdfService = PdfService();

  /// Generar reporte consolidado de múltiples vehículos como ZIP
  Future<File> generateConsolidatedReport({
    required List<Vehicle> vehicles,
    required DateTime startDate,
    required DateTime endDate,
    required bool includeMaintenances,
    required bool includeInspections,
    required bool includeDocuments,
  }) async {
    final archive = Archive();
    final tempDir = await getTemporaryDirectory();
    int fileCounter = 0;

    // Procesar cada vehículo
    for (var vehicle in vehicles) {
      final vehicleName = _sanitizeFileName(vehicle.name);

      // 1. MANTENIMIENTOS - Generar PDFs
      if (includeMaintenances && vehicle.maintenance.sections.isNotEmpty) {
        for (var section in vehicle.maintenance.sections) {
          final items = section.items.where((item) {
            return item.date.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                item.date.isBefore(endDate.add(const Duration(days: 1)));
          }).toList();

          for (var item in items) {
            try {
              // Generar PDF para este registro de mantenimiento
              final pdfBytes = await _pdfService.generateMaintenancePdf(
                vehicle: vehicle,
                sectionName: section.name,
                maintenanceItem: item,
              );

              final pdfFileName =
                  'Mantenimientos/$vehicleName/${_sanitizeFileName(section.name)}_${_formatDateForFile(item.date)}.pdf';
              archive.addFile(
                ArchiveFile(pdfFileName, pdfBytes.length, pdfBytes),
              );
              fileCounter++;
            } catch (e) {
              debugPrint('Error generando PDF de mantenimiento: $e');
            }
          }
        }
      }

      // 2. INSPECCIONES - Generar PDFs y copiar fotos
      if (includeInspections &&
          vehicle.maintenance.inspectionHistory.isNotEmpty) {
        final inspections = vehicle.maintenance.inspectionHistory.where((insp) {
          return insp.date.isAfter(
                startDate.subtract(const Duration(days: 1)),
              ) &&
              insp.date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();

        for (var inspection in inspections) {
          final inspectionDate = _formatDateForFile(inspection.date);

          // Generar PDF del checklist de inspección
          try {
            final pdfBytes = await _pdfService.generateInspectionPdf(
              vehicle: vehicle,
              inspection: inspection,
            );

            final pdfFileName =
                'Inspecciones/$vehicleName/Checklist_$inspectionDate.pdf';
            archive.addFile(
              ArchiveFile(pdfFileName, pdfBytes.length, pdfBytes),
            );
            fileCounter++;
          } catch (e) {
            debugPrint('Error generando PDF de inspección: $e');
          }

          // Copiar fotos de la inspección
          for (var i = 0; i < inspection.inspectionPhotos.length; i++) {
            final photoPath = inspection.inspectionPhotos[i];
            final photoFile = File(photoPath);

            if (await photoFile.exists()) {
              try {
                final photoBytes = await photoFile.readAsBytes();
                final extension = photoPath.split('.').last;
                final photoFileName =
                    'Inspecciones/$vehicleName/Fotos_$inspectionDate/foto_${i + 1}.$extension';

                archive.addFile(
                  ArchiveFile(photoFileName, photoBytes.length, photoBytes),
                );
                fileCounter++;
              } catch (e) {
                debugPrint('Error copiando foto de inspección: $e');
              }
            }
          }
        }
      }

      // 3. DOCUMENTOS - Copiar archivos originales
      if (includeDocuments) {
        // Seguro
        await _addDocumentFiles(
          archive: archive,
          vehicleName: vehicleName,
          documentName: 'Seguro',
          photos: vehicle.insurance.photos,
          pdfs: vehicle.insurance.pdfs,
        );

        // Conductor
        await _addDocumentFiles(
          archive: archive,
          vehicleName: vehicleName,
          documentName: 'Conductor',
          photos: vehicle.driver.photos,
          pdfs: vehicle.driver.pdfs,
        );

        // Tarjeta de Circulación
        await _addDocumentFiles(
          archive: archive,
          vehicleName: vehicleName,
          documentName: 'Tarjeta_Circulacion',
          photos: vehicle.circulationCard.photos,
          pdfs: vehicle.circulationCard.pdfs,
        );

        // Contrato
        await _addDocumentFiles(
          archive: archive,
          vehicleName: vehicleName,
          documentName: 'Contrato',
          photos: vehicle.contract.photos,
          pdfs: vehicle.contract.pdfs,
        );

        // Calcomanía Ecológica
        await _addDocumentFiles(
          archive: archive,
          vehicleName: vehicleName,
          documentName: 'Calcomania_Ecologica',
          photos: vehicle.ecologicalSticker.photos,
          pdfs: vehicle.ecologicalSticker.pdfs,
        );

        // Otros Documentos
        await _addDocumentFiles(
          archive: archive,
          vehicleName: vehicleName,
          documentName: 'Otros_Documentos',
          photos: vehicle.otherDocuments.photos,
          pdfs: vehicle.otherDocuments.pdfs,
        );
      }
    }

    // Si no hay archivos en el archive, agregar un archivo de texto indicándolo
    if (archive.isEmpty) {
      final message =
          'No se encontraron archivos en el rango de fechas seleccionado.\nPer\u00edodo: ${_formatDateReadable(startDate)} - ${_formatDateReadable(endDate)}';
      final messageBytes = message.codeUnits;
      archive.addFile(
        ArchiveFile('README.txt', messageBytes.length, messageBytes),
      );
    }

    // Guardar el archivo ZIP
    final zipFileName =
        'reportes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip';
    final zipFilePath = '${tempDir.path}/$zipFileName';

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    if (zipData != null) {
      final zipFile = File(zipFilePath);
      await zipFile.writeAsBytes(zipData);
      debugPrint('ZIP generado: $zipFilePath con $fileCounter archivos');
      return zipFile;
    } else {
      throw Exception('Error al crear el archivo ZIP');
    }
  }

  /// Agregar archivos de un documento al archive
  Future<void> _addDocumentFiles({
    required Archive archive,
    required String vehicleName,
    required String documentName,
    required List<String> photos,
    required List<String> pdfs,
  }) async {
    // Copiar fotos
    for (var i = 0; i < photos.length; i++) {
      final photoPath = photos[i];
      final photoFile = File(photoPath);

      if (await photoFile.exists()) {
        try {
          final photoBytes = await photoFile.readAsBytes();
          final extension = photoPath.split('.').last;
          final photoFileName =
              'Documentos/$vehicleName/$documentName/Fotos/foto_${i + 1}.$extension';

          archive.addFile(
            ArchiveFile(photoFileName, photoBytes.length, photoBytes),
          );
        } catch (e) {
          debugPrint('Error copiando foto de documento: $e');
        }
      }
    }

    // Copiar PDFs
    for (var i = 0; i < pdfs.length; i++) {
      final pdfPath = pdfs[i];
      final pdfFile = File(pdfPath);

      if (await pdfFile.exists()) {
        try {
          final pdfBytes = await pdfFile.readAsBytes();
          final extension = pdfPath.split('.').last;
          final pdfFileName =
              'Documentos/$vehicleName/$documentName/PDFs/documento_${i + 1}.$extension';

          archive.addFile(ArchiveFile(pdfFileName, pdfBytes.length, pdfBytes));
        } catch (e) {
          debugPrint('Error copiando PDF de documento: $e');
        }
      }
    }
  }

  /// Sanitizar nombre de archivo para evitar caracteres inválidos
  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(' ', '_')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ñ', 'N');
  }

  /// Formatear fecha para nombre de archivo
  String _formatDateForFile(DateTime date) {
    return DateFormat('yyyyMMdd_HHmmss').format(date);
  }

  /// Formatear fecha legible
  String _formatDateReadable(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
