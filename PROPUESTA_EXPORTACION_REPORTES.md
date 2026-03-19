# 📊 PROPUESTA: Exportación de Reportes en PDF
## AutoGestión Max - Feature de Valor Agregado

**Fecha:** 7 de febrero de 2026
**Estado:** Propuesta

---

## 🎯 OBJETIVO

Implementar una funcionalidad sencilla que permita a usuarios con múltiples vehículos exportar sus reportes guardados como PDF, con opciones de:
- ✅ Seleccionar vehículos (todos o algunos)
- ✅ Filtrar por rango de fechas
- ✅ Elegir tipos de reportes
- ✅ Descargar como PDF único o comprimido

---

## 💡 VALOR PARA EL USUARIO

### ¿Por qué es importante?

1. **Para usuarios con pocos vehículos (1-5):**
   - Pueden compartir reportes individuales fácilmente
   - Respaldo simple de información

2. **Para usuarios con muchos vehículos (6-50):**
   - Exportación masiva para auditorías
   - Reportes consolidados para contabilidad
   - Respaldo periódico organizado

3. **Uso práctico:**
   - Presentar a seguros después de accidente
   - Auditorías internas
   - Declaraciones fiscales
   - Traspaso de vehículos

---

## 🎨 DISEÑO PROPUESTO

### Pantalla: "Exportar Reportes"

```
┌─────────────────────────────────────┐
│  ← Exportar Reportes          [?]   │
├─────────────────────────────────────┤
│                                     │
│  📋 1. Seleccionar Vehículos        │
│  ┌─────────────────────────────┐   │
│  │ [✓] Todos los vehículos     │   │
│  │ [ ] Selección personalizada │   │
│  └─────────────────────────────┘   │
│                                     │
│  📅 2. Rango de Fechas             │
│  ┌─────────────────────────────┐   │
│  │ Desde: [01/01/2026     ] 📅│   │
│  │ Hasta: [07/02/2026     ] 📅│   │
│  └─────────────────────────────┘   │
│                                     │
│  📂 3. Tipo de Reportes            │
│  ┌─────────────────────────────┐   │
│  │ [✓] Mantenimientos          │   │
│  │ [✓] Gastos                  │   │
│  │ [✓] Inspecciones            │   │
│  │ [ ] Documentos vencidos     │   │
│  └─────────────────────────────┘   │
│                                     │
│  📦 4. Formato de Salida           │
│  ┌─────────────────────────────┐   │
│  │ ( ) PDF individual por      │   │
│  │     vehículo                │   │
│  │ (•) PDF consolidado (todos) │   │
│  │ ( ) ZIP con PDFs separados  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   📥 GENERAR REPORTES       │   │
│  └─────────────────────────────┘   │
│                                     │
│  💡 Se generarán 3 reportes de     │
│     5 vehículos (01/01-07/02)      │
└─────────────────────────────────────┘
```

---

## 🔧 IMPLEMENTACIÓN TÉCNICA

### Fase 1: Estructura Básica (4-6 horas)

#### 1.1 Nueva Pantalla de Exportación

**Archivo:** `lib/screens/export_reports_screen.dart`

```dart
class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  // Estados
  bool _allVehicles = true;
  List<String> _selectedVehicleIds = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  
  // Tipos de reportes
  bool _includeMaintenances = true;
  bool _includeExpenses = true;
  bool _includeInspections = true;
  bool _includeExpiredDocuments = false;
  
  // Formato
  String _exportFormat = 'consolidated'; // 'individual', 'consolidated', 'zip'
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar Reportes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleSelector(),
            _buildDateRangePicker(),
            _buildReportTypeSelector(),
            _buildFormatSelector(),
            _buildGenerateButton(),
            _buildSummary(),
          ],
        ),
      ),
    );
  }
}
```

#### 1.2 Servicio de Exportación

**Archivo:** `lib/services/export_service.dart`

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

class ExportService {
  /// Generar reporte consolidado de múltiples vehículos
  Future<File> generateConsolidatedReport({
    required List<Vehicle> vehicles,
    required DateTime startDate,
    required DateTime endDate,
    required ExportOptions options,
  }) async {
    final pdf = pw.Document();
    
    // Portada
    pdf.addPage(_buildCoverPage(vehicles.length, startDate, endDate));
    
    // Índice
    pdf.addPage(_buildIndexPage(vehicles));
    
    // Reporte por cada vehículo
    for (var vehicle in vehicles) {
      if (options.includeMaintenances) {
        pdf.addPage(_buildMaintenancePage(vehicle, startDate, endDate));
      }
      
      if (options.includeExpenses) {
        pdf.addPage(_buildExpensesPage(vehicle, startDate, endDate));
      }
      
      if (options.includeInspections) {
        pdf.addPage(_buildInspectionsPage(vehicle, startDate, endDate));
      }
    }
    
    // Resumen final
    if (options.includeSummary) {
      pdf.addPage(_buildSummaryPage(vehicles, startDate, endDate));
    }
    
    // Guardar archivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/reporte_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }
  
  /// Generar PDFs individuales por vehículo
  Future<List<File>> generateIndividualReports({
    required List<Vehicle> vehicles,
    required DateTime startDate,
    required DateTime endDate,
    required ExportOptions options,
  }) async {
    final files = <File>[];
    
    for (var vehicle in vehicles) {
      final pdf = pw.Document();
      
      // Agregar páginas según opciones
      if (options.includeMaintenances) {
        pdf.addPage(_buildMaintenancePage(vehicle, startDate, endDate));
      }
      // ... más páginas
      
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_${vehicle.name}.pdf');
      await file.writeAsBytes(await pdf.save());
      files.add(file);
    }
    
    return files;
  }
  
  /// Generar ZIP con múltiples PDFs
  Future<File> generateZipReport({
    required List<Vehicle> vehicles,
    required DateTime startDate,
    required DateTime endDate,
    required ExportOptions options,
  }) async {
    // 1. Generar PDFs individuales
    final pdfFiles = await generateIndividualReports(
      vehicles: vehicles,
      startDate: startDate,
      endDate: endDate,
      options: options,
    );
    
    // 2. Comprimir en ZIP
    final encoder = ZipEncoder();
    final output = await getTemporaryDirectory();
    final zipFile = File('${output.path}/reportes_${DateTime.now().millisecondsSinceEpoch}.zip');
    
    final archive = Archive();
    for (var file in pdfFiles) {
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(
        basename(file.path),
        bytes.length,
        bytes,
      ));
    }
    
    final zipData = encoder.encode(archive);
    await zipFile.writeAsBytes(zipData);
    
    // 3. Limpiar PDFs temporales
    for (var file in pdfFiles) {
      await file.delete();
    }
    
    return zipFile;
  }
  
  // Métodos privados para construir páginas del PDF
  pw.Page _buildCoverPage(int vehicleCount, DateTime start, DateTime end) {
    return pw.Page(
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'REPORTE DE FLOTILLA',
              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('$vehicleCount Vehículos', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            pw.Text(
              'Período: ${_formatDate(start)} - ${_formatDate(end)}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              'Generado por AutoGestión Max',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
            pw.Text(
              'Fecha: ${_formatDate(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ),
    );
  }
  
  pw.Page _buildIndexPage(List<Vehicle> vehicles) {
    return pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ÍNDICE DE VEHÍCULOS',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          ...vehicles.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final vehicle = entry.value;
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Row(
                children: [
                  pw.Text('$index.', style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    '${vehicle.brand} ${vehicle.model} - ${vehicle.plate}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  // ... más métodos para construir páginas
}

class ExportOptions {
  final bool includeMaintenances;
  final bool includeExpenses;
  final bool includeInspections;
  final bool includeExpiredDocuments;
  final bool includeSummary;
  
  const ExportOptions({
    this.includeMaintenances = true,
    this.includeExpenses = true,
    this.includeInspections = true,
    this.includeExpiredDocuments = false,
    this.includeSummary = true,
  });
}
```

---

## 📦 DEPENDENCIAS REQUERIDAS

**Archivo:** `pubspec.yaml`

```yaml
dependencies:
  # Ya existen:
  pdf: ^3.10.4
  path_provider: ^2.0.15
  share_plus: ^7.0.2
  
  # NUEVA (solo si usas ZIP):
  archive: ^3.4.10  # Para comprimir archivos
```

---

## 🎯 CARACTERÍSTICAS POR IMPLEMENTAR

### Nivel 1: Básico (4-6 horas)
- [x] Pantalla de selección
- [x] Generar PDF consolidado simple
- [x] Compartir PDF
- [ ] Selector de vehículos
- [ ] Selector de fechas
- [ ] Checkboxes de tipos de reporte

### Nivel 2: Intermedio (8-12 horas)
- [ ] PDFs con formato profesional
- [ ] Tablas de datos
- [ ] Gráficas simples (costos por mes)
- [ ] Filtros avanzados
- [ ] Previsualización

### Nivel 3: Avanzado (16-20 horas)
- [ ] Compresión ZIP
- [ ] Gráficas complejas
- [ ] Análisis de tendencias
- [ ] Exportación a Excel
- [ ] Programar reportes automáticos

---

## 📋 FLUJO DE USUARIO

```
1. Usuario va a "Mi Perfil" o menú principal
   ↓
2. Toca botón "📊 Exportar Reportes"
   ↓
3. Selecciona opciones:
   - ¿Todos los vehículos? Sí/No
   - Si No: aparece lista de checkboxes
   - Rango de fechas
   - Tipos de reporte
   - Formato (PDF único / ZIP)
   ↓
4. Toca "Generar Reportes"
   ↓
5. Loading: "Generando PDF..."
   ↓
6. Aparece diálogo de compartir
   ↓
7. Usuario guarda o comparte PDF
```

---

## 💰 ESTIMACIÓN DE ESFUERZO

### Implementación Mínima Viable (MVP)
**Tiempo:** 6-8 horas
**Incluye:**
- ✅ Pantalla básica de exportación
- ✅ Selección de todos los vehículos
- ✅ Rango de fechas simple
- ✅ PDF consolidado básico con texto
- ✅ Compartir PDF

**Costo estimado:** ~$2,400 - $3,200 MXN (a $400 MXN/hora)

### Implementación Completa
**Tiempo:** 16-20 horas
**Incluye todo lo del MVP +**
- ✅ Selección individual de vehículos
- ✅ PDFs con formato profesional
- ✅ Tablas y gráficas
- ✅ Exportación ZIP
- ✅ Filtros avanzados

**Costo estimado:** ~$6,400 - $8,000 MXN (a $400 MXN/hora)

---

## 🚀 PLAN DE IMPLEMENTACIÓN

### Sprint 1: MVP (1 semana)
**Día 1-2:** Pantalla de exportación básica
**Día 3-4:** Servicio de generación de PDF
**Día 5:** Integración y testing
**Día 6-7:** Refinamiento y correcciones

### Sprint 2: Mejoras (1 semana)
**Día 1-2:** Selector de vehículos individual
**Día 3-4:** Formato profesional del PDF
**Día 5:** Gráficas básicas
**Día 6-7:** Exportación ZIP

---

## 📊 ESTRUCTURA DEL PDF GENERADO

### PDF Consolidado - Ejemplo

```
════════════════════════════════════════
REPORTE DE FLOTILLA
5 Vehículos | 01/01/2026 - 07/02/2026
════════════════════════════════════════

ÍNDICE
1. Toyota Camry 2020 - ABC-123
2. Honda Civic 2021 - XYZ-789
3. Ford Explorer 2019 - DEF-456
...

════════════════════════════════════════
VEHÍCULO 1: TOYOTA CAMRY 2020
Placa: ABC-123
════════════════════════════════════════

MANTENIMIENTOS (Enero - Febrero 2026)
════════════════════════════════════════
Fecha       | Tipo              | Costo
────────────┼───────────────────┼─────────
15/01/2026  | Cambio de aceite  | $850
28/01/2026  | Rotación llantas  | $400
03/02/2026  | Alineación        | $350
────────────┴───────────────────┴─────────
TOTAL:                            $1,600

GASTOS
════════════════════════════════════════
[Tabla similar de gastos]

INSPECCIONES
════════════════════════════════════════
[Resultados de checklists]

════════════════════════════════════════
VEHÍCULO 2: HONDA CIVIC 2021
[... continúa con siguiente vehículo]

════════════════════════════════════════
RESUMEN GENERAL DE FLOTILLA
════════════════════════════════════════

Total de mantenimientos: 15
Total de gastos: $12,450
Promedio por vehículo: $2,490

Vehículo con más gastos: Toyota Camry ($4,200)
Vehículo con menos gastos: Ford Explorer ($1,100)

════════════════════════════════════════
Generado por AutoGestión Max v1.0.0
Fecha: 07/02/2026 14:35
════════════════════════════════════════
```

---

## 🎨 UBICACIÓN EN LA APP

### Opción 1: Desde Perfil (Recomendado)
```
Mi Perfil
├── Ver Planes
├── 📊 Exportar Reportes  ← NUEVO
├── Configuración
├── Exportar mis datos (texto)
└── Cerrar sesión
```

### Opción 2: Menú Principal
```
[≡] Menú
├── Mis Vehículos
├── Ver Planes
├── 📊 Reportes        ← NUEVO
│   ├── Ver Individual
│   └── Exportar Todos
└── Mi Perfil
```

### Opción 3: Icon en AppBar
```
┌────────────────────────────┐
│ AutoGestión Pro  🔔 📊 👤 │  ← Botón de reportes
└────────────────────────────┘
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Backend / Lógica
- [ ] Crear `ExportService`
- [ ] Método para PDF consolidado
- [ ] Método para PDFs individuales
- [ ] Método para ZIP
- [ ] Filtros por fecha
- [ ] Filtros por tipo de reporte
- [ ] Calcular estadísticas
- [ ] Formatear tablas

### UI / Frontend
- [ ] Crear `ExportReportsScreen`
- [ ] Selector de vehículos
- [ ] Date range picker
- [ ] Checkboxes de tipos
- [ ] Radio buttons de formato
- [ ] Botón de generar
- [ ] Loading indicator
- [ ] Diálogo de compartir
- [ ] Agregar navegación desde perfil

### Testing
- [ ] Test con 1 vehículo
- [ ] Test con 5 vehículos
- [ ] Test con 20 vehículos
- [ ] Test sin datos (vehículo nuevo)
- [ ] Test con rango de fechas grande
- [ ] Test de compartir PDF
- [ ] Test de compresión ZIP
- [ ] Test en Android/iOS

---

## 🎁 BENEFICIOS ADICIONALES

Esta funcionalidad puede usarse como **diferenciador de planes:**

### Sugerencia de Beneficio Honesto

```dart
// Small 6-8
features: [
  '6-8 vehículos',
  'Sincronización automática',
  'Alertas de vencimiento',
  'Respaldo en la nube',
]

// Medium 13-17
features: [
  '13-17 vehículos',
  'Todas las funciones básicas',
  'Espacio ampliado en nube',
  '📊 Exportación de reportes PDF', // ← NUEVO
]

// Large 24-30
features: [
  '24-30 vehículos',
  'Todas las funciones',
  'Almacenamiento premium',
  '📊 Exportación masiva + ZIP', // ← NUEVO
]
```

**Implementación:**
- FREE: Sin exportación (solo texto plano actual)
- Starter: Exportar 1 vehículo a la vez
- Small: Exportar hasta 3 vehículos
- Medium: Exportar todos, PDF consolidado
- Large: Exportar todos + ZIP
- Enterprise: Todo lo anterior + reportes programados

---

## 📈 PRÓXIMOS PASOS

### Decisión Requerida

**¿Quieres implementar esto ahora?**

**Opción A:** MVP básico (6-8 horas)
- Solo PDF consolidado
- Todos los vehículos
- Rango de fechas simple
- Sin ZIP

**Opción B:** Completo (16-20 horas)
- Selección individual
- PDF profesional
- Gráficas
- ZIP

**Opción C:** Posponer
- Lanzar app sin esta funcionalidad
- Implementar en próxima versión (v1.1.0)

---

**¿Cuál opción prefieres?** Puedo comenzar con la implementación inmediatamente.
