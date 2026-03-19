import 'package:flutter/material.dart';
import '../screens/employee_selection_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../services/employee_service.dart';

/// Widget que verifica si hay un empleado seleccionado
/// antes de permitir acceso a la app
class EmployeeGate extends StatefulWidget {
  const EmployeeGate({super.key});

  @override
  State<EmployeeGate> createState() => _EmployeeGateState();
}

class _EmployeeGateState extends State<EmployeeGate> {
  final EmployeeService _employeeService = EmployeeService();
  late Future<bool> _hasSelectedRoleFuture;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // 🚀 OPTIMIZACIÓN: Usar Future en lugar de estado para evitar rebuilds
    _hasSelectedRoleFuture = _employeeService.hasSelectedRole();
  }

  Future<void> _navigateToEmployeeSelection() async {
    if (_isNavigating) return; // Evitar múltiples navegaciones simultáneas
    _isNavigating = true;

    // Limpiar cualquier SnackBar anterior antes de navegar
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const EmployeeSelectionScreen()),
    );
    // result es true si seleccionó, null si presionó back
    debugPrint('EmployeeGate: selección resultado=$result');

    _isNavigating = false;

    // Siempre refrescar después de volver, tanto si seleccionó como si no
    if (mounted) {
      setState(() {
        _hasSelectedRoleFuture = _employeeService.hasSelectedRole();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 OPTIMIZACIÓN: Usar FutureBuilder para evitar pantallas de carga innecesarias
    return FutureBuilder<bool>(
      future: _hasSelectedRoleFuture,
      builder: (context, snapshot) {
        // Si está cargando, mostrar loading mínimo
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay un error o no tiene rol seleccionado, navegar a selección
        final hasSelectedRole = snapshot.data ?? false;

        if (!hasSelectedRole) {
          // Navegar a selección de empleado en el siguiente frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _navigateToEmployeeSelection();
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si ya tiene sesión, ir directo a la pantalla principal
        return const MainNavigationScreen();
      },
    );
  }
}
