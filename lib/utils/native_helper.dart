import 'package:flutter/services.dart';

/// Estado del permiso
enum NativePermissionStatus {
  granted,
  denied,
  permanentlyDenied;

  bool get isGranted => this == NativePermissionStatus.granted;
  bool get isDenied => this == NativePermissionStatus.denied;
  bool get isPermanentlyDenied => this == NativePermissionStatus.permanentlyDenied;
}

/// Helper nativo para permisos y apertura de archivos.
/// Reemplaza permission_handler y open_filex para evitar que se inyecten
/// permisos READ_MEDIA_* en el manifiesto y DEX de Android.
class NativeHelper {
  static const _channel = MethodChannel('com.mahondev.autogestionmax/native_helper');

  /// Verificar estado de un permiso sin solicitarlo.
  /// [type] puede ser: 'camera', 'storage', 'photos'
  static Future<NativePermissionStatus> checkPermission(String type) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'checkPermission',
        {'permission': type},
      );
      return _parseStatus(result);
    } catch (_) {
      return NativePermissionStatus.denied;
    }
  }

  /// Solicitar un permiso. Retorna el estado resultante.
  /// [type] puede ser: 'camera', 'storage', 'photos'
  static Future<NativePermissionStatus> requestPermission(String type) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'requestPermission',
        {'permission': type},
      );
      return _parseStatus(result);
    } catch (_) {
      return NativePermissionStatus.denied;
    }
  }

  /// Solicitar permiso de cámara
  static Future<NativePermissionStatus> requestCameraPermission() =>
      requestPermission('camera');

  /// Verificar si el permiso de cámara está concedido
  static Future<bool> isCameraGranted() async {
    final status = await checkPermission('camera');
    return status.isGranted;
  }

  /// Solicitar permiso de almacenamiento (solo Android < 13)
  static Future<NativePermissionStatus> requestStoragePermission() =>
      requestPermission('storage');

  /// Verificar si el permiso de almacenamiento está concedido
  static Future<bool> isStorageGranted() async {
    final status = await checkPermission('storage');
    return status.isGranted;
  }

  /// Abrir la configuración de la app en el sistema
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {
      // Silently fail if settings can't be opened
    }
  }

  /// Abrir un archivo con el visor del sistema.
  /// Retorna true si se abrió correctamente.
  static Future<bool> openFile(String path, {String? mimeType}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openFile',
        {
          'path': path,
          if (mimeType != null) 'mimeType': mimeType,
        },
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static NativePermissionStatus _parseStatus(String? status) {
    switch (status) {
      case 'granted':
        return NativePermissionStatus.granted;
      case 'permanentlyDenied':
        return NativePermissionStatus.permanentlyDenied;
      case 'denied':
      default:
        return NativePermissionStatus.denied;
    }
  }
}
