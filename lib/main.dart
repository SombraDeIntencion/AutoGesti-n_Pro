import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/auth_gate.dart';
import 'utils/memory_monitor.dart';
import 'utils/app_theme.dart';

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
  } catch (e) {
    // Error al inicializar Firebase: $e
  }

  runApp(const AutoGestionProApp());
}

class AutoGestionProApp extends StatelessWidget {
  const AutoGestionProApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Envolver la app en MemoryMonitor para detectar fugas de memoria en desarrollo
    return MemoryMonitor(
      child: MaterialApp(
        title: 'Autogestión Max',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
        locale: const Locale('es', 'ES'),
        home: const AuthGate(), // Usar AuthGate para manejar autenticación
      ),
    );
  }
}
