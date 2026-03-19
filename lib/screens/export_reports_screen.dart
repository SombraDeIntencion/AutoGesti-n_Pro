import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';

/// Pantalla para exportar reportes de vehículos en PDF
class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final VehicleService _vehicleService = VehicleService();
  final ExportService _exportService = ExportService();

  // Estados
  bool _selectAllVehicles = true;
  Set<String> _selectedVehicleIds = {};
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  // Tipos de reportes
  bool _includeMaintenances = true;
  bool _includeInspections = true;
  bool _includeDocuments = true;

  bool _isLoading = false;
  List<Vehicle> _vehicles = [];
  bool _isLoadingVehicles = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehiclesStream = _vehicleService.getVehicles();
      final vehicles = await vehiclesStream.first;
      setState(() {
        _vehicles = vehicles;
        _selectedVehicleIds = vehicles.map((v) => v.id).toSet();
        _isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() => _isLoadingVehicles = false);
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: _endDate,
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _generateReport() async {
    final l10n = AppLocalizations.of(context);

    if (_selectedVehicleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOneVehicle),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_includeMaintenances && !_includeInspections && !_includeDocuments) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOneReportType),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Filtrar vehículos seleccionados
      final selectedVehicles = _vehicles
          .where((v) => _selectedVehicleIds.contains(v.id))
          .toList();

      // Generar PDF
      final pdfFile = await _exportService.generateConsolidatedReport(
        vehicles: selectedVehicles,
        startDate: _startDate,
        endDate: _endDate,
        includeMaintenances: _includeMaintenances,
        includeInspections: _includeInspections,
        includeDocuments: _includeDocuments,
      );

      if (mounted) setState(() => _isLoading = false);

      // Compartir PDF
      await Share.shareXFiles([
        XFile(pdfFile.path),
      ], text: l10n.fleetReportAutogestionMax);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorGeneratingReport}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoadingVehicles) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.exportReports),
          backgroundColor: const Color(0xFF0088CC),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_vehicles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.exportReports),
          backgroundColor: const Color(0xFF0088CC),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.drive_eta_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noVehiclesRegistered,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.addVehiclesToGenerateReports,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    final selectedCount = _selectedVehicleIds.length;
    final reportTypesCount =
        (_includeMaintenances ? 1 : 0) +
        (_includeInspections ? 1 : 0) +
        (_includeDocuments ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportReports),
        backgroundColor: const Color(0xFF0088CC),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ayuda
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0088CC).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0088CC).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF0088CC),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.generateConsolidatedPDFReport,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Seleccionar Vehículos
                _buildSectionTitle(
                  '1. ${l10n.selectVehicles}',
                  Icons.drive_eta,
                ),
                const SizedBox(height: 12),
                _buildVehicleSelector(l10n),
                const SizedBox(height: 24),

                // 2. Rango de Fechas
                _buildSectionTitle(
                  '2. ${l10n.dateRange}',
                  Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _buildDateRangePicker(l10n),
                const SizedBox(height: 24),

                // 3. Tipo de Reportes
                _buildSectionTitle('3. ${l10n.reportTypes}', Icons.checklist),
                const SizedBox(height: 12),
                _buildReportTypeSelector(l10n),
                const SizedBox(height: 24),

                // Resumen
                _buildSummary(l10n, selectedCount, reportTypesCount),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Botón flotante
          if (!_isLoading)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: ElevatedButton(
                onPressed: _generateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.file_download, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      l10n.exportReportsButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        l10n.generatingReport,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.pleaseWait,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0088CC), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0088CC),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelector(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: _selectAllVehicles,
            onChanged: (value) {
              setState(() {
                _selectAllVehicles = value ?? true;
                if (_selectAllVehicles) {
                  _selectedVehicleIds = _vehicles.map((v) => v.id).toSet();
                } else {
                  _selectedVehicleIds.clear();
                }
              });
            },
            title: Text(
              l10n.allVehicles,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${_vehicles.length} ${l10n.vehiclesAvailable}'),
            activeColor: const Color(0xFF0088CC),
          ),
          if (!_selectAllVehicles) ...[
            const Divider(height: 1),
            ..._vehicles.map((vehicle) {
              final isSelected = _selectedVehicleIds.contains(vehicle.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedVehicleIds.add(vehicle.id);
                    } else {
                      _selectedVehicleIds.remove(vehicle.id);
                    }
                  });
                },
                title: Text(vehicle.name),
                subtitle: Text('${vehicle.brand} ${vehicle.model}'),
                activeColor: const Color(0xFF0088CC),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangePicker(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Fecha inicio
          InkWell(
            onTap: _selectStartDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFF0088CC)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.from,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(_startDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fecha fin
          InkWell(
            onTap: _selectEndDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFF0088CC)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.to,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatDate(_endDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeSelector(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: _includeMaintenances,
            onChanged: (value) {
              setState(() => _includeMaintenances = value ?? true);
            },
            title: Text(l10n.maintenances),
            subtitle: Text(l10n.maintenanceHistory),
            activeColor: const Color(0xFF0088CC),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            value: _includeInspections,
            onChanged: (value) {
              setState(() => _includeInspections = value ?? true);
            },
            title: Text(l10n.inspections),
            subtitle: Text(l10n.checklistReports),
            activeColor: const Color(0xFF0088CC),
          ),
          const Divider(height: 1),
          CheckboxListTile(
            value: _includeDocuments,
            onChanged: (value) {
              setState(() => _includeDocuments = value ?? true);
            },
            title: Text(l10n.documents),
            subtitle: Text(l10n.insuranceDriverCirculation),
            activeColor: const Color(0xFF0088CC),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    AppLocalizations l10n,
    int selectedCount,
    int reportTypesCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0088CC).withValues(alpha: 0.1),
            const Color(0xFF17A2B8).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0088CC).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.summarize, color: Color(0xFF0088CC), size: 32),
          const SizedBox(height: 12),
          Text(
            l10n.reportWillBeGenerated,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            '$selectedCount ${selectedCount != 1 ? l10n.vehiclesPlural : l10n.vehicleSingular}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0088CC),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$reportTypesCount ${reportTypesCount != 1 ? l10n.reportTypesPlural : l10n.reportTypeSingular}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
