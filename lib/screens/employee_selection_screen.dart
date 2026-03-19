import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/employee_service.dart';
import '../l10n/app_localizations.dart';

/// Pantalla para que los empleados se identifiquen antes de usar la app
class EmployeeSelectionScreen extends StatefulWidget {
  const EmployeeSelectionScreen({super.key});

  @override
  State<EmployeeSelectionScreen> createState() =>
      _EmployeeSelectionScreenState();
}

class _EmployeeSelectionScreenState extends State<EmployeeSelectionScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _continueAsManager() async {
    if (!mounted) return;

    final controller = TextEditingController();
    String? password;

    // Esperar al siguiente frame para evitar problemas con el context
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // Mostrar diálogo para verificar contraseña
    password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.managerVerification),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogL10n.enterPasswordToContinueAsManager,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: dialogL10n.password,
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) =>
                    Navigator.pop(dialogContext, controller.text),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogL10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(dialogL10n.verify),
            ),
          ],
        );
      },
    );

    // Esperar a que el diálogo se cierre completamente antes de disponer el controller
    await Future.delayed(const Duration(milliseconds: 100));
    controller.dispose();

    if (password == null || password.isEmpty) return;

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Reautenticar al usuario con su contraseña
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        throw Exception(l10n.couldNotVerifyUser);
      }

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Contraseña correcta - limpiar empleado y continuar
      await _employeeService.clearCurrentEmployee();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.welcomeManager),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'wrong-password'
            ? l10n.incorrectPassword
            : l10n.verificationError;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectEmployee() async {
    final l10n = AppLocalizations.of(context);
    final employeeId = _idController.text.trim();

    if (employeeId.isEmpty) {
      setState(() => _error = l10n.enterEmployeeId);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employee = await _employeeService.getEmployee(employeeId);

      if (employee == null) {
        setState(() {
          _error = l10n.invalidEmployeeNumber;
          _isLoading = false;
        });
        return;
      }

      // Guardar empleado actual
      await _employeeService.setCurrentEmployee(employee);

      if (!mounted) return;

      // Confirmar y volver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.welcome}, ${employee.name}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false, // Evitar que se cierre con el botón back
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Mostrar diálogo de confirmación para salir de la app
          showDialog(
            context: context,
            builder: (dialogContext) {
              final dialogL10n = AppLocalizations.of(dialogContext);
              return AlertDialog(
                title: Text(dialogL10n.exitApp),
                content: Text(dialogL10n.exitAppConfirmation),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(dialogL10n.cancel),
                  ),
                  TextButton(
                    onPressed: () {
                      // Cerrar diálogo
                      Navigator.pop(dialogContext);
                      // Salir de la aplicación
                      SystemNavigator.pop();
                    },
                    child: Text(dialogL10n.exit),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF17A2B8),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo o icono
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF17A2B8),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título
                  Text(
                    l10n.employeeIdentification,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterEmployeeNumber,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Card con formulario
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Campo de número de empleado
                          TextField(
                            controller: _idController,
                            decoration: InputDecoration(
                              labelText: l10n.employeeNumber,
                              hintText: l10n.employeeIdHint,
                              prefixIcon: const Icon(Icons.badge),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorText: _error,
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _selectEmployee(),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 24),

                          // Botón de continuar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _selectEmployee,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF17A2B8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      l10n.continueButton,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón para continuar como gerente - Mejorado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _continueAsManager,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.admin_panel_settings, size: 24),
                      label: Text(
                        l10n.continueAsManager,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.requiresPasswordVerification,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
