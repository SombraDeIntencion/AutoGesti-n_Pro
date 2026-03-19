import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/native_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/billing_service.dart';
import '../models/expense.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_localizations.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final BillingService _billingService = BillingService();
  final VehicleService _vehicleService = VehicleService();
  DateTime _selectedDate = DateTime.now();
  int _periodMode = 1; // 0=Año, 1=Mes, 2=Semana
  int _slideDirection = 1; // 1=siguiente (→), -1=anterior (←)
  late DateTime _selectedWeekStart = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }();

  // Filtros
  final Set<String> _selectedVehicleIds = {};
  final Set<ExpenseCategory> _selectedCategories = {};

  // Streams únicos — broadcast para soportar múltiples StreamBuilders simultáneos
  late final Stream<List<Expense>> _expensesStream = _billingService
      .getExpenses()
      .asBroadcastStream();
  late final Stream<List<Vehicle>> _vehiclesStream = _vehicleService
      .getVehicles()
      .asBroadcastStream();

  // Caché de vehículos para uso síncrono en diálogos
  List<Vehicle> _latestVehicles = [];
  StreamSubscription<List<Vehicle>>? _vehiclesSub;

  // Período seleccionado — usado en gráficas, resumen y lista
  DateTime get _firstDayOfMonth {
    switch (_periodMode) {
      case 0:
        return DateTime(_selectedDate.year, 1, 1);
      case 2:
        return _selectedWeekStart;
      case 3:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
      default:
        return DateTime(_selectedDate.year, _selectedDate.month, 1);
    }
  }

  DateTime get _lastDayOfMonth {
    switch (_periodMode) {
      case 0:
        return DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
      case 2:
        return _selectedWeekStart.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
      case 3:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          23,
          59,
          59,
        );
      default:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );
    }
  }

  String _periodDisplayLabel(String locale) {
    switch (_periodMode) {
      case 0:
        return '${_selectedDate.year}';
      case 2:
        final end = _selectedWeekStart.add(const Duration(days: 6));
        return '${DateFormat('dd/MM', locale).format(_selectedWeekStart)} – ${DateFormat('dd/MM', locale).format(end)}';
      case 3:
        return DateFormat('EEE d MMM', locale).format(_selectedDate);
      default:
        return DateFormat(
          'MMMM yyyy',
          locale,
        ).format(DateTime(_selectedDate.year, _selectedDate.month));
    }
  }

  @override
  void initState() {
    super.initState();
    _vehiclesSub = _vehiclesStream.listen((vehicles) {
      _latestVehicles = vehicles;
    });
  }

  @override
  void dispose() {
    _vehiclesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF17A2B8), // Cyan/turquesa
              Color(0xFF0088CC), // Azul
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título de la app
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido principal en scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Card destacado de Facturación y Gastos
                      _buildFeatureCard(),

                      const SizedBox(height: 20),

                      // Tarjetas de resumen
                      _buildSummaryCards(),

                      const SizedBox(height: 24),

                      // Gráfico de gastos por vehículo
                      _buildExpensesByVehicleChart(),

                      const SizedBox(height: 24),

                      // Gráfico de distribución por categoría
                      _buildExpensesByCategoryChart(),

                      const SizedBox(height: 24),

                      // Filtros
                      _buildFiltersSection(),

                      const SizedBox(height: 16),

                      // Botones de exportación
                      _buildExportButton(),

                      const SizedBox(height: 20),

                      // Lista de gastos recientes
                      _buildRecentExpensesList(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  // Card destacado de Facturación y Gastos
  Widget _buildFeatureCard() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.billingAndExpenses,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.billingDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Sección de filtros
  Widget _buildFiltersSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'public/images/iconfiltro.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.filters,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filtro de vehículo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.vehicleSingular,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Vehicle>>(
                stream: _vehiclesStream,
                builder: (context, snapshot) {
                  final vehicles = snapshot.data ?? [];
                  String buttonLabel() {
                    if (_selectedVehicleIds.isEmpty) {
                      return l10n.allVehicles;
                    }
                    if (_selectedVehicleIds.length == 1) {
                      final v = vehicles.firstWhere(
                        (v) => v.id == _selectedVehicleIds.first,
                        orElse: () => vehicles.first,
                      );
                      return v.name;
                    }
                    return '${_selectedVehicleIds.length} ${l10n.vehicles}';
                  }

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black26,
                        builder: (ctx) {
                          final searchCtrl = TextEditingController();
                          List<Vehicle> filtered = List.from(vehicles);
                          return StatefulBuilder(
                            builder: (ctx, setS) {
                              final bottomInset = MediaQuery.of(
                                ctx,
                              ).viewInsets.bottom;
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                insetPadding: EdgeInsets.fromLTRB(
                                  24,
                                  40,
                                  24,
                                  bottomInset + 16,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    16,
                                    0,
                                    8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Título
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          l10n.vehicles,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Barra de búsqueda
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: TextField(
                                          controller: searchCtrl,
                                          style: const TextStyle(fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: l10n.searchNamePlateBrand,
                                            hintStyle: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              size: 20,
                                            ),
                                            suffixIcon:
                                                searchCtrl.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                      size: 18,
                                                    ),
                                                    onPressed: () {
                                                      searchCtrl.clear();
                                                      setS(() {
                                                        filtered = List.from(
                                                          vehicles,
                                                        );
                                                      });
                                                    },
                                                  )
                                                : null,
                                            isDense: true,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                          ),
                                          onChanged: (q) {
                                            final query = q.toLowerCase();
                                            setS(() {
                                              filtered = vehicles.where((v) {
                                                return v.name
                                                        .toLowerCase()
                                                        .contains(query) ||
                                                    v.plate
                                                        .toLowerCase()
                                                        .contains(query) ||
                                                    v.brand
                                                        .toLowerCase()
                                                        .contains(query) ||
                                                    v.model
                                                        .toLowerCase()
                                                        .contains(query) ||
                                                    v.year.toString().contains(
                                                      query,
                                                    );
                                              }).toList();
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Opción "Todos"
                                      CheckboxListTile(
                                        dense: true,
                                        title: Text(l10n.allVehicles),
                                        value: _selectedVehicleIds.isEmpty,
                                        activeColor: const Color(0xFF17A2B8),
                                        onChanged: (_) {
                                          setS(() {
                                            _selectedVehicleIds.clear();
                                          });
                                        },
                                      ),
                                      const Divider(height: 1),
                                      // Lista scrollable
                                      SizedBox(
                                        height: bottomInset > 0 ? 140 : 220,
                                        child: filtered.isEmpty
                                            ? Center(
                                                child: Text(
                                                  l10n.noMatches,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                shrinkWrap: false,
                                                itemCount: filtered.length,
                                                itemBuilder: (_, i) {
                                                  final v = filtered[i];
                                                  final sel =
                                                      _selectedVehicleIds
                                                          .contains(v.id);
                                                  return CheckboxListTile(
                                                    dense: true,
                                                    activeColor: const Color(
                                                      0xFF17A2B8,
                                                    ),
                                                    value: sel,
                                                    title: Text(
                                                      v.name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      '${v.plate} · ${v.brand} ${v.model} ${v.year}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                    onChanged: (checked) {
                                                      setS(() {
                                                        if (checked!) {
                                                          _selectedVehicleIds
                                                              .add(v.id);
                                                          // Solo auto-limpiar si
                                                          // hay más de 1 vehículo
                                                          if (vehicles.length >
                                                                  1 &&
                                                              _selectedVehicleIds
                                                                      .length ==
                                                                  vehicles
                                                                      .length) {
                                                            _selectedVehicleIds
                                                                .clear();
                                                          }
                                                        } else {
                                                          _selectedVehicleIds
                                                              .remove(v.id);
                                                        }
                                                      });
                                                    },
                                                  );
                                                },
                                              ),
                                      ),
                                      // Botón Listo
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            4,
                                            12,
                                            4,
                                          ),
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(l10n.done),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              buttonLabel(),
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedVehicleIds.isEmpty
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filtro de categoría
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.categoryLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black26,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setS) => AlertDialog(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(
                          l10n.categoriesLabel,
                          style: const TextStyle(fontSize: 16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CheckboxListTile(
                              dense: true,
                              title: Text(l10n.allCategories),
                              value: _selectedCategories.isEmpty,
                              activeColor: const Color(0xFF17A2B8),
                              onChanged: (_) {
                                setS(() {
                                  _selectedCategories.clear();
                                });
                              },
                            ),
                            const Divider(height: 1),
                            ...ExpenseCategory.values.map((cat) {
                              return CheckboxListTile(
                                dense: true,
                                title: Text(_getCategoryName(cat)),
                                value: _selectedCategories.contains(cat),
                                activeColor: const Color(0xFF17A2B8),
                                onChanged: (checked) {
                                  setS(() {
                                    if (checked!) {
                                      _selectedCategories.add(cat);
                                      if (_selectedCategories.length ==
                                          ExpenseCategory.values.length) {
                                        _selectedCategories.clear();
                                      }
                                    } else {
                                      _selectedCategories.remove(cat);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.done),
                          ),
                        ],
                      ),
                    ),
                  ).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategories.isEmpty
                              ? l10n.allCategories
                              : _selectedCategories.length == 1
                              ? _getCategoryName(_selectedCategories.first)
                              : '${_selectedCategories.length} ${l10n.categoriesLabel}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedCategories.isEmpty
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Botones de exportación
  Widget _buildExportButton() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildExportChip(
          label: l10n.exportPdf,
          svgAsset: 'public/images/ic_pdf.svg',
          onTap: () => _showExportPicker(isPdf: true),
        ),
        const SizedBox(width: 10),
        _buildExportChip(
          label: l10n.exportExcel,
          svgAsset: 'public/images/ic_excel.svg',
          onTap: () => _showExportPicker(isPdf: false),
        ),
      ],
    );
  }

  Widget _buildExportChip({
    required String label,
    required String svgAsset,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        splashColor: Colors.white30,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF0E7490),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(svgAsset, width: 26, height: 26),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Avanza o retrocede el período activo un paso en la dirección dada.
  void _navigatePeriod(int direction) {
    _slideDirection = direction;
    setState(() {
      switch (_periodMode) {
        case 0: // Año
          _selectedDate = DateTime(
            _selectedDate.year + direction,
            _selectedDate.month,
          );
          break;
        case 1: // Mes
          var newMonth = _selectedDate.month + direction;
          var newYear = _selectedDate.year;
          if (newMonth < 1) {
            newMonth = 12;
            newYear--;
          } else if (newMonth > 12) {
            newMonth = 1;
            newYear++;
          }
          _selectedDate = DateTime(newYear, newMonth);
          break;
        case 2: // Semana
          _selectedWeekStart = _selectedWeekStart.add(
            Duration(days: 7 * direction),
          );
          break;
        case 3: // Día
          _selectedDate = _selectedDate.add(Duration(days: direction));
          break;
      }
    });
  }

  // Tarjetas de resumen
  Widget _buildSummaryCards() {
    return StreamBuilder<List<Expense>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final expenses = (snapshot.data ?? []).where((e) {
          if (e.date.isBefore(_firstDayOfMonth) ||
              e.date.isAfter(_lastDayOfMonth)) {
            return false;
          }
          if (_selectedVehicleIds.isNotEmpty &&
              !_selectedVehicleIds.contains(e.vehicleId)) {
            return false;
          }
          if (_selectedCategories.isNotEmpty &&
              !_selectedCategories.contains(e.category)) {
            return false;
          }
          return true;
        }).toList();
        final total = expenses.fold<double>(0.0, (s, e) => s + e.amount);
        final vehicles = expenses.map((e) => e.vehicleId).toSet().length;
        final categories = expenses.map((e) => e.category).toSet().length;
        final expenseCount = expenses.length;

        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final begin = _slideDirection > 0
                    ? const Offset(0.35, 0)
                    : const Offset(-0.35, 0);
                return SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset.zero)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(
                  '${_periodMode}_${_selectedDate.year}_${_selectedDate.month}_${_selectedDate.day}_${_selectedWeekStart.millisecondsSinceEpoch}',
                ),
                child: _buildSummaryCard(
                  l10n.totalPeriod(
                    _periodDisplayLabel(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  '\$${NumberFormat('#,##0.00').format(total)}',
                  l10n.expensesRegisteredN(expenseCount),
                  Icons.attach_money,
                  const Color(0xFF17A2B8),
                  isHighlighted: true,
                  onTap: () => _showPeriodPicker(),
                  onPrev: () => _navigatePeriod(-1),
                  onNext: () => _navigatePeriod(1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              l10n.activeVehicles,
              vehicles.toString(),
              l10n.withExpensesRegistered,
              Icons.trending_up,
              const Color(0xFF22C55E),
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              l10n.categoriesLabel,
              categories.toString(),
              l10n.expenseTypes,
              Icons.donut_large,
              const Color(0xFFF97316),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    bool isHighlighted = false,
    VoidCallback? onTap,
    VoidCallback? onPrev,
    VoidCallback? onNext,
  }) {
    final cardContent = Row(
      children: [
        if (isHighlighted && onPrev != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white.withValues(alpha: 0.55),
              size: 22,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Colors.white.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isHighlighted ? Colors.white : color,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isHighlighted
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isHighlighted
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (isHighlighted && onNext != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.55),
              size: 22,
            ),
          ),
      ],
    );

    final inkWidget = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
                child: cardContent,
              )
            : cardContent,
      ),
    );

    if (onPrev != null || onNext != null) {
      return GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -300) onNext?.call();
          if ((details.primaryVelocity ?? 0) > 300) onPrev?.call();
        },
        child: inkWidget,
      );
    }
    return inkWidget;
  }

  // Gráfico de gastos por vehículo (Barras)
  Widget _buildExpensesByVehicleChart() {
    return StreamBuilder<List<Expense>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final rawList = (snapshot.data ?? []).where((e) {
          if (e.date.isBefore(_firstDayOfMonth) ||
              e.date.isAfter(_lastDayOfMonth)) {
            return false;
          }
          if (_selectedVehicleIds.isNotEmpty &&
              !_selectedVehicleIds.contains(e.vehicleId)) {
            return false;
          }
          if (_selectedCategories.isNotEmpty &&
              !_selectedCategories.contains(e.category)) {
            return false;
          }
          return true;
        }).toList();
        final Map<String, double> vehicleTotals = {};
        for (final expense in rawList) {
          vehicleTotals[expense.vehicleName] =
              (vehicleTotals[expense.vehicleName] ?? 0) + expense.amount;
        }
        if (vehicleTotals.isEmpty) {
          return _buildEmptyChart(
            l10n.expensesByVehicle,
            l10n.noExpensesInPeriod,
          );
        }

        final data = vehicleTotals;
        final entries = data.entries.toList();

        // Escala dinámica con intervalos "bonitos" (1K, 2K, 5K, 10K, etc.)
        final rawMax = entries
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b);
        final rawStep = rawMax / 5;
        final magnitude = pow(10, (log(rawStep) / log(10)).floor()).toDouble();
        final normalized = rawStep / magnitude;
        final double niceStep;
        if (normalized <= 1) {
          niceStep = 1 * magnitude;
        } else if (normalized <= 2) {
          niceStep = 2 * magnitude;
        } else if (normalized <= 5) {
          niceStep = 5 * magnitude;
        } else {
          niceStep = 10 * magnitude;
        }
        // maxY = siguiente múltiplo de niceStep por encima del max real
        final double chartMaxY = (rawMax / niceStep).ceil() * niceStep;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.expensesByVehicle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  const double yAxisWidth = 52.0;
                  const double totalHeight = 220.0;
                  const double bottomReserved = 36.0;
                  const double plotHeight = totalHeight - bottomReserved;
                  const double barSlotWidth = 64.0;
                  final bool needsScroll = entries.length > 5;
                  final double scrollableWidth = entries.length * barSlotWidth;
                  final int numIntervals = (chartMaxY / niceStep).round();

                  // Eje Y manual (queda fijo mientras se desliza)
                  final yAxisWidget = SizedBox(
                    width: yAxisWidth,
                    height: totalHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(numIntervals + 1, (i) {
                        final value = i * niceStep;
                        final topOffset =
                            (1 - value / chartMaxY) * plotHeight - 6;
                        return Positioned(
                          top: topOffset,
                          left: 0,
                          right: 4,
                          child: Text(
                            '\$${NumberFormat.compact().format(value)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      }),
                    ),
                  );

                  // BarChart sin eje Y (lo mostramos manualmente arriba)
                  final barChart = BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${entries[groupIndex].key}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '\$${NumberFormat('#,##0.00').format(rod.toY)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: bottomReserved,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= entries.length) {
                                return const Text('');
                              }
                              final name = entries[value.toInt()].key;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  name.length > 8
                                      ? '${name.substring(0, 8)}…'
                                      : name,
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                            reservedSize: 0,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: niceStep,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: entries.asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value,
                              color: const Color(0xFF17A2B8),
                              width: needsScroll ? 26 : 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: totalHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            yAxisWidget,
                            Expanded(
                              child: needsScroll
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: SizedBox(
                                        width: scrollableWidth,
                                        height: totalHeight,
                                        child: barChart,
                                      ),
                                    )
                                  : barChart,
                            ),
                          ],
                        ),
                      ),
                      if (needsScroll)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.swipe,
                                size: 13,
                                color: Color(0xFFCBD5E1),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Desliza para ver más vehículos',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Gráfico de distribución por categoría (Pastel)
  Widget _buildExpensesByCategoryChart() {
    return StreamBuilder<List<Expense>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final rawList = (snapshot.data ?? []).where((e) {
          if (e.date.isBefore(_firstDayOfMonth) ||
              e.date.isAfter(_lastDayOfMonth)) {
            return false;
          }
          if (_selectedVehicleIds.isNotEmpty &&
              !_selectedVehicleIds.contains(e.vehicleId)) {
            return false;
          }
          if (_selectedCategories.isNotEmpty &&
              !_selectedCategories.contains(e.category)) {
            return false;
          }
          return true;
        }).toList();
        final Map<ExpenseCategory, double> categoryTotals = {};
        for (final expense in rawList) {
          categoryTotals[expense.category] =
              (categoryTotals[expense.category] ?? 0) + expense.amount;
        }
        if (categoryTotals.isEmpty) {
          return _buildEmptyChart(
            l10n.distributionByCategory,
            l10n.noExpensesInPeriod,
          );
        }

        final data = categoryTotals;
        final total = data.values.reduce((a, b) => a + b);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.distributionByCategory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: data.entries.map((entry) {
                            final percentage = (entry.value / total) * 100;
                            final isLarge = percentage >= 8;
                            return PieChartSectionData(
                              color: _getCategoryColor(entry.key),
                              value: entry.value,
                              // Segmentos pequeños ocultan el label del slice;
                              // el % aparece en la leyenda lateral.
                              title: isLarge
                                  ? '${percentage.toStringAsFixed(0)}%'
                                  : '',
                              radius: 65,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black38, blurRadius: 3),
                                ],
                              ),
                              // Centrar label verticalmente dentro del slice
                              titlePositionPercentageOffset: 0.6,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: data.entries.map((entry) {
                          final percentage = (entry.value / total) * 100;
                          final isSmall = percentage < 8;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _getCategoryName(entry.key),
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Mostrar % en leyenda solo para segmentos
                                // pequeños (ya visible en el slice si es grande)
                                if (isSmall)
                                  Text(
                                    '${percentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getCategoryColor(entry.key),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Lista de gastos recientes
  Widget _buildRecentExpensesList() {
    return StreamBuilder<List<Expense>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.recentExpenses,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noExpenses,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Aplicar filtros de período, vehículo y categoría
        var filteredExpenses = snapshot.data!
            .where(
              (e) =>
                  !e.date.isBefore(_firstDayOfMonth) &&
                  !e.date.isAfter(_lastDayOfMonth),
            )
            .toList();

        // Filtrar por vehículo
        if (_selectedVehicleIds.isNotEmpty) {
          filteredExpenses = filteredExpenses
              .where((e) => _selectedVehicleIds.contains(e.vehicleId))
              .toList();
        }

        // Filtrar por categoría
        if (_selectedCategories.isNotEmpty) {
          filteredExpenses = filteredExpenses
              .where((e) => _selectedCategories.contains(e.category))
              .toList();
        }

        // Tomar solo los primeros 10
        filteredExpenses = filteredExpenses.take(10).toList();

        if (filteredExpenses.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.recentExpenses,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noExpensesWithFilters,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.recentExpenses,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
            ),
            ...filteredExpenses.map((expense) => _buildExpenseItem(expense)),
          ],
        );
      },
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    final categoryColor = _getCategoryColor(expense.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showExpenseDetails(expense),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Ícono de categoría
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(6),
                child: _buildCategoryIcon(expense.category),
              ),
              const SizedBox(width: 16),
              // Información del gasto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCategoryName(expense.category),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.vehicleName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'dd MMM yyyy',
                            Localizations.localeOf(context).languageCode,
                          ).format(expense.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (expense.description != null &&
                        expense.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (expense.receiptUrl != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            expense.receiptType == 'photo'
                                ? Icons.image
                                : expense.receiptType == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.qr_code_2,
                            size: 12,
                            color: const Color(0xFF17A2B8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Comprobante adjunto',
                            style: TextStyle(
                              fontSize: 11,
                              color: const Color(0xFF17A2B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Monto
              Text(
                '\$${NumberFormat('#,##0.00').format(expense.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Parser modular de QR
  // ──────────────────────────────────────────────

  /// Resultado del parser. Solo los campos reconocidos vendrán rellenos.
  static Map<String, dynamic> _parseQRCode(String raw) {
    final result = <String, dynamic>{'type': 'unknown', 'rawText': raw};

    // ── 1. QR SAT (factura electrónica mexicana) ──────────────────────────
    // Formato: https://verificacfdi.facturaelectronica.sat.gob.mx/default.aspx
    //          ?id=UUID&re=RFC_emisor&rr=RFC_receptor&tt=total&fe=firma
    if (raw.contains('sat.gob.mx') || raw.contains('verificacfdi')) {
      result['type'] = 'sat';
      try {
        final uri = Uri.parse(raw);
        final tt = uri.queryParameters['tt'];
        final re = uri.queryParameters['re'];
        final rr = uri.queryParameters['rr'];
        if (tt != null) {
          final amount = double.tryParse(tt.replaceAll(',', '.'));
          if (amount != null) result['amount'] = amount;
        }
        final notes = [
          if (re != null) 'Emisor: $re',
          if (rr != null) 'Receptor: $rr',
          'CFDI verificable en SAT',
        ].join(' | ');
        result['notes'] = notes;
        result['satUrl'] = raw;
      } catch (_) {}
      return result;
    }

    // ── 2. Formato propio: clave=valor separado por | ─────────────────────
    // Ejemplo: monto=500|categoria=fuel|fecha=2026-02-23|notas=Carga de gasolina
    if (raw.contains('=') &&
        (raw.contains('|') ||
            raw.contains('monto=') ||
            raw.contains('amount='))) {
      final pairs = raw.split('|');
      final map = <String, String>{};
      for (final pair in pairs) {
        final idx = pair.indexOf('=');
        if (idx < 0) continue;
        final key = pair.substring(0, idx).trim().toLowerCase();
        final val = pair.substring(idx + 1).trim();
        map[key] = val;
      }
      if (map.isNotEmpty) {
        result['type'] = 'custom';
        // Monto
        final rawAmount = map['monto'] ?? map['amount'] ?? map['total'];
        if (rawAmount != null) {
          final amount = double.tryParse(
            rawAmount.replaceAll(',', '.').replaceAll('\$', ''),
          );
          if (amount != null) result['amount'] = amount;
        }
        // Categoría
        final rawCat = (map['categoria'] ?? map['category'] ?? '')
            .toLowerCase();
        final catMap = {
          'combustible': ExpenseCategory.fuel,
          'fuel': ExpenseCategory.fuel,
          'gasolina': ExpenseCategory.fuel,
          'mantenimiento': ExpenseCategory.maintenance,
          'maintenance': ExpenseCategory.maintenance,
          'seguro': ExpenseCategory.insurance,
          'insurance': ExpenseCategory.insurance,
          'peaje': ExpenseCategory.toll,
          'toll': ExpenseCategory.toll,
          'estacionamiento': ExpenseCategory.parking,
          'parking': ExpenseCategory.parking,
          'reparacion': ExpenseCategory.repair,
          'reparación': ExpenseCategory.repair,
          'repair': ExpenseCategory.repair,
          'otro': ExpenseCategory.other,
          'other': ExpenseCategory.other,
        };
        if (catMap.containsKey(rawCat)) result['category'] = catMap[rawCat];
        // Fecha
        final rawDate = map['fecha'] ?? map['date'];
        if (rawDate != null) {
          try {
            result['date'] = DateTime.parse(rawDate);
          } catch (_) {}
        }
        // Notas
        final rawNotes =
            map['notas'] ??
            map['notes'] ??
            map['descripcion'] ??
            map['description'];
        if (rawNotes != null && rawNotes.isNotEmpty) result['notes'] = rawNotes;
      }
      return result;
    }

    // ── 3. Fallback: texto desconocido ─────────────────────────────────────
    // type ya es 'unknown', rawText ya está seteado
    return result;
  }

  // Diálogo para agregar gasto
  void _showAddExpenseDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Capturar messenger del contexto PADRE antes de que showDialog lo sombree
    final parentMessenger = ScaffoldMessenger.of(context);
    final amountController = TextEditingController();
    final mileageController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedVehicleId; // Usar ID en lugar del objeto completo
    ExpenseCategory selectedCategory = ExpenseCategory.fuel;
    DateTime selectedDate = DateTime.now();
    File? mileagePhoto;
    File? receiptFile;
    String? receiptType; // 'qr', 'photo', 'pdf'
    String? receiptFileName; // Nombre del archivo PDF
    String? qrData; // Datos escaneados del QR
    final ImagePicker picker = ImagePicker();
    bool isDialogActive = true; // Bandera para controlar setState

    // Función para limpiar recursos al cerrar.
    // Esperar a que la animación de salida del diálogo termine (~300ms)
    // antes de desechar los controllers, para evitar que los TextFields
    // los accedan después de dispose() durante la transición.
    void disposeControllers() {
      isDialogActive = false;
      Future.delayed(const Duration(milliseconds: 350), () {
        amountController.dispose();
        mileageController.dispose();
        notesController.dispose();
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final maxDialogHeight =
              MediaQuery.of(context).size.height - keyboardHeight - 80;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: maxDialogHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.registerExpense,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF17A2B8),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                // whenComplete(disposeControllers) maneja la
                                // limpieza — no llamar aquí para evitar
                                // double-dispose de TextEditingControllers
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.registerExpenseSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selector de vehículo
                          Builder(
                            builder: (context) {
                              final vehicles = _latestVehicles;
                              if (vehicles.isEmpty) {
                                return Text(l10n.noVehiclesAvailable);
                              }

                              final selectedVehicle = vehicles
                                  .cast<Vehicle?>()
                                  .firstWhere(
                                    (v) => v?.id == selectedVehicleId,
                                    orElse: () => null,
                                  );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.vehicleRequired,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierColor: Colors.black26,
                                        builder: (ctx) {
                                          final searchCtrl =
                                              TextEditingController();
                                          List<Vehicle> filtered = List.from(
                                            vehicles,
                                          );
                                          return StatefulBuilder(
                                            builder: (ctx, setVehicleS) {
                                              final bottomInset = MediaQuery.of(
                                                ctx,
                                              ).viewInsets.bottom;
                                              return Dialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                insetPadding:
                                                    EdgeInsets.fromLTRB(
                                                      24,
                                                      40,
                                                      24,
                                                      bottomInset + 16,
                                                    ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        0,
                                                        16,
                                                        0,
                                                        8,
                                                      ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                            ),
                                                        child: Text(
                                                          l10n.selectAVehicle,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                            ),
                                                        child: TextField(
                                                          controller:
                                                              searchCtrl,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                          decoration: InputDecoration(
                                                            hintText: l10n
                                                                .searchNamePlate,
                                                            hintStyle:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                ),
                                                            prefixIcon:
                                                                const Icon(
                                                                  Icons.search,
                                                                  size: 20,
                                                                ),
                                                            suffixIcon:
                                                                searchCtrl
                                                                    .text
                                                                    .isNotEmpty
                                                                ? IconButton(
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .clear,
                                                                      size: 18,
                                                                    ),
                                                                    onPressed: () {
                                                                      searchCtrl
                                                                          .clear();
                                                                      setVehicleS(
                                                                        () => filtered =
                                                                            List.from(
                                                                              vehicles,
                                                                            ),
                                                                      );
                                                                    },
                                                                  )
                                                                : null,
                                                            isDense: true,
                                                            border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10,
                                                                ),
                                                          ),
                                                          onChanged: (q) {
                                                            final query = q
                                                                .toLowerCase();
                                                            setVehicleS(() {
                                                              filtered = vehicles.where((
                                                                v,
                                                              ) {
                                                                return v.name
                                                                        .toLowerCase()
                                                                        .contains(
                                                                          query,
                                                                        ) ||
                                                                    v.plate
                                                                        .toLowerCase()
                                                                        .contains(
                                                                          query,
                                                                        ) ||
                                                                    v.brand
                                                                        .toLowerCase()
                                                                        .contains(
                                                                          query,
                                                                        ) ||
                                                                    v.model
                                                                        .toLowerCase()
                                                                        .contains(
                                                                          query,
                                                                        );
                                                              }).toList();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      const Divider(height: 1),
                                                      ConstrainedBox(
                                                        constraints: BoxConstraints(
                                                          maxHeight:
                                                              (MediaQuery.of(
                                                                            ctx,
                                                                          )
                                                                          .size
                                                                          .height -
                                                                      bottomInset -
                                                                      270)
                                                                  .clamp(
                                                                    80.0,
                                                                    260.0,
                                                                  ),
                                                        ),
                                                        child: filtered.isEmpty
                                                            ? Center(
                                                                child: Text(
                                                                  l10n.noMatches,
                                                                  style: const TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                                ),
                                                              )
                                                            : ListView.builder(
                                                                itemCount:
                                                                    filtered
                                                                        .length,
                                                                itemBuilder: (_, i) {
                                                                  final v =
                                                                      filtered[i];
                                                                  final isSel =
                                                                      selectedVehicleId ==
                                                                      v.id;
                                                                  return ListTile(
                                                                    dense: true,
                                                                    selected:
                                                                        isSel,
                                                                    selectedColor:
                                                                        const Color(
                                                                          0xFF17A2B8,
                                                                        ),
                                                                    selectedTileColor:
                                                                        const Color(
                                                                          0xFF17A2B8,
                                                                        ).withValues(
                                                                          alpha:
                                                                              0.08,
                                                                        ),
                                                                    trailing:
                                                                        isSel
                                                                        ? const Icon(
                                                                            Icons.check,
                                                                            color: Color(
                                                                              0xFF17A2B8,
                                                                            ),
                                                                            size:
                                                                                18,
                                                                          )
                                                                        : null,
                                                                    title: Text(
                                                                      v.name,
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                      ),
                                                                    ),
                                                                    subtitle: Text(
                                                                      '${v.plate} · ${v.brand} ${v.model} ${v.year}',
                                                                      style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color: Colors
                                                                            .grey
                                                                            .shade600,
                                                                      ),
                                                                    ),
                                                                    onTap: () {
                                                                      if (isDialogActive) {
                                                                        setState(
                                                                          () => selectedVehicleId =
                                                                              isSel
                                                                              ? null
                                                                              : v.id,
                                                                        );
                                                                      }
                                                                      Navigator.pop(
                                                                        ctx,
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                      ),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.fromLTRB(
                                                                0,
                                                                4,
                                                                12,
                                                                4,
                                                              ),
                                                          child: TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                ),
                                                            child: Text(
                                                              l10n.cancel,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedVehicle?.name ??
                                                  l10n.selectAVehicle,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: selectedVehicle == null
                                                    ? Colors.grey.shade500
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Selector de categoría
                          Text(
                            l10n.categoryRequired,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ExpenseCategory>(
                            initialValue: selectedCategory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            items: ExpenseCategory.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    _buildCategoryIcon(category, size: 22),
                                    const SizedBox(width: 8),
                                    Text(_getCategoryName(category)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (category) {
                              if (isDialogActive) {
                                setState(() => selectedCategory = category!);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Monto
                          Text(
                            l10n.amountMxnRequired,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            decoration: InputDecoration(
                              hintText: '0.00',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Fecha
                          Text(
                            l10n.dateRequired,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null && isDialogActive) {
                                setState(() => selectedDate = date);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(selectedDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Kilometraje con foto
                          Text(
                            l10n.mileageOptional,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: mileageController,
                                  decoration: InputDecoration(
                                    hintText: l10n.mileageHint,
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF17A2B8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    try {
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.camera,
                                            maxWidth: 1920,
                                            maxHeight: 1080,
                                            imageQuality: 85,
                                          );
                                      if (image != null && isDialogActive) {
                                        setState(() {
                                          mileagePhoto = File(image.path);
                                        });
                                      }
                                    } catch (e) {
                                      parentMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.errorCapturingPhotoExpense(''),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Preview de foto de odómetro
                          if (mileagePhoto != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.cyan.shade200),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      mileagePhoto!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      cacheWidth: 120,
                                      cacheHeight: 120,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.odometerPhotoLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.attachedLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      if (isDialogActive) {
                                        setState(() {
                                          mileagePhoto = null;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Comprobante
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.receiptOptional,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Escanear QR
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          // Solicitar permiso de cámara en tiempo de ejecución
                                          final status =
                                              await NativeHelper.requestCameraPermission();
                                          if (!context.mounted) return;
                                          if (!status.isGranted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.cameraPermissionQr,
                                                ),
                                                action:
                                                    status.isPermanentlyDenied
                                                    ? SnackBarAction(
                                                        label:
                                                            l10n.openSettings,
                                                        onPressed: NativeHelper
                                                            .openAppSettings,
                                                      )
                                                    : null,
                                              ),
                                            );
                                            return;
                                          }
                                          // Abrir scanner QR
                                          final result =
                                              await Navigator.push<String>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      _QRScannerScreen(),
                                                ),
                                              );

                                          if (result != null &&
                                              isDialogActive) {
                                            final parsed = _parseQRCode(result);
                                            setState(() {
                                              qrData = result;
                                              receiptType = 'qr';
                                              // Auto-rellenar campos según el tipo detectado
                                              if (parsed['amount'] != null) {
                                                amountController.text =
                                                    (parsed['amount'] as double)
                                                        .toStringAsFixed(2);
                                              }
                                              if (parsed['category'] != null) {
                                                selectedCategory =
                                                    parsed['category']
                                                        as ExpenseCategory;
                                              }
                                              if (parsed['date'] != null) {
                                                selectedDate =
                                                    parsed['date'] as DateTime;
                                              }
                                              if (parsed['notes'] != null) {
                                                notesController.text =
                                                    parsed['notes'] as String;
                                              }
                                            });
                                            final tipo =
                                                parsed['type'] as String;
                                            if (tipo == 'sat') {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.qrSatDetected,
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF28A745,
                                                    ),
                                                    duration: Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else if (tipo == 'custom') {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.qrCustomDetected,
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF17A2B8,
                                                    ),
                                                    duration: Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n.qrSavedAsText,
                                                    ),
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF17A2B8),
                                                Color(0xFF138496),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.qr_code_scanner,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                l10n.scanQr,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Foto
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            final XFile? image = await picker
                                                .pickImage(
                                                  source: ImageSource.camera,
                                                  maxWidth: 1920,
                                                  maxHeight: 1080,
                                                  imageQuality: 85,
                                                );
                                            if (image != null &&
                                                isDialogActive) {
                                              setState(() {
                                                receiptFile = File(image.path);
                                                receiptType = 'photo';
                                                receiptFileName = null;
                                                qrData =
                                                    null; // Limpiar QR si existía
                                              });
                                            }
                                          } catch (e) {
                                            parentMessenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.errorCapturingPhotoExpense(
                                                    '',
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6F00),
                                                Color(0xFFFF8F2F),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.photo_camera,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                l10n.photoButtonLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // PDF
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            FilePickerResult? result =
                                                await FilePicker.platform
                                                    .pickFiles(
                                                      type: FileType.custom,
                                                      allowedExtensions: [
                                                        'pdf',
                                                      ],
                                                    );

                                            if (result != null &&
                                                result.files.single.path !=
                                                    null &&
                                                isDialogActive) {
                                              setState(() {
                                                receiptFile = File(
                                                  result.files.single.path!,
                                                );
                                                receiptType = 'pdf';
                                                receiptFileName =
                                                    result.files.single.name;
                                                qrData =
                                                    null; // Limpiar QR si existía
                                              });
                                            }
                                          } catch (e) {
                                            parentMessenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.errorSelectingPdfFile(
                                                    '',
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade700,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'PDF',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Preview de recibo QR
                                if (qrData != null && receiptType == 'qr') ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.cyan.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.cyan.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2,
                                            color: Color(0xFF17A2B8),
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.qrScanned,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                qrData!.length > 30
                                                    ? '${qrData!.substring(0, 30)}...'
                                                    : qrData!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            if (isDialogActive) {
                                              setState(() {
                                                qrData = null;
                                                receiptType = null;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Preview de recibo Foto/PDF
                                if (receiptFile != null &&
                                    (receiptType == 'photo' ||
                                        receiptType == 'pdf')) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: receiptType == 'photo'
                                          ? Colors.orange.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: receiptType == 'photo'
                                            ? Colors.orange.shade200
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Vista previa de imagen o ícono PDF
                                        if (receiptType == 'photo')
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              receiptFile!,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 36,
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                receiptType == 'photo'
                                                    ? l10n.receiptPhotoLabel
                                                    : l10n.receiptPdfLabel,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                receiptType == 'photo'
                                                    ? l10n.attachedLabel
                                                    : receiptFileName ??
                                                          l10n.attachedLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            if (isDialogActive) {
                                              setState(() {
                                                receiptFile = null;
                                                receiptType = null;
                                                receiptFileName = null;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notas
                          Text(
                            l10n.notesOptional,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: notesController,
                            decoration: InputDecoration(
                              hintText: l10n.notesHint,
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Usar parentMessenger capturado ANTES del showDialog
                              // para evitar crash de '_dependents.isEmpty'
                              // al usar context del diálogo después de Navigator.pop()

                              if (selectedVehicleId == null) {
                                parentMessenger.showSnackBar(
                                  SnackBar(content: Text(l10n.selectAVehicle)),
                                );
                                return;
                              }

                              final amount = double.tryParse(
                                amountController.text,
                              );
                              if (amount == null || amount <= 0) {
                                parentMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.enterValidAmount),
                                  ),
                                );
                                return;
                              }

                              final mileage = mileageController.text.isEmpty
                                  ? null
                                  : int.tryParse(mileageController.text);

                              // Obtener vehículo seleccionado del caché
                              final selectedVehicle = _latestVehicles
                                  .firstWhere((v) => v.id == selectedVehicleId);

                              // Capturar Navigator antes de operaciones async
                              final navigator = Navigator.of(context);

                              // Mostrar loading
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              try {
                                final expenseId = const Uuid().v4();
                                final userId = _billingService.currentUserId!;
                                String? mileagePhotoUrl;
                                String? receiptUrl;
                                String? finalReceiptType;

                                // Subir foto del odómetro si existe
                                if (mileagePhoto != null) {
                                  mileagePhotoUrl = await _billingService
                                      .uploadMileagePhoto(
                                        mileagePhoto!,
                                        userId,
                                        expenseId,
                                      );
                                }

                                // Subir recibo según el tipo
                                if (qrData != null && receiptType == 'qr') {
                                  // Crear archivo temporal con los datos del QR
                                  final tempDir = Directory.systemTemp;
                                  final qrFile = File(
                                    '${tempDir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.txt',
                                  );
                                  await qrFile.writeAsString(qrData!);

                                  receiptUrl = await _billingService
                                      .uploadReceipt(
                                        qrFile,
                                        userId,
                                        expenseId,
                                        'qr',
                                      );
                                  finalReceiptType = 'qr';

                                  // Limpiar archivo temporal
                                  try {
                                    await qrFile.delete();
                                  } catch (e) {
                                    // Ignorar error al eliminar temporal
                                  }
                                } else if (receiptFile != null &&
                                    (receiptType == 'photo' ||
                                        receiptType == 'pdf')) {
                                  // Subir foto o PDF del recibo
                                  receiptUrl = await _billingService
                                      .uploadReceipt(
                                        receiptFile!,
                                        userId,
                                        expenseId,
                                        receiptType!,
                                      );
                                  finalReceiptType = receiptType;
                                }

                                final expense = Expense(
                                  id: expenseId,
                                  userId: userId,
                                  vehicleId: selectedVehicle.id,
                                  vehicleName: selectedVehicle.name,
                                  category: selectedCategory,
                                  amount: amount,
                                  date: selectedDate,
                                  description: notesController.text.isEmpty
                                      ? null
                                      : notesController.text,
                                  mileage: mileage,
                                  mileagePhotoUrl: mileagePhotoUrl,
                                  receiptUrl: receiptUrl,
                                  receiptType: finalReceiptType,
                                );

                                await _billingService.addExpense(expense);

                                if (context.mounted) {
                                  navigator.pop(); // Cerrar loading
                                  navigator.pop(); // Cerrar diálogo
                                  parentMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.expenseAddedSuccessfully,
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  navigator.pop(); // Cerrar loading
                                  parentMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.errorSavingExpense(''),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF17A2B8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(disposeControllers);
  }

  // ───────────────────────────────────────────
  // VISOR DE COMPROBANTE
  // ───────────────────────────────────────────

  Future<void> _viewReceipt(Expense expense) async {
    if (expense.receiptUrl == null) return;
    final url = expense.receiptUrl!;
    final type = expense.receiptType ?? '';
    // Capturar messenger ANTES de cualquier operación async
    final messenger = ScaffoldMessenger.of(context);

    if (type == 'photo') {
      // Mostrar imagen en pantalla completa
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 32,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'pdf') {
      // Descargar y abrir PDF con visor del sistema, con fallback a navegador
      if (!mounted) return;
      // Indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final response = await http.get(Uri.parse(url));
        if (!mounted) return;
        Navigator.pop(context); // cerrar indicador
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/comprobante_${expense.id}.pdf');
          await file.writeAsBytes(response.bodyBytes);
          final opened = await NativeHelper.openFile(file.path);
          if (!opened && mounted) {
            // Si no se pudo abrir localmente, intentar en navegador
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se encontró app para abrir el PDF. Intenta instalar un lector de PDF.',
                  ),
                ),
              );
            }
          }
        } else {
          // Si falla la descarga, abrir directamente en navegador
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('No se pudo descargar el comprobante.'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          // Último fallback: intentar abrir en navegador
          try {
            final uri = Uri.parse(url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Error al abrir el comprobante')),
            );
          }
        }
      }
    } else if (type == 'qr') {
      // Mostrar los datos del QR en un diálogo
      if (!mounted) return;
      try {
        final response = await http.get(Uri.parse(url));
        final qrText = response.statusCode == 200 ? response.body : url;
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.qr_code_2, color: Color(0xFF17A2B8)),
                SizedBox(width: 8),
                Text('Datos del QR'),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                qrText,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Error al cargar el comprobante')),
          );
        }
      }
    }
  }

  // Mostrar detalles de un gasto
  void _showExpenseDetails(Expense expense) {
    final l10n = AppLocalizations.of(context);
    // Capturar messenger del contexto PADRE antes de que showDialog lo sombree
    final parentMessenger = ScaffoldMessenger.of(context);

    // Etiqueta e icono del tipo de comprobante
    IconData receiptIcon = Icons.receipt_long;
    String receiptLabel = '';
    if (expense.receiptUrl != null) {
      switch (expense.receiptType) {
        case 'photo':
          receiptIcon = Icons.image;
          receiptLabel = 'Foto';
          break;
        case 'pdf':
          receiptIcon = Icons.picture_as_pdf;
          receiptLabel = 'PDF';
          break;
        case 'qr':
          receiptIcon = Icons.qr_code_2;
          receiptLabel = 'QR / XML';
          break;
        default:
          receiptLabel = 'Adjunto';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.expenseDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(l10n.vehicleSingular, expense.vehicleName),
            _buildDetailRow(
              l10n.categoryLabel,
              _getCategoryName(expense.category),
            ),
            _buildDetailRow(
              l10n.amountLabel,
              '\$${NumberFormat('#,##0.00').format(expense.amount)}',
            ),
            _buildDetailRow(
              l10n.date,
              DateFormat(
                'dd MMMM yyyy',
                Localizations.localeOf(context).languageCode,
              ).format(expense.date),
            ),
            if (expense.description != null)
              _buildDetailRow(l10n.descriptionLabel, expense.description!),
            // Fila de comprobante
            if (expense.receiptUrl != null) ...[
              const Divider(height: 24),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _viewReceipt(expense);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17A2B8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF17A2B8).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        receiptIcon,
                        color: const Color(0xFF17A2B8),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Comprobante · $receiptLabel',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF17A2B8),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Color(0xFF17A2B8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.confirmDeleteExpenseTitle),
                  content: Text(l10n.confirmDeleteExpense),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                try {
                  await _billingService.deleteExpense(expense.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    parentMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.expenseDeletedSuccessfully)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    parentMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.error)),
                    );
                  }
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Utilidades para colores y nombres de categorías
  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.fuel:
        return const Color(0xFF1447E6); // azul
      case ExpenseCategory.maintenance:
        return const Color(0xFFCA3500); // naranja-rojo
      case ExpenseCategory.insurance:
        return const Color(0xFF008236); // verde
      case ExpenseCategory.toll:
        return const Color(0xFF8200DB); // púrpura
      case ExpenseCategory.parking:
        return const Color(0xFF5856D6); // índigo
      case ExpenseCategory.repair:
        return const Color(0xFFFF2D78); // rosa
      case ExpenseCategory.other:
        return const Color(0xFF8E8E93); // gris
    }
  }

  String _getCategorySvg(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.fuel:
        return 'public/images/containergasolina.svg';
      case ExpenseCategory.maintenance:
        return 'public/images/reparacion.svg';
      case ExpenseCategory.insurance:
        return 'public/images/seguro.svg';
      case ExpenseCategory.toll:
        return 'public/images/peaje.svg';
      case ExpenseCategory.parking:
        return 'public/images/cat_parking.svg';
      case ExpenseCategory.repair:
        return 'public/images/cat_repair.svg';
      case ExpenseCategory.other:
        return 'public/images/cat_other.svg';
    }
  }

  Widget _buildCategoryIcon(ExpenseCategory category, {double size = 40}) {
    const Map<ExpenseCategory, String> pngAssets = {
      ExpenseCategory.fuel: 'public/images/gasolina.png',
      ExpenseCategory.maintenance: 'public/images/mantenimiento.png',
      ExpenseCategory.insurance: 'public/images/seguro.png',
      ExpenseCategory.toll: 'public/images/peaje.png',
      ExpenseCategory.parking: 'public/images/estacionamiento.png',
      ExpenseCategory.repair: 'public/images/reparacion.png',
    };
    final png = pngAssets[category];
    if (png != null) {
      return Image.asset(png, width: size, height: size, fit: BoxFit.contain);
    }
    return SvgPicture.asset(
      _getCategorySvg(category),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    final l10n = AppLocalizations.of(context);
    switch (category) {
      case ExpenseCategory.fuel:
        return l10n.expenseCatFuel;
      case ExpenseCategory.maintenance:
        return l10n.expenseCatMaintenance;
      case ExpenseCategory.insurance:
        return l10n.expenseCatInsurance;
      case ExpenseCategory.toll:
        return l10n.expenseCatToll;
      case ExpenseCategory.parking:
        return l10n.expenseCatParking;
      case ExpenseCategory.repair:
        return l10n.expenseCatRepair;
      case ExpenseCategory.other:
        return l10n.expenseCatOther;
    }
  }

  // ─────────────────────────────────────────────
  // SELECTOR DE PERÍODO (para gráficas y resumen)
  // ─────────────────────────────────────────────

  void _showPeriodPicker() {
    final l10n = AppLocalizations.of(context);
    int mode = _periodMode;
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;
    int selectedDay = _selectedDate.day;
    DateTime selectedWeekStart = _selectedWeekStart;
    int calendarYear = selectedWeekStart.year;
    int calendarMonth = selectedWeekStart.month;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          DateTime start;
          String rangeText;
          if (mode == 0) {
            start = DateTime(selectedYear, 1, 1);
            rangeText = '${l10n.yearTab} $selectedYear';
          } else if (mode == 1) {
            start = DateTime(selectedYear, selectedMonth, 1);
            rangeText = DateFormat(
              'MMMM yyyy',
              Localizations.localeOf(context).languageCode,
            ).format(DateTime(selectedYear, selectedMonth));
          } else if (mode == 2) {
            start = selectedWeekStart;
            final weekEnd = selectedWeekStart.add(const Duration(days: 6));
            rangeText =
                '${DateFormat('dd/MM/yyyy').format(start)}  →  ${DateFormat('dd/MM/yyyy').format(weekEnd)}';
          } else {
            final d = DateTime(selectedYear, selectedMonth, selectedDay);
            start = d;
            rangeText = DateFormat(
              'EEEE dd/MM/yyyy',
              Localizations.localeOf(context).languageCode,
            ).format(d);
          }

          Widget buildWeekCalendar() {
            final firstDay = DateTime(calendarYear, calendarMonth, 1);
            final daysInMonth = DateTime(
              calendarYear,
              calendarMonth + 1,
              0,
            ).day;
            final startOffset = firstDay.weekday - 1;
            final totalCells = startOffset + daysInMonth;
            final rows = (totalCells / 7).ceil();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setSheet(() {
                          if (calendarMonth == 1) {
                            calendarMonth = 12;
                            calendarYear--;
                          } else {
                            calendarMonth--;
                          }
                        });
                      },
                    ),
                    Text(
                      '${DateFormat('MMMM', Localizations.localeOf(context).languageCode).format(DateTime(calendarYear, calendarMonth))} $calendarYear',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setSheet(() {
                          if (calendarMonth == 12) {
                            calendarMonth = 1;
                            calendarYear++;
                          } else {
                            calendarMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: l10n.weekdayAbbr
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                ...List.generate(rows, (rowIdx) {
                  final mondayOffset = rowIdx * 7 - startOffset;
                  final mondayDate = DateTime(
                    calendarYear,
                    calendarMonth,
                    1 + mondayOffset,
                  );
                  final isSelected =
                      selectedWeekStart.year == mondayDate.year &&
                      selectedWeekStart.month == mondayDate.month &&
                      selectedWeekStart.day == mondayDate.day;
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      selectedWeekStart = mondayDate;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF17A2B8).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: List.generate(7, (colIdx) {
                          final dayOffset = mondayOffset + colIdx;
                          final dayNum = 1 + dayOffset;
                          final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
                          final cellDate = inMonth
                              ? DateTime(calendarYear, calendarMonth, dayNum)
                              : null;
                          final isToday =
                              cellDate != null &&
                              cellDate.year == DateTime.now().year &&
                              cellDate.month == DateTime.now().month &&
                              cellDate.day == DateTime.now().day;
                          return Expanded(
                            child: inMonth
                                ? Container(
                                    height: 36,
                                    decoration: isToday
                                        ? BoxDecoration(
                                            color: const Color(0xFF17A2B8),
                                            shape: BoxShape.circle,
                                          )
                                        : null,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isToday
                                            ? Colors.white
                                            : isSelected
                                            ? const Color(0xFF17A2B8)
                                            : Colors.black87,
                                        fontWeight: isToday || isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ],
            );
          }

          Widget buildDayCalendar() {
            final firstDay = DateTime(selectedYear, selectedMonth, 1);
            final daysInMonth = DateTime(
              selectedYear,
              selectedMonth + 1,
              0,
            ).day;
            final startOffset = firstDay.weekday - 1;
            final totalCells = startOffset + daysInMonth;
            final rows = (totalCells / 7).ceil();
            final today = DateTime.now();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setSheet(() {
                          if (selectedMonth == 1) {
                            selectedMonth = 12;
                            selectedYear--;
                          } else {
                            selectedMonth--;
                          }
                          selectedDay = 1;
                        });
                      },
                    ),
                    Text(
                      '${DateFormat('MMMM', Localizations.localeOf(context).languageCode).format(DateTime(selectedYear, selectedMonth))} $selectedYear',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setSheet(() {
                          if (selectedMonth == 12) {
                            selectedMonth = 1;
                            selectedYear++;
                          } else {
                            selectedMonth++;
                          }
                          selectedDay = 1;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: l10n.weekdayAbbr
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                ...List.generate(rows, (rowIdx) {
                  return Row(
                    children: List.generate(7, (colIdx) {
                      final dayOffset = rowIdx * 7 - startOffset + colIdx;
                      final dayNum = 1 + dayOffset;
                      final inMonth = dayNum >= 1 && dayNum <= daysInMonth;
                      final isSelected = inMonth && selectedDay == dayNum;
                      final isToday =
                          inMonth &&
                          today.year == selectedYear &&
                          today.month == selectedMonth &&
                          today.day == dayNum;
                      return Expanded(
                        child: inMonth
                            ? GestureDetector(
                                onTap: () =>
                                    setSheet(() => selectedDay = dayNum),
                                child: Container(
                                  height: 36,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF17A2B8)
                                        : isToday
                                        ? const Color(
                                            0xFF17A2B8,
                                          ).withValues(alpha: 0.15)
                                        : null,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                          ? const Color(0xFF17A2B8)
                                          : Colors.black87,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      );
                    }),
                  );
                }),
              ],
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Título
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF17A2B8),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.viewPeriod,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _periodMode = mode;
                          _selectedDate = mode == 3
                              ? DateTime(
                                  selectedYear,
                                  selectedMonth,
                                  selectedDay,
                                )
                              : DateTime(selectedYear, selectedMonth);
                          _selectedWeekStart = selectedWeekStart;
                        });
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.apply),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17A2B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _modeTab(
                        l10n.yearTab,
                        0,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                      _modeTab(
                        l10n.monthTab,
                        1,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                      _modeTab(
                        l10n.weekTab,
                        2,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                      _modeTab(
                        l10n.dayTab,
                        3,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Año
                if (mode == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setSheet(() => selectedYear--),
                      ),
                      Text(
                        '$selectedYear',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17A2B8),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setSheet(() => selectedYear++),
                      ),
                    ],
                  ),

                // ── Mes
                if (mode == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setSheet(() => selectedYear--),
                      ),
                      Text(
                        '$selectedYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setSheet(() => selectedYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.0,
                    children: List.generate(12, (i) {
                      final isSelected = selectedMonth == i + 1;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedMonth = i + 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF17A2B8)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            DateFormat(
                              'MMM',
                              'es',
                            ).format(DateTime(2000, i + 1)),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],

                // ── Semana
                if (mode == 2) buildWeekCalendar(),

                // ── Día
                if (mode == 3) buildDayCalendar(),

                const SizedBox(height: 16),

                // Resumen del rango
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17A2B8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        size: 18,
                        color: Color(0xFF17A2B8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rangeText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF17A2B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // EXPORTACIÓN: selector de período + PDF + CSV
  // ─────────────────────────────────────────────

  void _showExportPicker({required bool isPdf}) {
    final l10n = AppLocalizations.of(context);
    int mode = 1; // 0=Año, 1=Mes, 2=Semana
    int selectedYear = _selectedDate.year;
    int selectedMonth = _selectedDate.month;

    // Lunes de la semana actual por defecto
    final now = DateTime.now();
    DateTime selectedWeekStart = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    // Si el lunes cae en mes anterior, ajustar
    int calendarYear = selectedWeekStart.year;
    int calendarMonth = selectedWeekStart.month;

    // Vehículos seleccionados para exportar (vacío = todos)
    List<String> selectedVehicleIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          // Calcular rango según el modo
          DateTime start, end;
          String label;
          if (mode == 0) {
            start = DateTime(selectedYear, 1, 1);
            end = DateTime(selectedYear, 12, 31, 23, 59, 59);
            label = '$selectedYear';
          } else if (mode == 1) {
            start = DateTime(selectedYear, selectedMonth, 1);
            end = DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59);
            label =
                '${DateFormat('MMMM', Localizations.localeOf(context).languageCode).format(DateTime(selectedYear, selectedMonth))}_$selectedYear';
          } else {
            start = selectedWeekStart;
            end = selectedWeekStart.add(
              const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
            );
            label =
                'Semana_${DateFormat('dd-MM-yyyy').format(selectedWeekStart)}';
          }

          // ── Contenido de la semana (mini-calendario) ──────────────────
          Widget buildWeekCalendar() {
            final firstDay = DateTime(calendarYear, calendarMonth, 1);
            final daysInMonth = DateTime(
              calendarYear,
              calendarMonth + 1,
              0,
            ).day;
            // Ajustar para que la primera celda sea lunes
            final startOffset = firstDay.weekday - 1; // 0=lun, 6=dom
            final totalCells = startOffset + daysInMonth;
            final rows = (totalCells / 7).ceil();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navegación de mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setSheet(() {
                          if (calendarMonth == 1) {
                            calendarMonth = 12;
                            calendarYear--;
                          } else {
                            calendarMonth--;
                          }
                        });
                      },
                    ),
                    Text(
                      '${DateFormat('MMMM', Localizations.localeOf(context).languageCode).format(DateTime(calendarYear, calendarMonth))} $calendarYear',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setSheet(() {
                          if (calendarMonth == 12) {
                            calendarMonth = 1;
                            calendarYear++;
                          } else {
                            calendarMonth++;
                          }
                        });
                      },
                    ),
                  ],
                ),
                // Cabecera días
                Row(
                  children: l10n.weekdayAbbr
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 4),
                // Filas de semanas
                ...List.generate(rows, (rowIdx) {
                  // Lunes de esta fila
                  final mondayOffset = rowIdx * 7 - startOffset;
                  final mondayDate = DateTime(
                    calendarYear,
                    calendarMonth,
                    1 + mondayOffset,
                  );

                  final isSelected =
                      selectedWeekStart.year == mondayDate.year &&
                      selectedWeekStart.month == mondayDate.month &&
                      selectedWeekStart.day == mondayDate.day;

                  return GestureDetector(
                    onTap: () {
                      setSheet(() {
                        selectedWeekStart = mondayDate;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF17A2B8).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF17A2B8),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Row(
                        children: List.generate(7, (colIdx) {
                          final dayNum = mondayOffset + colIdx + 1;
                          final isCurrentMonth =
                              dayNum >= 1 && dayNum <= daysInMonth;
                          final dayDate = isCurrentMonth
                              ? DateTime(calendarYear, calendarMonth, dayNum)
                              : null;
                          final isToday =
                              dayDate != null &&
                              dayDate.year == now.year &&
                              dayDate.month == now.month &&
                              dayDate.day == now.day;

                          return Expanded(
                            child: Container(
                              height: 34,
                              alignment: Alignment.center,
                              child: isCurrentMonth
                                  ? Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? const Color(0xFF17A2B8)
                                            : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$dayNum',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isToday
                                              ? Colors.white
                                              : isSelected
                                              ? const Color(0xFF17A2B8)
                                              : Colors.black87,
                                          fontWeight: isToday || isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(),
                            ),
                          );
                        }),
                      ),
                    ),
                  );
                }),
              ],
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Título
                Row(
                  children: [
                    Icon(
                      isPdf
                          ? Icons.picture_as_pdf_outlined
                          : Icons.table_chart_outlined,
                      color: const Color(0xFF17A2B8),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPdf ? l10n.exportPdf : l10n.exportExcelCsv,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        final ids = List<String>.from(selectedVehicleIds);
                        Navigator.pop(ctx);
                        if (isPdf) {
                          _exportToPdf(start, end, label, vehicleIds: ids);
                        } else {
                          _exportToCsv(start, end, label, vehicleIds: ids);
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.confirm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17A2B8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tabs de modo
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _modeTab(
                        l10n.yearTab,
                        0,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                      _modeTab(
                        l10n.monthTab,
                        1,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                      _modeTab(
                        l10n.weekTab,
                        2,
                        mode,
                        (v) => setSheet(() => mode = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Año ─────────────────────────────────────────────────
                if (mode == 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setSheet(() => selectedYear--),
                      ),
                      Text(
                        '$selectedYear',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF17A2B8),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setSheet(() => selectedYear++),
                      ),
                    ],
                  ),

                // ── Mes ─────────────────────────────────────────────────
                if (mode == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setSheet(() => selectedYear--),
                      ),
                      Text(
                        '$selectedYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setSheet(() => selectedYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.0,
                    children: List.generate(12, (i) {
                      final isSelected = selectedMonth == i + 1;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedMonth = i + 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF17A2B8)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            DateFormat(
                              'MMM',
                              'es',
                            ).format(DateTime(2000, i + 1)),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],

                // ── Semana ──────────────────────────────────────────────
                if (mode == 2) buildWeekCalendar(),

                const SizedBox(height: 24),

                // Resumen del período seleccionado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17A2B8).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF17A2B8).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        size: 16,
                        color: Color(0xFF17A2B8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(start)}  →  ${DateFormat('dd/MM/yyyy').format(end)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF17A2B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Selección de vehículos ────────────────────────────
                FutureBuilder<List<Vehicle>>(
                  future: _vehiclesStream.first,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final vehicles = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.vehiclesToInclude,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Chip "Todos"
                            GestureDetector(
                              onTap: () =>
                                  setSheet(() => selectedVehicleIds.clear()),
                              child: _vehicleChip(
                                label: l10n.all,
                                isSelected: selectedVehicleIds.isEmpty,
                                showCheck: false,
                              ),
                            ),
                            // Chip por vehículo
                            ...vehicles.map((v) {
                              final sel = selectedVehicleIds.contains(v.id);
                              return GestureDetector(
                                onTap: () => setSheet(() {
                                  if (sel) {
                                    selectedVehicleIds.remove(v.id);
                                  } else {
                                    selectedVehicleIds.add(v.id);
                                  }
                                }),
                                child: _vehicleChip(
                                  label: v.name,
                                  isSelected: sel,
                                  showCheck: sel,
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _modeTab(
    String label,
    int value,
    int current,
    void Function(int) onSelect,
  ) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF17A2B8) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _vehicleChip({
    required String label,
    required bool isSelected,
    required bool showCheck,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF17A2B8) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF17A2B8) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCheck) ...[
            const Icon(Icons.check, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ── Descargar archivos de comprobante desde Firebase Storage ─────────
  Future<Map<String, List<int>>> _downloadReceiptFiles(
    List<Expense> expenses,
  ) async {
    final Map<String, List<int>> files = {};
    for (final e in expenses) {
      if (e.receiptUrl == null) continue;
      try {
        final resp = await http.get(Uri.parse(e.receiptUrl!));
        if (resp.statusCode == 200) {
          files[e.id] = resp.bodyBytes;
        }
      } catch (_) {
        // Si falla la descarga, se omite el archivo
      }
    }
    return files;
  }

  /// Empaqueta un archivo principal + archivos de comprobante en un ZIP.
  /// Devuelve el File del ZIP creado.
  Future<File> _bundleZip({
    required String zipName,
    required String mainFileName,
    required List<int> mainFileBytes,
    required List<Expense> expensesWithReceipts,
    required Map<String, List<int>> receiptBytes,
    required DateFormat dateFmt,
  }) async {
    final archive = Archive();
    // Archivo principal del reporte
    archive.addFile(
      ArchiveFile(mainFileName, mainFileBytes.length, mainFileBytes),
    );
    // Agregar comprobantes en carpeta "comprobantes/"
    int idx = 0;
    for (final e in expensesWithReceipts) {
      idx++;
      final data = receiptBytes[e.id];
      if (data == null) continue;
      final ext = e.receiptType == 'pdf' ? 'pdf' : 'jpg';
      final safeName = e.vehicleName.replaceAll(RegExp(r'[^\w\s-]'), '');
      final dateStr = dateFmt.format(e.date);
      final fileName = 'comprobantes/${idx}_${safeName}_$dateStr.$ext';
      archive.addFile(ArchiveFile(fileName, data.length, data));
    }
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('ZIP encode failed');
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$zipName');
    await zipFile.writeAsBytes(zipBytes, flush: true);
    return zipFile;
  }

  // ── Exportar PDF ──────────────────────────────────────────────────────
  Future<void> _exportToPdf(
    DateTime start,
    DateTime end,
    String label, {
    List<String> vehicleIds = const [],
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(l10n.generatingPdfProgress),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      var expenses = await _billingService.getExpensesInPeriod(start, end);
      if (vehicleIds.isNotEmpty) {
        expenses = expenses
            .where((e) => vehicleIds.contains(e.vehicleId))
            .toList();
      }
      final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final fmt = NumberFormat('#,##0.00');
      final dateFmt = DateFormat('dd/MM/yyyy');
      final periodLabel = '${dateFmt.format(start)} – ${dateFmt.format(end)}';

      final pdf = pw.Document();
      final teal = PdfColor.fromHex('#17A2B8');
      final lightGrey = PdfColor.fromHex('#F3F4F6');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(36),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l10n.expensesReportTitle,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: teal,
                        ),
                      ),
                      pw.Text(
                        l10n.appName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        l10n.periodLabel,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        periodLabel,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        l10n.generatedOn(dateFmt.format(DateTime.now())),
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: teal, thickness: 1.5),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (ctx) {
            if (expenses.isEmpty) {
              return [
                pw.Center(
                  child: pw.Text(
                    l10n.noExpensesForPeriod,
                    style: pw.TextStyle(color: PdfColors.grey600),
                  ),
                ),
              ];
            }

            final byVehicle = <String, List<Expense>>{};
            for (final e in expenses) {
              byVehicle.putIfAbsent(e.vehicleName, () => []).add(e);
            }

            return [
              // Resumen
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightGrey,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          '${expenses.length}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: teal,
                          ),
                        ),
                        pw.Text(
                          l10n.expensesLabel,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          '${byVehicle.length}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: teal,
                          ),
                        ),
                        pw.Text(
                          l10n.vehicles,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          '\$${fmt.format(total)}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: teal,
                          ),
                        ),
                        pw.Text(
                          l10n.totalMxnLabel,
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Tabla de gastos
              pw.Table(
                border: pw.TableBorder(
                  bottom: const pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  horizontalInside: const pw.BorderSide(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.5),
                  1: const pw.FlexColumnWidth(2.0),
                  2: const pw.FlexColumnWidth(1.8),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: teal),
                    children:
                        [
                              l10n.pdfColVehicle,
                              l10n.pdfColCategory,
                              l10n.pdfColDescription,
                              l10n.pdfColDate,
                              l10n.pdfColAmount,
                            ]
                            .map(
                              (h) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                child: pw.Text(
                                  h,
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  ...expenses.asMap().entries.map((entry) {
                    final isEven = entry.key % 2 == 0;
                    final e = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : lightGrey,
                      ),
                      children:
                          [
                                e.vehicleName,
                                _getCategoryNameStatic(e.category, l10n),
                                e.description ?? '—',
                                dateFmt.format(e.date),
                                '\$${fmt.format(e.amount)}',
                              ]
                              .map(
                                (cell) => pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 5,
                                  ),
                                  child: pw.Text(
                                    cell,
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // Total final
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: teal,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Text(
                    'Total: \$${fmt.format(total)} MXN',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ];
          },
        ),
      );

      // ── Descargar comprobantes de imagen (foto/QR) e integrarlos ──
      final photoExpenses = expenses
          .where(
            (e) =>
                e.receiptUrl != null &&
                (e.receiptType == 'photo' || e.receiptType == 'qr'),
          )
          .toList();
      final Map<String, pw.MemoryImage> receiptImages = {};
      for (final e in photoExpenses) {
        try {
          final resp = await http.get(Uri.parse(e.receiptUrl!));
          if (resp.statusCode == 200) {
            receiptImages[e.id] = pw.MemoryImage(resp.bodyBytes);
          }
        } catch (_) {}
      }

      // Página de comprobantes de imagen embebidas en el PDF
      if (receiptImages.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(36),
            header: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l10n.receiptsLabel,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: teal,
                  ),
                ),
                pw.Divider(color: teal, thickness: 1.5),
                pw.SizedBox(height: 4),
              ],
            ),
            build: (_) {
              final widgets = <pw.Widget>[];
              for (final e in photoExpenses) {
                final img = receiptImages[e.id];
                if (img == null) continue;
                widgets.addAll([
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              e.vehicleName,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.Text(
                              '${_getCategoryNameStatic(e.category, l10n)}  ·  '
                              '${dateFmt.format(e.date)}  ·  '
                              '\$${fmt.format(e.amount)} MXN',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            if (e.description != null &&
                                e.description!.isNotEmpty)
                              pw.Text(
                                e.description!,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.Image(img, width: 340, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  pw.SizedBox(height: 12),
                ]);
              }
              return widgets;
            },
          ),
        );
      }

      // ── Generar PDF del reporte ──
      final pdfBytes = await pdf.save();

      // ── Comprobantes PDF: descargar y empaquetar en ZIP ──
      final allReceiptExpenses = expenses
          .where((e) => e.receiptUrl != null)
          .toList();
      // Solo los de tipo PDF se descargan como archivos aparte
      final pdfReceiptExpenses = allReceiptExpenses
          .where((e) => e.receiptType == 'pdf')
          .toList();

      final tempDir = await getTemporaryDirectory();

      if (pdfReceiptExpenses.isNotEmpty) {
        // Descargar PDFs de comprobantes
        final receiptData = await _downloadReceiptFiles(pdfReceiptExpenses);
        // Empaquetar en ZIP
        final zipFile = await _bundleZip(
          zipName: 'Gastos_$label.zip',
          mainFileName: 'Gastos_$label.pdf',
          mainFileBytes: pdfBytes,
          expensesWithReceipts: pdfReceiptExpenses,
          receiptBytes: receiptData,
          dateFmt: dateFmt,
        );
        messenger.hideCurrentSnackBar();
        await _showExportOptions(
          zipFile,
          'application/zip',
          'Gastos_$label.zip',
          'Reporte de Gastos – $label',
        );
      } else {
        // Sin comprobantes PDF → solo el archivo PDF
        final file = File('${tempDir.path}/Gastos_$label.pdf');
        await file.writeAsBytes(pdfBytes);
        messenger.hideCurrentSnackBar();
        await _showExportOptions(
          file,
          'application/pdf',
          'Gastos_$label.pdf',
          'Reporte de Gastos – $label',
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneratingPdfExport('')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Exportar Excel (HTML) + comprobantes en ZIP ────────────────────────
  Future<void> _exportToCsv(
    DateTime start,
    DateTime end,
    String label, {
    List<String> vehicleIds = const [],
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(l10n.generatingCsvProgress),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      var expenses = await _billingService.getExpensesInPeriod(start, end);
      if (vehicleIds.isNotEmpty) {
        expenses = expenses
            .where((e) => vehicleIds.contains(e.vehicleId))
            .toList();
      }
      final dateFmt = DateFormat('dd/MM/yyyy');
      final numFmt = NumberFormat('#,##0.00');
      final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

      // ── Generar HTML compatible con Excel (UTF-8 con BOM) ──
      final buf = StringBuffer();
      buf.writeln(
        '<html xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:x="urn:schemas-microsoft-com:office:excel" '
        'xmlns="http://www.w3.org/TR/REC-html40">',
      );
      buf.writeln('<head>');
      buf.writeln(
        '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">',
      );
      buf.writeln('<style>');
      buf.writeln('table { border-collapse: collapse; width: 100%; }');
      buf.writeln(
        'th { background-color: #17A2B8; color: white; font-weight: bold; '
        'padding: 8px; border: 1px solid #dee2e6; text-align: left; }',
      );
      buf.writeln(
        'td { padding: 6px 8px; border: 1px solid #dee2e6; vertical-align: top; }',
      );
      buf.writeln(
        '.total-row td { background-color: #17A2B8; color: white; font-weight: bold; }',
      );
      buf.writeln('</style></head><body>');

      // Título
      buf.writeln(
        '<h2 style="color:#17A2B8;">AutoGesti&#243;n Max &#8211; '
        '${_escHtml(l10n.billingAndExpenses)}</h2>',
      );
      buf.writeln(
        '<p>${_escHtml(l10n.periodLabel)}: <b>${_escHtml(label)}</b></p>',
      );

      // Tabla principal
      buf.writeln('<table>');
      buf.writeln('<tr>');
      buf.writeln('<th>${_escHtml(l10n.pdfColVehicle)}</th>');
      buf.writeln('<th>${_escHtml(l10n.pdfColCategory)}</th>');
      buf.writeln('<th>${_escHtml(l10n.pdfColAmount)} (MXN)</th>');
      buf.writeln('<th>${_escHtml(l10n.pdfColDate)}</th>');
      buf.writeln('<th>${_escHtml(l10n.pdfColDescription)}</th>');
      buf.writeln('<th>${_escHtml(l10n.mileage)}</th>');
      buf.writeln('<th>${_escHtml(l10n.receiptsLabel)}</th>');
      buf.writeln('</tr>');

      int receiptIdx = 0;
      for (final e in expenses) {
        buf.writeln('<tr>');
        buf.writeln('<td>${_escHtml(e.vehicleName)}</td>');
        buf.writeln(
          '<td>${_escHtml(_getCategoryNameStatic(e.category, l10n))}</td>',
        );
        buf.writeln('<td>\$${numFmt.format(e.amount)}</td>');
        buf.writeln('<td>${dateFmt.format(e.date)}</td>');
        buf.writeln('<td>${_escHtml(e.description ?? '')}</td>');
        buf.writeln('<td>${e.mileage?.toString() ?? ''}</td>');

        // Columna de comprobante: referencia al archivo en el ZIP
        if (e.receiptUrl != null && e.receiptType != null) {
          receiptIdx++;
          final ext = e.receiptType == 'pdf' ? 'pdf' : 'jpg';
          final safeName = e.vehicleName.replaceAll(RegExp(r'[^\w\s-]'), '');
          final dateStr = dateFmt.format(e.date);
          final refName =
              'comprobantes/${receiptIdx}_${safeName}_$dateStr.$ext';
          if (e.receiptType == 'pdf') {
            buf.writeln('<td>&#128206; ${_escHtml(refName)}</td>');
          } else {
            buf.writeln('<td>&#128247; ${_escHtml(refName)}</td>');
          }
        } else {
          buf.writeln('<td></td>');
        }
        buf.writeln('</tr>');
      }

      // Fila total
      buf.writeln('<tr class="total-row">');
      buf.writeln('<td>TOTAL</td><td></td>');
      buf.writeln('<td>\$${numFmt.format(total)}</td>');
      buf.writeln('<td colspan="4"></td>');
      buf.writeln('</tr>');
      buf.writeln('</table>');
      buf.writeln('</body></html>');

      // Escribir XLS con BOM para codificación UTF-8 correcta
      final htmlContent = buf.toString();
      final xlsBytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(htmlContent)];

      // ── Descargar todos los comprobantes ──
      final receiptExpenses = expenses
          .where((e) => e.receiptUrl != null && e.receiptType != null)
          .toList();

      final tempDir = await getTemporaryDirectory();

      if (receiptExpenses.isNotEmpty) {
        final receiptData = await _downloadReceiptFiles(receiptExpenses);
        final zipFile = await _bundleZip(
          zipName: 'Gastos_$label.zip',
          mainFileName: 'Gastos_$label.xls',
          mainFileBytes: xlsBytes,
          expensesWithReceipts: receiptExpenses,
          receiptBytes: receiptData,
          dateFmt: dateFmt,
        );
        messenger.hideCurrentSnackBar();
        await _showExportOptions(
          zipFile,
          'application/zip',
          'Gastos_$label.zip',
          'Reporte de Gastos – $label',
        );
      } else {
        // Sin comprobantes → solo el archivo Excel
        final file = File('${tempDir.path}/Gastos_$label.xls');
        await file.writeAsBytes(xlsBytes, flush: true);
        messenger.hideCurrentSnackBar();
        await _showExportOptions(
          file,
          'application/vnd.ms-excel',
          'Gastos_$label.xls',
          'Reporte de Gastos – $label',
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.errorGeneratingCsvExport('')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Escapa caracteres HTML especiales
  String _escHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  // ── Opciones de exportación (compartir o guardar en dispositivo) ──────────────────
  Future<void> _showExportOptions(
    File file,
    String mimeType,
    String fileName,
    String subject,
  ) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF17A2B8),
                ),
                title: Text(l10n.share),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Share.shareXFiles([
                    XFile(file.path, mimeType: mimeType),
                  ], subject: subject);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF17A2B8),
                ),
                title: Text(l10n.saveToDevice),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _saveToDevice(file, fileName);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToDevice(File file, String fileName) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      Directory? saveDir;
      if (Platform.isAndroid) {
        // Guardar directo en /storage/emulated/0/Download/
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          // Fallback a carpeta externa de la app
          saveDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
      } else {
        saveDir =
            await getDownloadsDirectory() ?? await getTemporaryDirectory();
      }

      if (saveDir == null) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingFile('No storage directory')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Agregar timestamp para evitar sobreescribir archivos
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
      final baseName = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      final uniqueName = '${baseName}_$ts$ext';
      final savedFile = File('${saveDir.path}/$uniqueName');
      await file.copy(savedFile.path);

      if (!mounted) return;
      // Mostrar ruta corta: solo carpeta + archivo
      final shortPath = Platform.isAndroid
          ? 'Download/$uniqueName'
          : savedFile.path;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.fileSavedSuccess(shortPath)),
          action: SnackBarAction(
            label: l10n.openFile,
            onPressed: () => NativeHelper.openFile(savedFile.path),
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.errorSavingFile('')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper para categorías usando l10n (previamente capturado antes del await)
  String _getCategoryNameStatic(
    ExpenseCategory category,
    AppLocalizations l10n,
  ) {
    switch (category) {
      case ExpenseCategory.fuel:
        return l10n.expenseCatFuel;
      case ExpenseCategory.maintenance:
        return l10n.expenseCatMaintenance;
      case ExpenseCategory.insurance:
        return l10n.expenseCatInsurance;
      case ExpenseCategory.toll:
        return l10n.expenseCatToll;
      case ExpenseCategory.parking:
        return l10n.expenseCatParking;
      case ExpenseCategory.repair:
        return l10n.expenseCatRepair;
      case ExpenseCategory.other:
        return l10n.expenseCatOther;
    }
  }
}

// Pantalla del Scanner QR
class _QRScannerScreen extends StatefulWidget {
  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController(
    autoStart: false,
  );
  bool _isScanning = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStart();
  }

  Future<void> _checkPermissionAndStart() async {
    final status = await NativeHelper.checkPermission('camera');
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      await cameraController.start();
    } else {
      final result = await NativeHelper.requestCameraPermission();
      if (mounted) setState(() => _hasPermission = result.isGranted);
      if (result.isGranted) await cameraController.start();
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanQrTitle),
        backgroundColor: const Color(0xFF17A2B8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: !_hasPermission
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.no_photography,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.cameraPermissionNotGranted,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    if (!_isScanning) return;

                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isEmpty) return;

                    final barcode = barcodes.first;
                    if (barcode.rawValue == null) return;

                    if (mounted) {
                      setState(() {
                        _isScanning = false;
                      });
                    }

                    // Retornar el dato del QR
                    Navigator.pop(context, barcode.rawValue);
                  },
                ),
                // Overlay con guia visual
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyan, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Instrucciones
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.qrPositionInFrame,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
