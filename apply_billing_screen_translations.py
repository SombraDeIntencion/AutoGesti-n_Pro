#!/usr/bin/env python3
"""Comprehensive replacement script for billing_screen.dart - adds l10n support."""
import re

path = r"c:\Dev\FlutterProjects\autogestion_max\lib\screens\billing_screen.dart"

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

original_len = len(content)

# ─────────────────────────────────────────────────────────────
# 1. ADD IMPORT
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "import '../services/vehicle_service.dart';\nimport 'package:uuid/uuid.dart';",
    "import '../services/vehicle_service.dart';\nimport 'package:uuid/uuid.dart';\nimport '../l10n/app_localizations.dart';"
)

# ─────────────────────────────────────────────────────────────
# 2. build() - add l10n + replace app header strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Widget build(BuildContext context) {\n    return Scaffold(",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    return Scaffold("
)

# App header: 'AutoGestion Max' (only in the Text widget in the header)
content = content.replace(
    "                        Text(\n                          'AutoGestion Max',\n                          style: const TextStyle(\n                            fontSize: 20,\n                            fontWeight: FontWeight.bold,\n                            color: Colors.white,\n                            height: 1.2,\n                          ),\n                        ),",
    "                        Text(\n                          l10n.appName,\n                          style: const TextStyle(\n                            fontSize: 20,\n                            fontWeight: FontWeight.bold,\n                            color: Colors.white,\n                            height: 1.2,\n                          ),\n                        ),"
)

content = content.replace(
    "                        Text(\n                          'Gestión de Flotilla de Vehículos',\n                          style: const TextStyle(\n                            fontSize: 12,\n                            color: Colors.white70,\n                            height: 1.3,\n                          ),\n                        ),",
    "                        Text(\n                          l10n.appSubtitle,\n                          style: const TextStyle(\n                            fontSize: 12,\n                            color: Colors.white70,\n                            height: 1.3,\n                          ),\n                        ),"
)

# ─────────────────────────────────────────────────────────────
# 3. _buildFeatureCard() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Widget _buildFeatureCard() {\n    return Container(",
    "  Widget _buildFeatureCard() {\n    final l10n = AppLocalizations.of(context);\n    return Container("
)

content = content.replace(
    "          Text(\n            'Facturación y Gastos',\n            style: const TextStyle(\n              fontSize: 20,\n              fontWeight: FontWeight.bold,\n              color: Colors.black87,\n            ),\n          ),",
    "          Text(\n            l10n.billingAndExpenses,\n            style: const TextStyle(\n              fontSize: 20,\n              fontWeight: FontWeight.bold,\n              color: Colors.black87,\n            ),\n          ),"
)

content = content.replace(
    "          Text(\n            'Gestiona los gastos de tu flotilla de forma rápida y sencilla',\n            style: const TextStyle(\n              fontSize: 14,\n              color: Color(0xFF616161),\n              height: 1.4,\n            ),\n          ),",
    "          Text(\n            l10n.billingDescription,\n            style: const TextStyle(\n              fontSize: 14,\n              color: Color(0xFF616161),\n              height: 1.4,\n            ),\n          ),"
)

# ─────────────────────────────────────────────────────────────
# 4. _buildFiltersSection() - add l10n + filters section
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Widget _buildFiltersSection() {\n    return Container(",
    "  Widget _buildFiltersSection() {\n    final l10n = AppLocalizations.of(context);\n    return Container("
)

# 'Filtros' text in filters section
content = content.replace(
    "              Text(\n                'Filtros',\n                style: const TextStyle(\n                  fontSize: 16,\n                  fontWeight: FontWeight.bold,\n                  color: Colors.black87,\n                ),\n              ),",
    "              Text(\n                l10n.filters,\n                style: const TextStyle(\n                  fontSize: 16,\n                  fontWeight: FontWeight.bold,\n                  color: Colors.black87,\n                ),\n              ),"
)

# 'Vehículo' label in filter section
content = content.replace(
    "              Text(\n                'Vehículo',\n                style: TextStyle(\n                  fontSize: 12,\n                  color: Colors.grey.shade600,\n                  fontWeight: FontWeight.w500,\n                ),\n              ),",
    "              Text(\n                l10n.vehicleSingular,\n                style: TextStyle(\n                  fontSize: 12,\n                  color: Colors.grey.shade600,\n                  fontWeight: FontWeight.w500,\n                ),\n              ),"
)

# buttonLabel inside _buildFiltersSection for vehicles
content = content.replace(
    "                    if (_selectedVehicleIds.isEmpty) {\n                      return 'Todos los vehículos';\n                    }",
    "                    if (_selectedVehicleIds.isEmpty) {\n                      return l10n.allVehicles;\n                    }"
)

content = content.replace(
    "                    return '${_selectedVehicleIds.length} vehículos';",
    "                    return '${_selectedVehicleIds.length} ${l10n.vehicles}';"
)

# 'Vehículos' dialog title (in filter section vehicle picker)
content = content.replace(
    "                                      const Padding(\n                                        padding: EdgeInsets.symmetric(\n                                          horizontal: 20,\n                                        ),\n                                        child: Text(\n                                          'Vehículos',\n                                          style: TextStyle(\n                                            fontSize: 17,\n                                            fontWeight: FontWeight.w600,\n                                          ),\n                                        ),\n                                      ),",
    "                                      Padding(\n                                        padding: const EdgeInsets.symmetric(\n                                          horizontal: 20,\n                                        ),\n                                        child: Text(\n                                          l10n.vehicles,\n                                          style: const TextStyle(\n                                            fontSize: 17,\n                                            fontWeight: FontWeight.w600,\n                                          ),\n                                        ),\n                                      ),"
)

# Search hint in filter section vehicle picker (Buscar por nombre, placa, marca...)
content = content.replace(
    "                                            hintText:\n                                                'Buscar por nombre, placa, marca…',",
    "                                            hintText:\n                                                l10n.searchNamePlateBrand,"
)

# 'Todos los vehículos' checkbox in filter section
content = content.replace(
    "                                      CheckboxListTile(\n                                        dense: true,\n                                        title: const Text(\n                                          'Todos los vehículos',\n                                        ),",
    "                                      CheckboxListTile(\n                                        dense: true,\n                                        title: Text(\n                                          l10n.allVehicles,\n                                        ),"
)

# 'Sin coincidencias' in filter section vehicle list
content = content.replace(
    "                                            ? const Center(\n                                                child: Text(\n                                                  'Sin coincidencias',\n                                                  style: TextStyle(\n                                                    color: Colors.grey,\n                                                    fontSize: 13,\n                                                  ),\n                                                ),\n                                              )\n                                            : ListView.builder(\n                                                shrinkWrap: false,",
    "                                            ? Center(\n                                                child: Text(\n                                                  l10n.noMatches,\n                                                  style: const TextStyle(\n                                                    color: Colors.grey,\n                                                    fontSize: 13,\n                                                  ),\n                                                ),\n                                              )\n                                            : ListView.builder(\n                                                shrinkWrap: false,"
)

# 'Listo' button in filter section
content = content.replace(
    "                                          child: const Text('Listo'),",
    "                                          child: Text(l10n.done),"
)

# Categories dialog title
content = content.replace(
    "                        title: const Text(\n                          'Categorías',\n                          style: TextStyle(fontSize: 16),\n                        ),",
    "                        title: Text(\n                          l10n.categoriesLabel,\n                          style: const TextStyle(fontSize: 16),\n                        ),"
)

# 'Todas las categorías'
content = content.replace(
    "                              title: const Text('Todas las categorías'),",
    "                              title: Text(l10n.allCategories),"
)

# Category button display text
content = content.replace(
    "                          _selectedCategories.isEmpty\n                              ? 'Todas las categorías'\n                              : _selectedCategories.length == 1\n                              ? _getCategoryName(_selectedCategories.first)\n                              : '${_selectedCategories.length} categorías',",
    "                          _selectedCategories.isEmpty\n                              ? l10n.allCategories\n                              : _selectedCategories.length == 1\n                              ? _getCategoryName(_selectedCategories.first)\n                              : '${_selectedCategories.length} ${l10n.categoriesLabel}',"
)

# ─────────────────────────────────────────────────────────────
# 5. _buildExportButton() - add l10n + replace labels
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Widget _buildExportButton() {\n    return Row(",
    "  Widget _buildExportButton() {\n    final l10n = AppLocalizations.of(context);\n    return Row("
)

content = content.replace(
    "        _buildExportChip(\n          label: 'Exportar PDF',",
    "        _buildExportChip(\n          label: l10n.exportPdf,"
)

content = content.replace(
    "        _buildExportChip(\n          label: 'Exportar Excel',",
    "        _buildExportChip(\n          label: l10n.exportExcel,"
)

# ─────────────────────────────────────────────────────────────
# 6. _buildSummaryCards() - strings in StreamBuilder
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "      builder: (context, snapshot) {\n        final expenses = (snapshot.data ?? []).where((e) {\n          if (e.date.isBefore(_firstDayOfMonth) ||",
    "      builder: (context, snapshot) {\n        final l10n = AppLocalizations.of(context);\n        final expenses = (snapshot.data ?? []).where((e) {\n          if (e.date.isBefore(_firstDayOfMonth) ||",
    # This replaces first occurrence (in _buildSummaryCards's StreamBuilder)
)

content = content.replace(
    "              'Total $_periodDisplayLabel',\n              '\\$${NumberFormat('#,##0.00').format(total)}',\n              '$expenseCount gastos registrados',",
    "              l10n.totalPeriod(_periodDisplayLabel),\n              '\\$${NumberFormat('#,##0.00').format(total)}',\n              l10n.expensesRegisteredN(expenseCount),"
)

content = content.replace(
    "              'Vehículos activos',\n              vehicles.toString(),\n              'con gastos registrados',",
    "              l10n.activeVehicles,\n              vehicles.toString(),\n              l10n.withExpensesRegistered,"
)

content = content.replace(
    "              'Categorías',\n              categories.toString(),\n              'tipos de gasto',",
    "              l10n.categoriesLabel,\n              categories.toString(),\n              l10n.expenseTypes,"
)

# ─────────────────────────────────────────────────────────────
# 7. _buildExpensesByVehicleChart() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "          return _buildEmptyChart(\n            'Gastos por Vehículo',\n            'No hay gastos registrados en este período',\n          );",
    "          return _buildEmptyChart(\n            l10n.expensesByVehicle,\n            l10n.noExpensesInPeriod,\n          );"
)

# Replace the chart title 'Gastos por Vehículo' (in the non-empty case - there may be a Text or similar)
# Let me check: the chart titles are inside the chart container when non-empty
# From context, the charts use a Container with padding and a title Text inside
# For the vehicle chart, look for the non-empty branch title
content = content.replace(
    "  Widget _buildExpensesByVehicleChart() {\n    return StreamBuilder<List<Expense>>(",
    "  Widget _buildExpensesByVehicleChart() {\n    return StreamBuilder<List<Expense>>("
)

# ─────────────────────────────────────────────────────────────
# 8. _buildExpensesByCategoryChart() - find empty chart call
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "          return _buildEmptyChart(\n            'Distribución por Categoría',\n            'No hay gastos registrados en este período',\n          );",
    "          return _buildEmptyChart(\n            l10n.distributionByCategory,\n            l10n.noExpensesInPeriod,\n          );"
)

# ─────────────────────────────────────────────────────────────
# 9. _buildRecentExpensesList() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
# 'Gastos Recientes' appears 3 times (in two empty states and one non-empty state)
# 'No hay gastos registrados' 
# 'No hay gastos con los filtros seleccionados'

# Replace all occurrences of the title 'Gastos Recientes' in the Text widget context
content = content.replace(
    "                  'Gastos Recientes',\n                  style: const TextStyle(\n                    fontSize: 18,\n                    fontWeight: FontWeight.bold,\n                    color: Color(0xFF37474F),\n                  ),",
    "                  l10n.recentExpenses,\n                  style: const TextStyle(\n                    fontSize: 18,\n                    fontWeight: FontWeight.bold,\n                    color: Color(0xFF37474F),\n                  ),"
)

content = content.replace(
    "                      Text(\n                        'No hay gastos registrados',\n                        style: TextStyle(color: Colors.grey, fontSize: 16),\n                      ),",
    "                      Text(\n                        l10n.noExpenses,\n                        style: TextStyle(color: Colors.grey, fontSize: 16),\n                      ),"
)

content = content.replace(
    "                      Text(\n                        'No hay gastos con los filtros seleccionados',\n                        style: TextStyle(color: Colors.grey, fontSize: 16),\n                        textAlign: TextAlign.center,\n                      ),",
    "                      Text(\n                        l10n.noExpensesWithFilters,\n                        style: TextStyle(color: Colors.grey, fontSize: 16),\n                        textAlign: TextAlign.center,\n                      ),"
)

# The StreamBuilder in _buildRecentExpensesList needs l10n
# But the above replacements use `l10n` which must be in scope
# The StreamBuilder builder has (context, snapshot) so we add l10n inside it
content = content.replace(
    "  Widget _buildRecentExpensesList() {\n    return StreamBuilder<List<Expense>>(\n      stream: _billingService.getExpenses(),\n      builder: (context, snapshot) {",
    "  Widget _buildRecentExpensesList() {\n    return StreamBuilder<List<Expense>>(\n      stream: _billingService.getExpenses(),\n      builder: (context, snapshot) {\n        final l10n = AppLocalizations.of(context);"
)

# ─────────────────────────────────────────────────────────────
# 10. _showAddExpenseDialog() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  void _showAddExpenseDialog(BuildContext context) {\n    final amountController = TextEditingController();",
    "  void _showAddExpenseDialog(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    final amountController = TextEditingController();"
)

# 'Registrar Gasto' dialog title
content = content.replace(
    "                              child: Text(\n                                'Registrar Gasto',\n                                style: TextStyle(\n                                  fontSize: 20,\n                                  fontWeight: FontWeight.bold,\n                                  color: const Color(0xFF17A2B8),\n                                ),\n                              ),",
    "                              child: Text(\n                                l10n.registerExpense,\n                                style: const TextStyle(\n                                  fontSize: 20,\n                                  fontWeight: FontWeight.bold,\n                                  color: Color(0xFF17A2B8),\n                                ),\n                              ),"
)

# 'Llena los campos para registrar un nuevo gasto.'
content = content.replace(
    "                        Text(\n                          'Llena los campos para registrar un nuevo gasto.',\n                          style: TextStyle(\n                            fontSize: 13,\n                            color: Colors.grey.shade600,\n                          ),\n                        ),",
    "                        Text(\n                          l10n.registerExpenseSubtitle,\n                          style: TextStyle(\n                            fontSize: 13,\n                            color: Colors.grey.shade600,\n                          ),\n                        ),"
)

# 'No hay vehículos disponibles'
content = content.replace(
    "                              if (!snapshot.hasData || snapshot.data!.isEmpty) {\n                                return const Text(\n                                  'No hay vehículos disponibles',\n                                );",
    "                              if (!snapshot.hasData || snapshot.data!.isEmpty) {\n                                return Text(\n                                  l10n.noVehiclesAvailable,\n                                );"
)

# 'Vehículo *' label in add expense
content = content.replace(
    "                                children: [\n                                  const Text(\n                                    'Vehículo *',\n                                    style: TextStyle(\n                                      fontWeight: FontWeight.w500,\n                                      fontSize: 14,\n                                    ),\n                                  ),",
    "                                children: [\n                                  Text(\n                                    l10n.vehicleRequired,\n                                    style: const TextStyle(\n                                      fontWeight: FontWeight.w500,\n                                      fontSize: 14,\n                                    ),\n                                  ),"
)

# 'Selecciona un vehículo' dialog title
content = content.replace(
    "                                                      const Padding(\n                                                        padding:\n                                                            EdgeInsets.symmetric(\n                                                              horizontal: 20,\n                                                            ),\n                                                        child: Text(\n                                                          'Selecciona un vehículo',\n                                                          style: TextStyle(\n                                                            fontSize: 16,\n                                                            fontWeight:\n                                                                FontWeight.w600,\n                                                          ),\n                                                        ),\n                                                      ),",
    "                                                      Padding(\n                                                        padding:\n                                                            const EdgeInsets.symmetric(\n                                                              horizontal: 20,\n                                                            ),\n                                                        child: Text(\n                                                          l10n.selectAVehicle,\n                                                          style: const TextStyle(\n                                                            fontSize: 16,\n                                                            fontWeight:\n                                                                FontWeight.w600,\n                                                          ),\n                                                        ),\n                                                      ),"
)

# 'Buscar por nombre, placa…' in add expense vehicle picker
content = content.replace(
    "                                                          hintText:\n                                                                'Buscar por nombre, placa…',",
    "                                                          hintText:\n                                                                l10n.searchNamePlate,"
)

# 'Sin coincidencias' in add expense vehicle picker
content = content.replace(
    "                                                        child: filtered.isEmpty\n                                                            ? const Center(\n                                                                child: Text(\n                                                                  'Sin coincidencias',\n                                                                  style: TextStyle(\n                                                                    color: Colors\n                                                                        .grey,\n                                                                    fontSize:\n                                                                        13,\n                                                                  ),\n                                                                ),\n                                                              )",
    "                                                        child: filtered.isEmpty\n                                                            ? Center(\n                                                                child: Text(\n                                                                  l10n.noMatches,\n                                                                  style: const TextStyle(\n                                                                    color: Colors\n                                                                        .grey,\n                                                                    fontSize:\n                                                                        13,\n                                                                  ),\n                                                                ),\n                                                              )"
)

# 'Cancelar' in add expense vehicle picker dialog
content = content.replace(
    "                                                          child: TextButton(\n                                                            onPressed: () =>\n                                                                Navigator.pop(\n                                                                  ctx,\n                                                                ),\n                                                            child: const Text(\n                                                              'Cancelar',\n                                                            ),\n                                                          ),",
    "                                                          child: TextButton(\n                                                            onPressed: () =>\n                                                                Navigator.pop(\n                                                                  ctx,\n                                                                ),\n                                                            child: Text(\n                                                              l10n.cancel,\n                                                            ),\n                                                          ),"
)

# vehicle picker hint text (now use the selected vehicle name or hint)
content = content.replace(
    "                                            selectedVehicle?.name ??\n                                                  'Selecciona un vehículo',",
    "                                            selectedVehicle?.name ??\n                                                  l10n.selectAVehicle,"
)

# 'Categoría *' label in add expense
content = content.replace(
    "                          const Text(\n                            'Categoría *',\n                            style: TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),\n                          const SizedBox(height: 8),\n                          DropdownButtonFormField",
    "                          Text(\n                            l10n.categoryRequired,\n                            style: const TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),\n                          const SizedBox(height: 8),\n                          DropdownButtonFormField"
)

# 'Monto (MXN) *' label in add expense
content = content.replace(
    "                          const Text(\n                            'Monto (MXN) *',\n                            style: TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),",
    "                          Text(\n                            l10n.amountMxnRequired,\n                            style: const TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),"
)

# 'Fecha *' label in add expense
content = content.replace(
    "                          const Text(\n                            'Fecha *',\n                            style: TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),\n                          const SizedBox(height: 8),\n                          InkWell(",
    "                          Text(\n                            l10n.dateRequired,\n                            style: const TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),\n                          const SizedBox(height: 8),\n                          InkWell("
)

# 'Kilometraje (opcional)'
content = content.replace(
    "                          const Text(\n                            'Kilometraje (opcional)',\n                            style: TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),",
    "                          Text(\n                            l10n.mileageOptional,\n                            style: const TextStyle(\n                              fontWeight: FontWeight.w500,\n                              fontSize: 14,\n                            ),\n                          ),"
)

# Odometer photo label and 'Adjunta' label
content = content.replace(
    "                                        Text(\n                                          'Foto del odómetro',\n                                          style: TextStyle(\n                                            fontWeight: FontWeight.w500,\n                                            fontSize: 14,\n                                          ),\n                                        ),\n                                        SizedBox(height: 4),\n                                        Text(\n                                          'Adjunta',\n                                          style: TextStyle(\n                                            fontSize: 12,\n                                            color: Colors.green,\n                                          ),\n                                        ),",
    "                                        Text(\n                                          l10n.odometerPhotoLabel,\n                                          style: const TextStyle(\n                                            fontWeight: FontWeight.w500,\n                                            fontSize: 14,\n                                          ),\n                                        ),\n                                        const SizedBox(height: 4),\n                                        Text(\n                                          l10n.attachedLabel,\n                                          style: TextStyle(\n                                            fontSize: 12,\n                                            color: Colors.green,\n                                          ),\n                                        ),"
)

# 'Comprobante (opcional)'
content = content.replace(
    "                                const Text(\n                                  'Comprobante (opcional)',\n                                  style: TextStyle(\n                                    fontWeight: FontWeight.w500,\n                                    fontSize: 14,\n                                  ),\n                                ),",
    "                                Text(\n                                  l10n.receiptOptional,\n                                  style: const TextStyle(\n                                    fontWeight: FontWeight.w500,\n                                    fontSize: 14,\n                                  ),\n                                ),"
)

# 'Escanear QR' button text
content = content.replace(
    "                                              Text(\n                                                'Escanear QR',\n                                                style: TextStyle(\n                                                  color: Colors.white,\n                                                  fontSize: 11,\n                                                  fontWeight: FontWeight.w500,\n                                                ),\n                                              ),",
    "                                              Text(\n                                                l10n.scanQr,\n                                                style: const TextStyle(\n                                                  color: Colors.white,\n                                                  fontSize: 11,\n                                                  fontWeight: FontWeight.w500,\n                                                ),\n                                              ),"
)

# camera permission QR snackbar
content = content.replace(
    "                                            ScaffoldMessenger.of(\n                                              context,\n                                            ).showSnackBar(\n                                              SnackBar(\n                                                content: const Text(\n                                                  'Se necesita permiso de cámara para escanear QR',\n                                                ),",
    "                                            ScaffoldMessenger.of(\n                                              context,\n                                            ).showSnackBar(\n                                              SnackBar(\n                                                content: Text(\n                                                  l10n.cameraPermissionQr,\n                                                ),"
)

# QR SAT detected snackbar
content = content.replace(
    "                                                  const SnackBar(\n                                                    content: Text(\n                                                      '✅ Factura SAT detectada — monto y emisor auto-llenados',\n                                                    ),",
    "                                                  SnackBar(\n                                                    content: Text(\n                                                      l10n.qrSatDetected,\n                                                    ),"
)

# QR custom detected snackbar
content = content.replace(
    "                                                  const SnackBar(\n                                                    content: Text(\n                                                      '✅ QR personalizado detectado — campos auto-llenados',\n                                                    ),",
    "                                                  SnackBar(\n                                                    content: Text(\n                                                      l10n.qrCustomDetected,\n                                                    ),"
)

# QR saved as text snackbar
content = content.replace(
    "                                                  const SnackBar(\n                                                    content: Text(\n                                                      'QR guardado como comprobante de texto',\n                                                    ),",
    "                                                  SnackBar(\n                                                    content: Text(\n                                                      l10n.qrSavedAsText,\n                                                    ),"
)

# Error al capturar foto in receipt area
content = content.replace(
    "                                              ScaffoldMessenger.of(\n                                                context,\n                                              ).showSnackBar(\n                                                SnackBar(\n                                                  content: Text(\n                                                    'Error al capturar foto: $e',\n                                                  ),\n                                                  backgroundColor: Colors.red,\n                                                ),\n                                              );\n                                            }\n                                          }\n                                        },\n                                        child: Container(\n                                          padding: const EdgeInsets.symmetric(\n                                            vertical: 16,\n                                          ),\n                                          decoration: BoxDecoration(\n                                            gradient: const LinearGradient(\n                                              colors: [\n                                                Color(0xFFFF6F00),",
    "                                              ScaffoldMessenger.of(\n                                                context,\n                                              ).showSnackBar(\n                                                SnackBar(\n                                                  content: Text(\n                                                    l10n.errorCapturingPhotoExpense('$e'),\n                                                  ),\n                                                  backgroundColor: Colors.red,\n                                                ),\n                                              );\n                                            }\n                                          }\n                                        },\n                                        child: Container(\n                                          padding: const EdgeInsets.symmetric(\n                                            vertical: 16,\n                                          ),\n                                          decoration: BoxDecoration(\n                                            gradient: const LinearGradient(\n                                              colors: [\n                                                Color(0xFFFF6F00),"
)

# Error al seleccionar PDF
content = content.replace(
    "                                              ScaffoldMessenger.of(\n                                                context,\n                                              ).showSnackBar(\n                                                SnackBar(\n                                                  content: Text(\n                                                    'Error al seleccionar PDF: $e',\n                                                  ),\n                                                  backgroundColor: Colors.red,\n                                                ),\n                                              );",
    "                                              ScaffoldMessenger.of(\n                                                context,\n                                              ).showSnackBar(\n                                                SnackBar(\n                                                  content: Text(\n                                                    l10n.errorSelectingPdfFile('$e'),\n                                                  ),\n                                                  backgroundColor: Colors.red,\n                                                ),\n                                              );"
)

# 'QR Escaneado' title
content = content.replace(
    "                                              const Text(\n                                                'QR Escaneado',\n                                                style: TextStyle(\n                                                  fontWeight: FontWeight.w500,\n                                                  fontSize: 14,\n                                                ),\n                                              ),",
    "                                              Text(\n                                                l10n.qrScanned,\n                                                style: const TextStyle(\n                                                  fontWeight: FontWeight.w500,\n                                                  fontSize: 14,\n                                                ),\n                                              ),"
)

# 'Foto del recibo' / 'PDF del recibo' 
content = content.replace(
    "                                              Text(\n                                                receiptType == 'photo'\n                                                    ? 'Foto del recibo'\n                                                    : 'PDF del recibo',\n                                                style: const TextStyle(\n                                                  fontWeight: FontWeight.w500,\n                                                  fontSize: 14,\n                                                ),\n                                              ),",
    "                                              Text(\n                                                receiptType == 'photo'\n                                                    ? l10n.receiptPhotoLabel\n                                                    : l10n.receiptPdfLabel,\n                                                style: const TextStyle(\n                                                  fontWeight: FontWeight.w500,\n                                                  fontSize: 14,\n                                                ),\n                                              ),"
)

# 'Adjunta' / 'Adjunto' in receipt preview
content = content.replace(
    "                                              Text(\n                                                receiptType == 'photo'\n                                                    ? 'Adjunta'\n                                                    : receiptFileName ??\n                                                          'Adjunto',",
    "                                              Text(\n                                                receiptType == 'photo'\n                                                    ? l10n.attachedLabel\n                                                    : receiptFileName ??\n                                                          l10n.attachedLabel,"
)

# 'Ingresa un monto válido' snackbar
content = content.replace(
    "                                  const SnackBar(\n                                    content: Text('Ingresa un monto válido'),\n                                  ),",
    "                                  SnackBar(\n                                    content: Text(l10n.enterValidAmount),\n                                  ),"
)

# 'Gasto agregado correctamente' snackbar
content = content.replace(
    "                                  messenger.showSnackBar(\n                                    const SnackBar(\n                                      content: Text(\n                                        'Gasto agregado correctamente',\n                                      ),\n                                      backgroundColor: Colors.green,\n                                    ),\n                                  );",
    "                                  messenger.showSnackBar(\n                                    SnackBar(\n                                      content: Text(\n                                        l10n.expenseAddedSuccessfully,\n                                      ),\n                                      backgroundColor: Colors.green,\n                                    ),\n                                  );"
)

# 'Error al guardar gasto: $e' snackbar
content = content.replace(
    "                                  messenger.showSnackBar(\n                                    SnackBar(\n                                      content: Text(\n                                        'Error al guardar gasto: $e',\n                                      ),\n                                      backgroundColor: Colors.red,\n                                    ),\n                                  );",
    "                                  messenger.showSnackBar(\n                                    SnackBar(\n                                      content: Text(\n                                        l10n.errorSavingExpense('$e'),\n                                      ),\n                                      backgroundColor: Colors.red,\n                                    ),\n                                  );"
)

# 'Guardar' save button
content = content.replace(
    "                            child: const Text('Guardar'),\n                          ),\n                        ),\n                      ],\n                    ),\n                  ),\n                ],\n              ),\n            ),\n          );\n        },\n      ),\n    ).whenComplete(disposeControllers);",
    "                            child: Text(l10n.save),\n                          ),\n                        ),\n                      ],\n                    ),\n                  ),\n                ],\n              ),\n            ),\n          );\n        },\n      ),\n    ).whenComplete(disposeControllers);"
)

# ─────────────────────────────────────────────────────────────
# 11. _showExpenseDetails() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  void _showExpenseDetails(Expense expense) {\n    showDialog(\n      context: context,\n      builder: (context) => AlertDialog(\n        title: const Text('Detalles del Gasto'),",
    "  void _showExpenseDetails(Expense expense) {\n    final l10n = AppLocalizations.of(context);\n    showDialog(\n      context: context,\n      builder: (context) => AlertDialog(\n        title: Text(l10n.expenseDetails),"
)

content = content.replace(
    "            _buildDetailRow('Vehículo', expense.vehicleName),\n            _buildDetailRow('Categoría', _getCategoryName(expense.category)),\n            _buildDetailRow(\n              'Monto',",
    "            _buildDetailRow(l10n.vehicleSingular, expense.vehicleName),\n            _buildDetailRow(l10n.categoryLabel, _getCategoryName(expense.category)),\n            _buildDetailRow(\n              l10n.amountLabel,"
)

content = content.replace(
    "            _buildDetailRow(\n              'Fecha',\n              DateFormat('dd MMMM yyyy', 'es').format(expense.date),\n            ),\n            if (expense.description != null)\n              _buildDetailRow('Descripción', expense.description!),",
    "            _buildDetailRow(\n              l10n.date,\n              DateFormat('dd MMMM yyyy', 'es').format(expense.date),\n            ),\n            if (expense.description != null)\n              _buildDetailRow(l10n.descriptionLabel, expense.description!),"
)

content = content.replace(
    "                  title: const Text('Confirmar eliminación'),\n                  content: const Text('¿Estás seguro de eliminar este gasto?'),",
    "                  title: Text(l10n.confirmDeleteExpenseTitle),\n                  content: Text(l10n.confirmDeleteExpense),"
)

# Cancel in delete dialog
content = content.replace(
    "                      onPressed: () => Navigator.pop(context, false),\n                      child: const Text('Cancelar'),\n                    ),\n                    ElevatedButton(\n                      onPressed: () => Navigator.pop(context, true),\n                      style: ElevatedButton.styleFrom(\n                        backgroundColor: Colors.red,\n                        foregroundColor: Colors.white,\n                      ),\n                      child: const Text('Eliminar'),\n                    ),",
    "                      onPressed: () => Navigator.pop(context, false),\n                      child: Text(l10n.cancel),\n                    ),\n                    ElevatedButton(\n                      onPressed: () => Navigator.pop(context, true),\n                      style: ElevatedButton.styleFrom(\n                        backgroundColor: Colors.red,\n                        foregroundColor: Colors.white,\n                      ),\n                      child: Text(l10n.delete),\n                    ),"
)

# 'Gasto eliminado correctamente' snackbar in details
content = content.replace(
    "                    ScaffoldMessenger.of(context).showSnackBar(\n                      const SnackBar(\n                        content: Text('Gasto eliminado correctamente'),\n                      ),\n                    );",
    "                    ScaffoldMessenger.of(context).showSnackBar(\n                      SnackBar(\n                        content: Text(l10n.expenseDeletedSuccessfully),\n                      ),\n                    );"
)

# 'Eliminar' button in details dialog
content = content.replace(
    "            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),",
    "            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),"
)

# 'Cerrar' button in details dialog
content = content.replace(
    "            child: const Text('Cerrar'),\n          ),\n        ],\n      ),\n    );\n  }\n\n  Widget _buildDetailRow",
    "            child: Text(l10n.close),\n          ),\n        ],\n      ),\n    );\n  }\n\n  Widget _buildDetailRow"
)

# ─────────────────────────────────────────────────────────────
# 12. _showPeriodPicker() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  void _showPeriodPicker() {\n    int mode = _periodMode;",
    "  void _showPeriodPicker() {\n    final l10n = AppLocalizations.of(context);\n    int mode = _periodMode;"
)

# Weekday abbreviations in period picker's buildWeekCalendar
content = content.replace(
    "                Row(\n                  children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']\n                      .map(\n                        (d) => Expanded(\n                          child: Center(\n                            child: Text(\n                              d,\n                              style: TextStyle(\n                                fontSize: 11,\n                                fontWeight: FontWeight.w600,\n                                color: Colors.grey.shade500,\n                              ),\n                            ),\n                          ),\n                        ),\n                      )\n                      .toList(),\n                ),\n                const SizedBox(height: 4),\n                ...List.generate(rows, (rowIdx) {\n                  final mondayOffset = rowIdx * 7 - startOffset;\n                  final mondayDate = DateTime(\n                    calendarYear,\n                    calendarMonth,\n                    1 + mondayOffset,\n                  );\n                  final isSelected =\n                      selectedWeekStart.year == mondayDate.year &&\n                      selectedWeekStart.month == mondayDate.month &&\n                      selectedWeekStart.day == mondayDate.day;",
    "                Row(\n                  children: l10n.weekdayAbbr\n                      .map(\n                        (d) => Expanded(\n                          child: Center(\n                            child: Text(\n                              d,\n                              style: TextStyle(\n                                fontSize: 11,\n                                fontWeight: FontWeight.w600,\n                                color: Colors.grey.shade500,\n                              ),\n                            ),\n                          ),\n                        ),\n                      )\n                      .toList(),\n                ),\n                const SizedBox(height: 4),\n                ...List.generate(rows, (rowIdx) {\n                  final mondayOffset = rowIdx * 7 - startOffset;\n                  final mondayDate = DateTime(\n                    calendarYear,\n                    calendarMonth,\n                    1 + mondayOffset,\n                  );\n                  final isSelected =\n                      selectedWeekStart.year == mondayDate.year &&\n                      selectedWeekStart.month == mondayDate.month &&\n                      selectedWeekStart.day == mondayDate.day;"
)

# Weekday abbreviations in period picker's buildDayCalendar
content = content.replace(
    "                Row(\n                  children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']\n                      .map(\n                        (d) => Expanded(\n                          child: Center(\n                            child: Text(\n                              d,\n                              style: TextStyle(\n                                fontSize: 11,\n                                fontWeight: FontWeight.w600,\n                                color: Colors.grey.shade500,\n                              ),\n                            ),\n                          ),\n                        ),\n                      )\n                      .toList(),\n                ),\n                const SizedBox(height: 4),\n                ...List.generate(rows, (rowIdx) {\n                  return Row(",
    "                Row(\n                  children: l10n.weekdayAbbr\n                      .map(\n                        (d) => Expanded(\n                          child: Center(\n                            child: Text(\n                              d,\n                              style: TextStyle(\n                                fontSize: 11,\n                                fontWeight: FontWeight.w600,\n                                color: Colors.grey.shade500,\n                              ),\n                            ),\n                          ),\n                        ),\n                      )\n                      .toList(),\n                ),\n                const SizedBox(height: 4),\n                ...List.generate(rows, (rowIdx) {\n                  return Row("
)

# 'Ver período' title
content = content.replace(
    "                    const Text(\n                      'Ver período',\n                      style: TextStyle(\n                        fontSize: 18,\n                        fontWeight: FontWeight.bold,\n                        color: Colors.black87,\n                      ),\n                    ),",
    "                    Text(\n                      l10n.viewPeriod,\n                      style: const TextStyle(\n                        fontSize: 18,\n                        fontWeight: FontWeight.bold,\n                        color: Colors.black87,\n                      ),\n                    ),"
)

# 'Aplicar' button in period picker
content = content.replace(
    "                      label: const Text('Aplicar'),\n                      style: ElevatedButton.styleFrom(\n                        backgroundColor: const Color(0xFF17A2B8),\n                        foregroundColor: Colors.white,\n                        padding: const EdgeInsets.symmetric(\n                          horizontal: 14,\n                          vertical: 8,\n                        ),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(20),\n                        ),\n                        textStyle: const TextStyle(\n                          fontSize: 13,\n                          fontWeight: FontWeight.w600,\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n                const SizedBox(height: 20),\n                // Tabs\n                Container(",
    "                      label: Text(l10n.apply),\n                      style: ElevatedButton.styleFrom(\n                        backgroundColor: const Color(0xFF17A2B8),\n                        foregroundColor: Colors.white,\n                        padding: const EdgeInsets.symmetric(\n                          horizontal: 14,\n                          vertical: 8,\n                        ),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(20),\n                        ),\n                        textStyle: const TextStyle(\n                          fontSize: 13,\n                          fontWeight: FontWeight.w600,\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n                const SizedBox(height: 20),\n                // Tabs\n                Container("
)

# Mode tabs in period picker
content = content.replace(
    "                  _modeTab('Año', 0, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab('Mes', 1, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab(\n                        'Semana',\n                        2,\n                        mode,\n                        (v) => setSheet(() => mode = v),\n                      ),\n                      _modeTab('Día', 3, mode, (v) => setSheet(() => mode = v)),",
    "                  _modeTab(l10n.yearTab, 0, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab(l10n.monthTab, 1, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab(\n                        l10n.weekTab,\n                        2,\n                        mode,\n                        (v) => setSheet(() => mode = v),\n                      ),\n                      _modeTab(l10n.dayTab, 3, mode, (v) => setSheet(() => mode = v)),"
)

# ─────────────────────────────────────────────────────────────
# 13. _showExportPicker() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  void _showExportPicker({required bool isPdf}) {\n    int mode = 1; // 0=Año, 1=Mes, 2=Semana",
    "  void _showExportPicker({required bool isPdf}) {\n    final l10n = AppLocalizations.of(context);\n    int mode = 1; // 0=Año, 1=Mes, 2=Semana"
)

# 'Exportar PDF' / 'Exportar Excel (CSV)' title in export picker
content = content.replace(
    "                    Text(\n                      isPdf ? 'Exportar PDF' : 'Exportar Excel (CSV)',",
    "                    Text(\n                      isPdf ? l10n.exportPdf : l10n.exportExcelCsv,"
)

# 'Confirmar' button in export picker
content = content.replace(
    "                      label: const Text('Confirmar'),\n                      style: ElevatedButton.styleFrom(\n                        backgroundColor: const Color(0xFF17A2B8),\n                        foregroundColor: Colors.white,\n                        padding: const EdgeInsets.symmetric(\n                          horizontal: 14,\n                          vertical: 8,\n                        ),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(20),\n                        ),\n                        textStyle: const TextStyle(\n                          fontSize: 13,\n                          fontWeight: FontWeight.w600,\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n                const SizedBox(height: 20),\n                // Tabs de modo",
    "                      label: Text(l10n.confirm),\n                      style: ElevatedButton.styleFrom(\n                        backgroundColor: const Color(0xFF17A2B8),\n                        foregroundColor: Colors.white,\n                        padding: const EdgeInsets.symmetric(\n                          horizontal: 14,\n                          vertical: 8,\n                        ),\n                        shape: RoundedRectangleBorder(\n                          borderRadius: BorderRadius.circular(20),\n                        ),\n                        textStyle: const TextStyle(\n                          fontSize: 13,\n                          fontWeight: FontWeight.w600,\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n                const SizedBox(height: 20),\n                // Tabs de modo"
)

# Weekday abbreviations in export picker week calendar
content = content.replace(
    "                // Cabecera días\n                Row(\n                  children: ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']",
    "                // Cabecera días\n                Row(\n                  children: l10n.weekdayAbbr"
)

# Mode tabs in export picker
content = content.replace(
    "                      _modeTab('Año', 0, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab('Mes', 1, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab(\n                        'Semana',\n                        2,\n                        mode,\n                        (v) => setSheet(() => mode = v),\n                      ),",
    "                      _modeTab(l10n.yearTab, 0, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab(l10n.monthTab, 1, mode, (v) => setSheet(() => mode = v)),\n                      _modeTab(\n                        l10n.weekTab,\n                        2,\n                        mode,\n                        (v) => setSheet(() => mode = v),\n                      ),"
)

# 'Vehículos a incluir' in export picker
content = content.replace(
    "                        const Text(\n                          'Vehículos a incluir',\n                          style: TextStyle(\n                            fontSize: 13,\n                            fontWeight: FontWeight.w600,\n                            color: Colors.black54,\n                          ),\n                        ),",
    "                        Text(\n                          l10n.vehiclesToInclude,\n                          style: const TextStyle(\n                            fontSize: 13,\n                            fontWeight: FontWeight.w600,\n                            color: Colors.black54,\n                          ),\n                        ),"
)

# 'Todos' chip in export picker
content = content.replace(
    "                              child: _vehicleChip(\n                                label: 'Todos',\n                                isSelected: selectedVehicleIds.isEmpty,\n                                showCheck: false,\n                              ),",
    "                              child: _vehicleChip(\n                                label: l10n.all,\n                                isSelected: selectedVehicleIds.isEmpty,\n                                showCheck: false,\n                              ),"
)

# ─────────────────────────────────────────────────────────────
# 14. _exportToPdf() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Future<void> _exportToPdf(\n    DateTime start,\n    DateTime end,\n    String label, {\n    List<String> vehicleIds = const [],\n  }) async {\n    final messenger = ScaffoldMessenger.of(context);",
    "  Future<void> _exportToPdf(\n    DateTime start,\n    DateTime end,\n    String label, {\n    List<String> vehicleIds = const [],\n  }) async {\n    final l10n = AppLocalizations.of(context);\n    final messenger = ScaffoldMessenger.of(context);"
)

# 'Generando PDF...' - replace const SnackBar + text
content = content.replace(
    "    messenger.showSnackBar(\n      const SnackBar(\n        content: Row(\n          children: [\n            SizedBox(\n              width: 18,\n              height: 18,\n              child: CircularProgressIndicator(\n                strokeWidth: 2,\n                color: Colors.white,\n              ),\n            ),\n            SizedBox(width: 12),\n            Text('Generando PDF...'),\n          ],\n        ),\n        duration: Duration(seconds: 10),\n      ),\n    );",
    "    messenger.showSnackBar(\n      SnackBar(\n        content: Row(\n          children: [\n            const SizedBox(\n              width: 18,\n              height: 18,\n              child: CircularProgressIndicator(\n                strokeWidth: 2,\n                color: Colors.white,\n              ),\n            ),\n            const SizedBox(width: 12),\n            Text(l10n.generatingPdfProgress),\n          ],\n        ),\n        duration: const Duration(seconds: 10),\n      ),\n    );"
)

# 'Reporte de Gastos' PDF title
content = content.replace(
    "                      pw.Text(\n                        'Reporte de Gastos',\n                        style: pw.TextStyle(\n                          fontSize: 22,\n                          fontWeight: pw.FontWeight.bold,\n                          color: teal,\n                        ),\n                      ),\n                      pw.Text(\n                        'AutoGestion Max',",
    "                      pw.Text(\n                        l10n.expensesReportTitle,\n                        style: pw.TextStyle(\n                          fontSize: 22,\n                          fontWeight: pw.FontWeight.bold,\n                          color: teal,\n                        ),\n                      ),\n                      pw.Text(\n                        l10n.appName,"
)

# 'Período' in PDF header
content = content.replace(
    "                      pw.Text(\n                        'Período',\n                        style: pw.TextStyle(\n                          fontSize: 9,\n                          color: PdfColors.grey600,\n                        ),\n                      ),",
    "                      pw.Text(\n                        l10n.periodLabel,\n                        style: pw.TextStyle(\n                          fontSize: 9,\n                          color: PdfColors.grey600,\n                        ),\n                      ),"
)

# 'Generado: ${dateFmt.format(DateTime.now())}'
content = content.replace(
    "                      pw.Text(\n                        'Generado: ${dateFmt.format(DateTime.now())}',",
    "                      pw.Text(\n                        l10n.generatedOn(dateFmt.format(DateTime.now())),"
)

# 'No hay gastos en el período seleccionado.'
content = content.replace(
    "                pw.Text(\n                    'No hay gastos en el período seleccionado.',\n                    style: pw.TextStyle(color: PdfColors.grey600),\n                  ),",
    "                pw.Text(\n                    l10n.noExpensesForPeriod,\n                    style: pw.TextStyle(color: PdfColors.grey600),\n                  ),"
)

# 'Gastos' count label in PDF summary
content = content.replace(
    "                        pw.Text(\n                          'Gastos',\n                          style: pw.TextStyle(\n                            fontSize: 9,\n                            color: PdfColors.grey600,\n                          ),\n                        ),\n                      ],\n                    ),\n                    pw.Column(\n                      children: [\n                        pw.Text(\n                          '${byVehicle.length}',",
    "                        pw.Text(\n                          l10n.expensesLabel,\n                          style: pw.TextStyle(\n                            fontSize: 9,\n                            color: PdfColors.grey600,\n                          ),\n                        ),\n                      ],\n                    ),\n                    pw.Column(\n                      children: [\n                        pw.Text(\n                          '${byVehicle.length}',"
)

# 'Vehículos' count in PDF summary
content = content.replace(
    "                        pw.Text(\n                          'Vehículos',\n                          style: pw.TextStyle(\n                            fontSize: 9,\n                            color: PdfColors.grey600,\n                          ),\n                        ),\n                      ],\n                    ),\n                    pw.Column(\n                      children: [\n                        pw.Text(\n                          '\\$${fmt.format(total)}',",
    "                        pw.Text(\n                          l10n.vehicles,\n                          style: pw.TextStyle(\n                            fontSize: 9,\n                            color: PdfColors.grey600,\n                          ),\n                        ),\n                      ],\n                    ),\n                    pw.Column(\n                      children: [\n                        pw.Text(\n                          '\\$${fmt.format(total)}',"
)

# 'Total MXN' in PDF summary
content = content.replace(
    "                        pw.Text(\n                          'Total MXN',\n                          style: pw.TextStyle(\n                            fontSize: 9,\n                            color: PdfColors.grey600,\n                          ),\n                        ),\n                      ],\n                    ),\n                  ],\n                ),\n              ),\n              pw.SizedBox(height: 16),",
    "                        pw.Text(\n                          l10n.totalMxnLabel,\n                          style: pw.TextStyle(\n                            fontSize: 9,\n                            color: PdfColors.grey600,\n                          ),\n                        ),\n                      ],\n                    ),\n                  ],\n                ),\n              ),\n              pw.SizedBox(height: 16),"
)

# PDF table header columns
content = content.replace(
    "                    children: [\n                  // Encabezado\n                  pw.TableRow(\n                    decoration: pw.BoxDecoration(color: teal),\n                    children:\n                        [\n                              'Vehículo',\n                              'Categoría',\n                              'Descripción',\n                              'Fecha',\n                              'Monto',\n                            ]",
    "                    children: [\n                  // Encabezado\n                  pw.TableRow(\n                    decoration: pw.BoxDecoration(color: teal),\n                    children:\n                        [\n                              l10n.pdfColVehicle,\n                              l10n.pdfColCategory,\n                              l10n.pdfColDescription,\n                              l10n.pdfColDate,\n                              l10n.pdfColAmount,\n                            ]"
)

# _getCategoryNameStatic calls in _exportToPdf (the cell data row)
content = content.replace(
    "                                e.vehicleName,\n                                _getCategoryNameStatic(e.category),\n                                e.description ?? '—',\n                                dateFmt.format(e.date),\n                                '\\$${fmt.format(e.amount)}',\n                              ]\n                              .map(\n                                (cell) => pw.Padding(\n                                  padding: const pw.EdgeInsets.symmetric(\n                                    horizontal: 6,\n                                    vertical: 5,\n                                  ),\n                                  child: pw.Text(\n                                    cell,\n                                    style: const pw.TextStyle(fontSize: 9),\n                                  ),\n                                ),\n                              )\n                              .toList(),",
    "                                e.vehicleName,\n                                _getCategoryNameStatic(e.category, l10n),\n                                e.description ?? '—',\n                                dateFmt.format(e.date),\n                                '\\$${fmt.format(e.amount)}',\n                              ]\n                              .map(\n                                (cell) => pw.Padding(\n                                  padding: const pw.EdgeInsets.symmetric(\n                                    horizontal: 6,\n                                    vertical: 5,\n                                  ),\n                                  child: pw.Text(\n                                    cell,\n                                    style: const pw.TextStyle(fontSize: 9),\n                                  ),\n                                ),\n                              )\n                              .toList(),"
)

# 'Comprobantes' page header in PDF
content = content.replace(
    "                pw.Text(\n                  'Comprobantes',\n                  style: pw.TextStyle(\n                    fontSize: 18,\n                    fontWeight: pw.FontWeight.bold,\n                    color: teal,\n                  ),\n                ),",
    "                pw.Text(\n                  l10n.receiptsLabel,\n                  style: pw.TextStyle(\n                    fontSize: 18,\n                    fontWeight: pw.FontWeight.bold,\n                    color: teal,\n                  ),\n                ),"
)

# _getCategoryNameStatic in comprobantes page
content = content.replace(
    "              '${_getCategoryNameStatic(e.category)}  ·  '\n                              '${DateFormat('dd/MM/yyyy').format(e.date)}  ·  '\n                              '\\$${NumberFormat('#,##0.00').format(e.amount)} MXN',",
    "              '${_getCategoryNameStatic(e.category, l10n)}  ·  '\n                              '${DateFormat('dd/MM/yyyy').format(e.date)}  ·  '\n                              '\\$${NumberFormat('#,##0.00').format(e.amount)} MXN',"
)

# 'Error al generar PDF: $e'
content = content.replace(
    "          content: Text('Error al generar PDF: $e'),",
    "          content: Text(l10n.errorGeneratingPdfExport('$e')),"
)

# ─────────────────────────────────────────────────────────────
# 15. _exportToCsv() - add l10n + replace strings
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Future<void> _exportToCsv(\n    DateTime start,\n    DateTime end,\n    String label, {\n    List<String> vehicleIds = const [],\n  }) async {\n    final messenger = ScaffoldMessenger.of(context);",
    "  Future<void> _exportToCsv(\n    DateTime start,\n    DateTime end,\n    String label, {\n    List<String> vehicleIds = const [],\n  }) async {\n    final l10n = AppLocalizations.of(context);\n    final messenger = ScaffoldMessenger.of(context);"
)

# 'Generando CSV...' - replace const SnackBar + text
content = content.replace(
    "    messenger.showSnackBar(\n      const SnackBar(\n        content: Row(\n          children: [\n            SizedBox(\n              width: 18,\n              height: 18,\n              child: CircularProgressIndicator(\n                strokeWidth: 2,\n                color: Colors.white,\n              ),\n            ),\n            SizedBox(width: 12),\n            Text('Generando CSV...'),\n          ],\n        ),\n        duration: Duration(seconds: 10),\n      ),\n    );",
    "    messenger.showSnackBar(\n      SnackBar(\n        content: Row(\n          children: [\n            const SizedBox(\n              width: 18,\n              height: 18,\n              child: CircularProgressIndicator(\n                strokeWidth: 2,\n                color: Colors.white,\n              ),\n            ),\n            const SizedBox(width: 12),\n            Text(l10n.generatingCsvProgress),\n          ],\n        ),\n        duration: const Duration(seconds: 10),\n      ),\n    );"
)

# CSV column headers - skip (labels include formatting like " *" and " (opcional)")
# _getCategoryNameStatic in CSV
content = content.replace(
    "            esc(_getCategoryNameStatic(e.category)),",
    "            esc(_getCategoryNameStatic(e.category, l10n)),"
)

# 'Error al generar CSV: $e'
content = content.replace(
    "          content: Text('Error al generar CSV: $e'),",
    "          content: Text(l10n.errorGeneratingCsvExport('$e')),"
)

# ─────────────────────────────────────────────────────────────
# 16. _getCategoryName() - use AppLocalizations
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  String _getCategoryName(ExpenseCategory category) {\n    switch (category) {\n      case ExpenseCategory.fuel:\n        return 'Combustible';\n      case ExpenseCategory.maintenance:\n        return 'Mantenimiento';\n      case ExpenseCategory.insurance:\n        return 'Seguro';\n      case ExpenseCategory.toll:\n        return 'Peaje';\n      case ExpenseCategory.parking:\n        return 'Estacionamiento';\n      case ExpenseCategory.repair:\n        return 'Reparación';\n      case ExpenseCategory.other:\n        return 'Otro';\n    }\n  }",
    "  String _getCategoryName(ExpenseCategory category) {\n    final l10n = AppLocalizations.of(context);\n    switch (category) {\n      case ExpenseCategory.fuel:\n        return l10n.expenseCatFuel;\n      case ExpenseCategory.maintenance:\n        return l10n.expenseCatMaintenance;\n      case ExpenseCategory.insurance:\n        return l10n.expenseCatInsurance;\n      case ExpenseCategory.toll:\n        return l10n.expenseCatToll;\n      case ExpenseCategory.parking:\n        return l10n.expenseCatParking;\n      case ExpenseCategory.repair:\n        return l10n.expenseCatRepair;\n      case ExpenseCategory.other:\n        return l10n.expenseCatOther;\n    }\n  }"
)

# ─────────────────────────────────────────────────────────────
# 17. _getCategoryNameStatic() - accept AppLocalizations param
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  // Helper estático (sin contexto) para usar dentro de isolates de PDF\n  String _getCategoryNameStatic(ExpenseCategory category) {\n    switch (category) {\n      case ExpenseCategory.fuel:\n        return 'Combustible';\n      case ExpenseCategory.maintenance:\n        return 'Mantenimiento';\n      case ExpenseCategory.insurance:\n        return 'Seguro';\n      case ExpenseCategory.toll:\n        return 'Peaje';\n      case ExpenseCategory.parking:\n        return 'Estacionamiento';\n      case ExpenseCategory.repair:\n        return 'Reparación';\n      case ExpenseCategory.other:\n        return 'Otro';\n    }\n  }",
    "  // Helper para categorías usando l10n (previamente capturado antes del await)\n  String _getCategoryNameStatic(ExpenseCategory category, AppLocalizations l10n) {\n    switch (category) {\n      case ExpenseCategory.fuel:\n        return l10n.expenseCatFuel;\n      case ExpenseCategory.maintenance:\n        return l10n.expenseCatMaintenance;\n      case ExpenseCategory.insurance:\n        return l10n.expenseCatInsurance;\n      case ExpenseCategory.toll:\n        return l10n.expenseCatToll;\n      case ExpenseCategory.parking:\n        return l10n.expenseCatParking;\n      case ExpenseCategory.repair:\n        return l10n.expenseCatRepair;\n      case ExpenseCategory.other:\n        return l10n.expenseCatOther;\n    }\n  }"
)

# ─────────────────────────────────────────────────────────────
# 18. QR Scanner Screen - add l10n
# ─────────────────────────────────────────────────────────────
content = content.replace(
    "  Widget build(BuildContext context) {\n    return Scaffold(\n      appBar: AppBar(\n        title: const Text('Escanear Código QR'),",
    "  Widget build(BuildContext context) {\n    final l10n = AppLocalizations.of(context);\n    return Scaffold(\n      appBar: AppBar(\n        title: Text(l10n.scanQrTitle),"
)

content = content.replace(
    "          ? const Center(\n              child: Column(\n                mainAxisAlignment: MainAxisAlignment.center,\n                children: [\n                  Icon(Icons.no_photography, size: 64, color: Colors.grey),\n                  SizedBox(height: 16),\n                  Text(\n                    'Permiso de cámara no concedido',\n                    style: TextStyle(fontSize: 16, color: Colors.grey),\n                  ),\n                ],\n              ),\n            )",
    "          ? Center(\n              child: Column(\n                mainAxisAlignment: MainAxisAlignment.center,\n                children: [\n                  const Icon(Icons.no_photography, size: 64, color: Colors.grey),\n                  const SizedBox(height: 16),\n                  Text(\n                    l10n.cameraPermissionNotGranted,\n                    style: const TextStyle(fontSize: 16, color: Colors.grey),\n                  ),\n                ],\n              ),\n            )"
)

content = content.replace(
    "                    child: const Text(\n                      'Coloca el código QR dentro del recuadro',\n                      textAlign: TextAlign.center,\n                      style: TextStyle(\n                        color: Colors.white,\n                        fontSize: 16,\n                        fontWeight: FontWeight.w500,\n                      ),\n                    ),",
    "                    child: Text(\n                      l10n.qrPositionInFrame,\n                      textAlign: TextAlign.center,\n                      style: const TextStyle(\n                        color: Colors.white,\n                        fontSize: 16,\n                        fontWeight: FontWeight.w500,\n                      ),\n                    ),"
)

# ─────────────────────────────────────────────────────────────
# VERIFY
# ─────────────────────────────────────────────────────────────
new_len = len(content)
print(f"Original length: {original_len:,} chars")
print(f"New length:      {new_len:,} chars")
print(f"Difference:      {new_len - original_len:+,} chars")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done! File written.")

# Verify import was added
if "import '../l10n/app_localizations.dart';" in content:
    print("✅ AppLocalizations import found")
else:
    print("❌ AppLocalizations import NOT found")

# Count remaining hardcoded Spanish strings (approximate check)
import re
remaining = re.findall(r"'[^']*(?:Facturación|Filtros|Vehículo|Categoría|gastos|Combustible|Peaje|Seguro)[^']*'", content)
print(f"Potential remaining Spanish strings: {len(remaining)}")
for r in remaining[:20]:
    print(f"  {r}")
