import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/document_section.dart';
import '../widgets/document_section_tab.dart';
import '../widgets/driver_section_tab.dart';
import '../widgets/maintenance_section_tab.dart';
import '../services/vehicle_service.dart';
import '../l10n/app_localizations.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Vehicle _vehicle;
  final VehicleService _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle(Vehicle updatedVehicle) async {
    setState(() {
      _vehicle = updatedVehicle;
    });
    await _vehicleService.updateVehicle(updatedVehicle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17A2B8), Color(0xFF0088CC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con información del vehículo
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Botón volver
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context);
                              return Text(
                                l10n.backToFleet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Icono y datos del vehículo
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _vehicle.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_vehicle.brand} ${_vehicle.model}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_vehicle.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                _vehicle.plate,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      indicator: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFF17A2B8),
                          width: 2,
                        ),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: [
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTabWithStatus(
                              l10n.otherDocuments,
                              Icons.folder_open,
                              _vehicle.otherDocuments,
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTabWithStatus(
                              l10n.ecologicalSticker,
                              Icons.eco,
                              _vehicle.ecologicalSticker,
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTabWithStatus(
                              l10n.insurance,
                              Icons.shield,
                              _vehicle.insurance,
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTabWithStatus(
                              l10n.circulationCard,
                              Icons.credit_card,
                              _vehicle.circulationCard,
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTab(l10n.contract, Icons.description);
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTab(l10n.driver, Icons.person);
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildTab(l10n.maintenance, Icons.build);
                          },
                        ),
                      ],
                    ),
                    // Indicador visual de deslizamiento
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.swipeToSeeMore,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: 16,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido de las tabs
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Otros documentos
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return DocumentSectionTab(
                            title: l10n.otherDocuments,
                            section: _vehicle.otherDocuments,
                            vehicleId: _vehicle.id,
                            sectionName: 'otros_documentos',
                            onUpdate: (updatedSection) {
                              _updateVehicle(
                                _vehicle.copyWith(
                                  otherDocuments: updatedSection,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Engomado ecológico
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return DocumentSectionTab(
                            title: l10n.ecologicalSticker,
                            section: _vehicle.ecologicalSticker,
                            vehicleId: _vehicle.id,
                            sectionName: 'engomado_ecologico',
                            onUpdate: (updatedSection) {
                              _updateVehicle(
                                _vehicle.copyWith(
                                  ecologicalSticker: updatedSection,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Seguro
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return DocumentSectionTab(
                            title: l10n.insurance,
                            section: _vehicle.insurance,
                            vehicleId: _vehicle.id,
                            sectionName: 'seguro',
                            onUpdate: (updatedSection) {
                              _updateVehicle(
                                _vehicle.copyWith(insurance: updatedSection),
                              );
                            },
                          );
                        },
                      ),
                      // Tarjeta de Circulación
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return DocumentSectionTab(
                            title: l10n.circulationCard,
                            section: _vehicle.circulationCard,
                            vehicleId: _vehicle.id,
                            sectionName: 'tarjeta_circulacion',
                            onUpdate: (updatedSection) {
                              _updateVehicle(
                                _vehicle.copyWith(
                                  circulationCard: updatedSection,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Contrato
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return DocumentSectionTab(
                            title: l10n.contract,
                            section: _vehicle.contract,
                            vehicleId: _vehicle.id,
                            sectionName: 'contrato',
                            onUpdate: (updatedSection) {
                              _updateVehicle(
                                _vehicle.copyWith(contract: updatedSection),
                              );
                            },
                          );
                        },
                      ),
                      // Conductor
                      DriverSectionTab(
                        driver: _vehicle.driver,
                        vehicleId: _vehicle.id,
                        onUpdate: (updatedDriver) {
                          _updateVehicle(
                            _vehicle.copyWith(driver: updatedDriver),
                          );
                        },
                      ),
                      // Mantenimiento
                      MaintenanceSectionTab(
                        vehicle: _vehicle,
                        onUpdate: _updateVehicle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, IconData icon) {
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(text)],
      ),
    );
  }

  Widget _buildTabWithStatus(
    String text,
    IconData icon,
    DocumentSection section,
  ) {
    Widget? statusBadge;

    if (section.expirationDate != null) {
      if (section.isExpired) {
        statusBadge = Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.error, size: 12, color: Colors.white),
        );
      } else if (section.isExpiringSoon) {
        statusBadge = Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warning, size: 12, color: Colors.white),
        );
      }
    }

    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text),
          if (statusBadge != null) statusBadge,
        ],
      ),
    );
  }
}
