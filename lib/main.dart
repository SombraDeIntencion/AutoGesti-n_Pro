import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'widgets/auth_gate.dart';
import 'utils/memory_monitor.dart';
import 'utils/app_theme.dart';
import 'services/locale_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar límites de caché de imágenes para evitar uso excesivo de memoria
  MemoryUtils.configureImageCache();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firebase inicializado correctamente

    // Configurar persistencia de autenticación
    // IMPORTANTE: En Android/iOS la persistencia LOCAL es automática y no se puede cambiar
    // Solo en Web necesitamos configurarla explícitamente
    try {
      if (kIsWeb) {
        // En Web, configurar persistencia LOCAL para mantener sesión
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }
      // En Android/iOS, la persistencia ya está habilitada por defecto
      // No se hace nada adicional
    } catch (e) {
      // Error configurando persistencia en Web: $e
    }

    // Dar un breve momento para que Firebase Auth restaure la sesión
    // desde el almacenamiento local. userChanges() en AuthGate se encarga
    // del resto de forma reactiva.
    await Future.delayed(const Duration(milliseconds: 200));
  } catch (e) {
    // Error al inicializar Firebase: $e
  }

  // Inicializar LocaleService antes de crear el Provider
  // para evitar que notifyListeners() se dispare durante el setup
  final localeService = LocaleService();
  await localeService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => localeService,
      child: const AutoGestionProApp(),
    ),
  );
}

class AutoGestionProApp extends StatelessWidget {
  const AutoGestionProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleService>(
      builder: (context, localeService, child) {
        // MemoryMonitor activo solo en modo debug para evitar overhead en producción
        final app = MaterialApp(
          title: 'Autogestión Max',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          locale: localeService.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales
              .map((info) => info.locale)
              .toList(),
          home: const AuthGate(),
        );
        return kDebugMode ? MemoryMonitor(child: app) : app;
      },
    );
  }
}
