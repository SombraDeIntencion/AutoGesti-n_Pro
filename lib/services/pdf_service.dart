import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/vehicle.dart';
import '../models/checklist_item.dart';
import '../models/inspection_record.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// Servicio para generar PDFs de reportes de inspección
class PdfService {
  /// Genera un PDF del reporte de inspección
  Future<File> generateInspectionReport(
    Vehicle vehicle,
    InspectionRecord inspection,
  ) async {
    final pdf = pw.Document();

    // Cargar imágenes de red si existen
    final List<pw.MemoryImage> inspectionImages = [];
    for (final photoUrl in inspection.inspectionPhotos) {
      try {
        final image = await _loadNetworkImage(photoUrl);
        if (image != null) {
          inspectionImages.add(image);
        }
      } catch (e) {
        // Error cargando imagen - continuar sin ella
      }
    }

    // Cargar fotos de componentes del checklist
    final Map<String, List<pw.MemoryImage>> componentPhotos = {};
    for (final item in inspection.checklist) {
      if (item.photos.isNotEmpty) {
        final List<pw.MemoryImage> itemImages = [];
        for (final photoUrl in item.photos) {
          try {
            final image = await _loadNetworkImage(photoUrl);
            if (image != null) {
              itemImages.add(image);
            }
          } catch (e) {
            // Error cargando foto - continuar sin ella
          }
        }
        if (itemImages.isNotEmpty) {
          componentPhotos[item.name] = itemImages;
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Encabezado
          _buildHeader(vehicle, inspection),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 20),

          // Información del vehículo
          _buildVehicleInfo(vehicle),
          pw.SizedBox(height: 20),

          // Fotos de inspección general
          if (inspectionImages.isNotEmpty) ...[
            _buildSectionTitle('Fotos de Inspección General'),
            pw.SizedBox(height: 10),
            _buildPhotoGrid(inspectionImages),
            pw.SizedBox(height: 20),
          ],

          // Checklist por categorías
          _buildSectionTitle('Checklist de Inspección'),
          pw.SizedBox(height: 10),
          _buildChecklistByCategory(inspection.checklist, 'INTERIOR/EXTERIOR', [
            ChecklistCategory.interior,
            ChecklistCategory.exterior,
          ]),
          pw.SizedBox(height: 10),
          _buildChecklistByCategory(inspection.checklist, 'BAJO EL CAPÓ', [
            ChecklistCategory.underhood,
          ]),
          pw.SizedBox(height: 10),
          _buildChecklistByCategory(inspection.checklist, 'NEUMÁTICOS', [
            ChecklistCategory.tires,
          ]),

          // Notas adicionales
          if (inspection.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Notas Adicionales'),
            pw.SizedBox(height: 10),
            pw.Text(inspection.notes, style: const pw.TextStyle(fontSize: 11)),
          ],

          // Fotos de componentes del checklist
          if (componentPhotos.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSectionTitle('Fotos Detalladas por Componente'),
            pw.SizedBox(height: 15),
            ..._buildComponentPhotosSection(componentPhotos),
          ],

          // Footer
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    // Guardar el PDF
    final output = await getTemporaryDirectory();
    final fileName =
        'inspeccion_${vehicle.brand}_${vehicle.model}_${DateFormat('yyyyMMdd_HHmmss').format(inspection.date)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Encabezado del reporte
  pw.Widget _buildHeader(Vehicle vehicle, InspectionRecord inspection) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REPORTE DE INSPECCIÓN VEHICULAR',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${vehicle.brand} ${vehicle.model}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(inspection.date)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Hora: ${DateFormat('HH:mm').format(inspection.date)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'ID: ${inspection.id.substring(0, 8)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  /// Información del vehículo
  pw.Widget _buildVehicleInfo(Vehicle vehicle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL VEHÍCULO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Marca', vehicle.brand),
              _buildInfoItem('Modelo', vehicle.model),
              _buildInfoItem('Año', vehicle.year.toString()),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('Placa', vehicle.plate),
              _buildInfoItem('Nombre', vehicle.name),
              pw.SizedBox(width: 100),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Título de sección
  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  /// Grid de fotos
  pw.Widget _buildPhotoGrid(List<pw.MemoryImage> images) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: images.take(6).map((image) {
        return pw.Container(
          width: 150,
          height: 150,
          child: pw.Image(image, fit: pw.BoxFit.cover),
        );
      }).toList(),
    );
  }

  /// Checklist por categoría
  pw.Widget _buildChecklistByCategory(
    List<ChecklistItem> allItems,
    String categoryTitle,
    List<ChecklistCategory> categories,
  ) {
    final items = allItems
        .where((item) => categories.contains(item.category))
        .toList();

    if (items.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            categoryTitle,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey700),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellHeight: 25,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
          },
          headers: ['Componente', 'Estado', 'Fotos'],
          data: items.map((item) {
            return [
              item.name,
              _getStatusText(item.status),
              item.photos.length.toString(),
            ];
          }).toList(),
        ),
      ],
    );
  }

  String _getStatusText(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.ok:
        return 'OK';
      case ChecklistStatus.attention:
        return 'Atencion';
      case ChecklistStatus.urgent:
        return 'Urgente';
    }
  }

  /// Footer del documento
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Reporte generado automáticamente - AutoGesti�n Max',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Text(
          'Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  /// Construir sección de fotos por componente
  List<pw.Widget> _buildComponentPhotosSection(
    Map<String, List<pw.MemoryImage>> componentPhotos,
  ) {
    final List<pw.Widget> widgets = [];

    componentPhotos.forEach((componentName, images) {
      widgets.addAll([
        // Nombre del componente
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Row(
            children: [
              pw.Container(width: 4, height: 16, color: PdfColors.blue900),
              pw.SizedBox(width: 8),
              pw.Text(
                componentName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                '${images.length} foto${images.length != 1 ? 's' : ''}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Grid de fotos del componente
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images.map((image) {
            return pw.Container(
              width: 170,
              height: 170,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),
            );
          }).toList(),
        ),
        pw.SizedBox(height: 15),
      ]);
    });

    return widgets;
  }

  /// Cargar imagen desde URL
  Future<pw.MemoryImage?> _loadNetworkImage(String url) async {
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return pw.MemoryImage(response.bodyBytes);
        }
      } else {
        // Es un archivo local
        final file = File(url);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return pw.MemoryImage(bytes);
        }
      }
    } catch (e) {
      // Error cargando imagen - retornar null
    }
    return null;
  }
}
