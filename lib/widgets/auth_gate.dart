import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/quiz_analytics_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/language/language_selection_screen.dart';
import '../screens/subscription_onboarding_screen.dart';
import '../widgets/employee_gate.dart';
import '../utils/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Widget que maneja la navegación según el estado de autenticación
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _hasSelectedLocale = false;
  bool _isCheckingLocale = true;
  bool _isCheckingAuth = true;
  User? _initialUser;
  bool _hasError = false;
  final AuthService _authService = AuthService();
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    // Cache del stream de auth para evitar recrearlo en cada build.
    // Filtrar con distinct() para ignorar eventos que solo cambian
    // displayName/photoURL (evita rebuild innecesario al editar perfil).
    _authStream = _authService.authStateChanges.distinct((prev, next) {
      return prev?.uid == next?.uid &&
          prev?.emailVerified == next?.emailVerified;
    });
    // Iniciar la verificación después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAuth();
      }
    });
  }

  /// Verificar sesión al iniciar la app
  /// Esto garantiza que la sesión persistida se restaure correctamente
  Future<void> _initializeAuth() async {
    try {
      // Capturar LocaleService antes de operaciones async
      final localeService = Provider.of<LocaleService>(context, listen: false);

      // 🚀 OPTIMIZACIÓN: Ejecutar locale y auth en paralelo
      final results = await Future.wait([
        _checkLocaleAsync(localeService),
        _checkAuthAsync(),
      ]);

      if (mounted) {
        setState(() {
          _hasSelectedLocale = results[0] as bool;
          _initialUser = results[1] as User?;
          _isCheckingLocale = false;
          _isCheckingAuth = false;
        });
      }
    } catch (e) {
      // Si hay error, asegurarse de quitar los indicadores de carga
      if (mounted) {
        setState(() {
          _isCheckingLocale = false;
          _isCheckingAuth = false;
          _hasError = true;
        });
      }
    }
  }

  /// Verificar locale de forma asíncrona (sin delay innecesario)
  Future<bool> _checkLocaleAsync(LocaleService localeService) async {
    try {
      // SharedPreferences es rápido, no necesita delay artificial
      return await localeService.hasSelectedLocale();
    } catch (e) {
      return false; // Asumir que no hay locale seleccionado
    }
  }

  /// Verificar autenticación de forma asíncrona (con delay mínimo)
  Future<User?> _checkAuthAsync() async {
    try {
      // Breve espera para sincronización de Firebase Auth
      await Future.delayed(const Duration(milliseconds: 50));

      // Verificar sesión persistida
      await _authService.checkPersistedSession();

      return _authService.currentUser;
    } catch (e) {
      return null;
    }
  }

  void _onLanguageSelected() {
    // Callback cuando se selecciona el idioma
    setState(() {
      _hasSelectedLocale = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si hubo un error durante la inicialización
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al inicializar la aplicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Por favor, reinicia la aplicación'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _isCheckingLocale = true;
                    _isCheckingAuth = true;
                  });
                  _initializeAuth();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // 🚀 OPTIMIZACIÓN: Loading mejorado con branding durante inicialización
    if (_isCheckingLocale || _isCheckingAuth) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.1),
                AppTheme.secondaryCyan.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de la app
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                // Indicador de carga
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si no ha seleccionado idioma, mostrar selector
    if (!_hasSelectedLocale) {
      return LanguageSelectionScreen(
        isInitialSetup: true,
        onLanguageSelected: _onLanguageSelected,
      );
    }

    // Si ya seleccionó idioma, verificar autenticación con StreamBuilder
    // IMPORTANTE: Aunque ya verificamos la sesión inicial, seguimos usando
    // StreamBuilder para reaccionar a cambios de autenticación en tiempo real
    return StreamBuilder<User?>(
      stream: _authStream,
      // Usar el usuario inicial en lugar de null para evitar parpadeos
      initialData: _initialUser,
      builder: (context, snapshot) {
        // Solo mostrar loading si realmente estamos esperando datos nuevos
        // y no tenemos datos iniciales
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null &&
            _initialUser == null) {
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
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n.errorVerifyingAuth,
                        style: Theme.of(context).textTheme.titleLarge,
                      );
                    },
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
          // Usuario autenticado y email verificado → quiz de onboarding si no lo ha hecho
          return _QuizGate(child: const EmployeeGate());
        }
      },
    );
  }
}

/// Widget que verifica si el usuario completó el quiz de onboarding
/// Si no lo ha hecho, muestra el onboarding antes de continuar
class _QuizGate extends StatefulWidget {
  final Widget child;

  const _QuizGate({required this.child});

  @override
  State<_QuizGate> createState() => _QuizGateState();
}

class _QuizGateState extends State<_QuizGate> {
  final QuizAnalyticsService _quizService = QuizAnalyticsService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkQuizStatus();
  }

  Future<void> _checkQuizStatus() async {
    final completed = await _quizService.isQuizCompleted();
    if (mounted) {
      setState(() {
        _isChecking = false;
      });

      // Si no ha completado el quiz, mostrarlo
      if (!completed) {
        _showOnboarding();
      }
    }
  }

  Future<void> _showOnboarding() async {
    // Esperar a que el widget esté construido
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SubscriptionOnboardingScreen(isPostRegistration: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.1),
                AppTheme.secondaryCyan.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
