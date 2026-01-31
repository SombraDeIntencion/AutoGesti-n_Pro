import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/vehicle_list_screen.dart';

/// Widget que maneja la navegación según el estado de autenticación
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Mostrar loading mientras se verifica la autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error al verificar autenticación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Verificar si el usuario está autenticado
        final user = snapshot.data;

        if (user == null) {
          // Usuario no autenticado → mostrar login
          return const LoginScreen();
        } else if (!user.emailVerified) {
          // Usuario autenticado pero email no verificado → pantalla de verificación
          return const EmailVerificationScreen();
        } else {
          // Usuario autenticado y email verificado → mostrar app
          return const VehicleListScreen();
        }
      },
    );
  }
}
