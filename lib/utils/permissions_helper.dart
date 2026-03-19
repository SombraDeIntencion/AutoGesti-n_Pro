import 'package:flutter/material.dart';
import 'dart:io';
import 'native_helper.dart';

/// Helper para gestionar permisos de la aplicación
class PermissionsHelper {
  /// Solicitar permiso de cámara
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await NativeHelper.checkPermission('camera');

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await NativeHelper.requestCameraPermission();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Permiso de Cámara',
          'La aplicación necesita acceso a la cámara para tomar fotos de tus vehículos y documentos.',
        );
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Permiso de Cámara',
          'La aplicación necesita acceso a la cámara para tomar fotos de tus vehículos y documentos.',
        );
      }
      return false;
    }

    return false;
  }

  /// Solicitar permiso de fotos/galería
  /// En Android 13+ el Photo Picker no requiere permisos explícitos.
  /// En iOS se solicita permiso de fotos nativamente.
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android: image_picker usa el Photo Picker del sistema,
      // no necesita READ_MEDIA_IMAGES ni READ_MEDIA_VIDEO
      return true;
    }

    if (!Platform.isIOS) {
      return true; // No se necesita en otras plataformas
    }

    // Solo iOS necesita solicitar permiso de fotos
    final status = await NativeHelper.checkPermission('photos');

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await NativeHelper.requestPermission('photos');
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Permiso de Fotos',
          'La aplicación necesita acceso a tus fotos para que puedas seleccionar imágenes de tus vehículos y documentos.',
        );
      }
      return false;
    }

    return false;
  }

  /// Solicitar permiso de almacenamiento (para Android < 13)
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await NativeHelper.checkPermission('storage');

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await NativeHelper.requestStoragePermission();
      if (result.isGranted) return true;

      if (result.isPermanentlyDenied && context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Permiso de Almacenamiento',
          'La aplicación necesita acceso al almacenamiento para guardar fotos y documentos.',
        );
      }
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDeniedDialog(
          context,
          'Permiso de Almacenamiento',
          'La aplicación necesita acceso al almacenamiento para guardar fotos y documentos.',
        );
      }
      return false;
    }

    return false;
  }

  /// Solicitar todos los permisos necesarios para fotos
  static Future<bool> requestPhotoPermissions(BuildContext context) async {
    final cameraGranted = await requestCameraPermission(context);
    if (!context.mounted) return false;
    final photosGranted = await requestPhotosPermission(context);

    return cameraGranted && photosGranted;
  }

  /// Mostrar diálogo cuando el permiso está denegado permanentemente
  static void _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            const Text(
              'Para habilitar este permiso:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Ve a Configuración de la app'),
            const Text('2. Toca "Permisos"'),
            const Text('3. Habilita el permiso necesario'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NativeHelper.openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  /// Verificar si todos los permisos de fotos están concedidos
  static Future<bool> hasPhotoPermissions() async {
    final cameraGranted = await NativeHelper.isCameraGranted();

    if (Platform.isAndroid) {
      // En Android, image_picker usa Photo Picker, no necesita permiso de fotos
      return cameraGranted;
    }

    final photosStatus = await NativeHelper.checkPermission('photos');
    return cameraGranted && photosStatus.isGranted;
  }

  /// Mostrar diálogo explicativo antes de solicitar permiso
  static Future<bool> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
    required Function() onRequestPermission,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (result == true) {
      onRequestPermission();
    }

    return result ?? false;
  }
}
