import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Widget para monitorear el uso de memoria de la aplicación
/// Útil durante desarrollo para detectar fugas de memoria
class MemoryMonitor extends StatefulWidget {
  final Widget child;

  const MemoryMonitor({super.key, required this.child});

  @override
  State<MemoryMonitor> createState() => _MemoryMonitorState();
}

class _MemoryMonitorState extends State<MemoryMonitor> {
  Timer? _memoryTimer;
  int _checkCount = 0;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _startMemoryMonitoring();
    }
  }

  void _startMemoryMonitoring() {
    // Monitorear cada 2 minutos
    _memoryTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkCount++;
      _logMemoryUsage();

      // Limpiar caché de imágenes cada 10 minutos (cada 5 checks)
      if (_checkCount % 5 == 0) {
        _clearImageCache();
      }
    });
  }

  void _logMemoryUsage() {
    try {
      // Log básico de estado
      developer.log('📊 Memory Check #$_checkCount', name: 'MemoryMonitor');

      // En desarrollo, esto ayuda a detectar patrones de uso
      // Debug logs removed for production
    } catch (e) {
      developer.log('Error al verificar memoria: $e', name: 'MemoryMonitor');
    }
  }

  void _clearImageCache() {
    try {
      // Limpiar caché de imágenes de Flutter
      imageCache.clear();
      imageCache.clearLiveImages();

      developer.log('🧹 Image cache cleared', name: 'MemoryMonitor');

      // Debug logs removed for production
    } catch (e) {
      developer.log('Error al limpiar caché: $e', name: 'MemoryMonitor');
    }
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Utilidades para gestión de memoria
class MemoryUtils {
  /// Limpiar caché de imágenes manualmente
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Configurar límites de caché de imágenes
  static void configureImageCache() {
    // Limitar el tamaño máximo del caché de imágenes
    // Valor por defecto: 1000 imágenes o 100MB
    imageCache.maximumSize = 100; // Reducir a 100 imágenes
    imageCache.maximumSizeBytes = 50 << 20; // Máximo 50MB
  }

  /// Log de información de memoria (solo en debug)
  static void logMemoryInfo(String context) {
    if (kDebugMode) {
      developer.log('Memory check at: $context', name: 'MemoryUtils');
    }
  }
}
