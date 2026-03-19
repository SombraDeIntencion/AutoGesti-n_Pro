import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Descargar archivo desde URL de Firebase Storage y guardarlo temporalmente
  Future<String?> _downloadFileFromUrl(String url) async {
    try {
      debugPrint('📥 ShareService: Intentando descargar: $url');

      // Si ya es una ruta local, devolverla directamente
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        debugPrint('✅ ShareService: Es una ruta local: $url');
        return url;
      }

      // Obtener el directorio temporal
      final tempDir = await getTemporaryDirectory();

      // Extraer el nombre del archivo de la URL
      final uri = Uri.parse(url);
      String fileName = '';
      String extension = '';

      // Para URLs de Firebase Storage, extraer el nombre del archivo
      if (uri.pathSegments.isNotEmpty) {
        String lastSegment = uri.pathSegments.last;
        fileName = Uri.decodeComponent(lastSegment);

        // Extraer la extensión ANTES de limpiar caracteres
        if (fileName.contains('.')) {
          final parts = fileName.split('.');
          // La extensión puede tener query params (?token=...)
          extension = parts.last.split('?').first.toLowerCase();
          // Validar que sea una extensión real (máx 5 caracteres)
          if (extension.length > 5 || extension.isEmpty) {
            extension = '';
          }
        }

        if (fileName.contains('/')) {
          fileName = fileName.split('/').last;
        }

        // Limpiar caracteres inválidos del nombre
        fileName = fileName
            .split('.')
            .first; // Tomar solo el nombre sin extensión
        fileName = fileName.replaceAll(RegExp(r'[<>:"|?*\\\/]'), '_');
      }

      // Si no hay extensión detectada, intentar detectar por la URL o contenido
      if (extension.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // Detectar tipo de archivo por la URL
        final urlLower = url.toLowerCase();
        if (urlLower.contains('.jpg') ||
            urlLower.contains('.jpeg') ||
            urlLower.contains('image%2Fjpeg')) {
          extension = 'jpg';
        } else if (urlLower.contains('.png') ||
            urlLower.contains('image%2Fpng')) {
          extension = 'png';
        } else if (urlLower.contains('.pdf') ||
            urlLower.contains('application%2Fpdf')) {
          extension = 'pdf';
        } else if (urlLower.contains('.zip') ||
            urlLower.contains('application%2Fzip')) {
          extension = 'zip';
        } else {
          // Último recurso: usar jpg como default para imágenes
          extension = 'jpg';
        }

        fileName = fileName.isEmpty ? 'archivo_$timestamp' : fileName;
      }

      // Construir nombre final con extensión
      final finalFileName = '$fileName.$extension';
      final tempFile = File('${tempDir.path}/$finalFileName');

      debugPrint('📝 ShareService: Descargando como: $finalFileName');

      // Usar Firebase Storage SDK para descargar (maneja autenticación automáticamente)
      try {
        final ref = _storage.refFromURL(url);
        await ref.writeToFile(tempFile);
        debugPrint('✅ ShareService: Descarga exitosa: ${tempFile.path}');
        return tempFile.path;
      } catch (e) {
        // Si falla con Firebase SDK, el archivo podría no existir o no tener permisos
        debugPrint('❌ ShareService: Error en Firebase SDK: $e');
        return null;
      }
    } catch (e) {
      // Error al descargar archivo
      debugPrint('❌ ShareService: Error general al descargar: $e');
      return null;
    }
  }

  // Descargar múltiples archivos
  Future<List<String>> _downloadMultipleFiles(List<String> urls) async {
    debugPrint('📦 ShareService: Descargando ${urls.length} archivos...');
    final List<String> localPaths = [];
    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      debugPrint('📥 Descargando archivo ${i + 1}/${urls.length}');
      final localPath = await _downloadFileFromUrl(url);
      if (localPath != null) {
        localPaths.add(localPath);
        successCount++;
        debugPrint('✅ Éxito: archivo ${i + 1}');
      } else {
        failCount++;
        debugPrint('❌ Fallo: archivo ${i + 1}');
      }
    }

    debugPrint(
      '📊 ShareService: Resultado final - Éxitos: $successCount, Fallos: $failCount',
    );
    return localPaths;
  }

  // Compartir por WhatsApp
  Future<void> shareViaWhatsApp(String filePath, String message) async {
    try {
      // Descargar el archivo si es una URL
      final localPath = await _downloadFileFromUrl(filePath);

      if (localPath == null) {
        throw Exception('No se pudo descargar el archivo');
      }

      // Verificar que el archivo existe
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('El archivo descargado no existe: $localPath');
      }

      debugPrint(
        '📤 Compartiendo archivo: $localPath (${await file.length()} bytes)',
      );

      // Compartir directamente el archivo - el usuario podrá elegir WhatsApp
      // Nota: No se incluye 'text' porque interfiere con el compartir de archivos en WhatsApp
      await Share.shareXFiles([XFile(localPath)]);
    } catch (e) {
      throw Exception('Error al compartir: $e');
    }
  }

  // Compartir por correo electrónico
  Future<void> shareViaEmail(
    String filePath,
    String subject,
    String body,
    String recipient,
  ) async {
    try {
      // Descargar el archivo si es una URL
      final localPath = await _downloadFileFromUrl(filePath);

      if (localPath == null) {
        throw Exception('No se pudo descargar el archivo');
      }

      // Compartir el archivo directamente - el usuario podrá elegir la app de correo
      await Share.shareXFiles([XFile(localPath)], subject: subject, text: body);
    } catch (e) {
      throw Exception('Error al compartir: $e');
    }
  }

  // Compartir archivo genérico
  Future<void> shareFile(String filePath, {String? message}) async {
    try {
      // Descargar el archivo si es una URL
      final localPath = await _downloadFileFromUrl(filePath);

      if (localPath == null) {
        throw Exception('No se pudo descargar el archivo');
      }

      // Verificar que el archivo existe
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('El archivo descargado no existe: $localPath');
      }

      debugPrint(
        '📤 Compartiendo archivo: $localPath (${await file.length()} bytes)',
      );

      // Nota: No se incluye 'text' porque interfiere con el compartir de archivos
      await Share.shareXFiles([XFile(localPath)]);
    } catch (e) {
      throw Exception('Error al compartir: $e');
    }
  }

  // Compartir múltiples archivos
  Future<void> shareMultipleFiles(
    List<String> filePaths, {
    String? message,
  }) async {
    try {
      debugPrint(
        '🚀 ShareService: Iniciando compartir ${filePaths.length} archivos',
      );

      // Descargar todos los archivos si son URLs
      final localPaths = await _downloadMultipleFiles(filePaths);

      debugPrint('📂 Archivos descargados localmente: ${localPaths.length}');

      if (localPaths.isEmpty) {
        throw Exception(
          'No se pudo descargar ningún archivo. Verifica la conexión a internet y los permisos de Firebase Storage.',
        );
      }

      // Verificar que todos los archivos existen
      final validFiles = <XFile>[];
      for (final path in localPaths) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('✓ Archivo válido: $path ($size bytes)');
          validFiles.add(XFile(path));
        } else {
          debugPrint('✗ Archivo no existe: $path');
        }
      }

      if (validFiles.isEmpty) {
        throw Exception(
          'Ningún archivo válido para compartir. Los archivos descargados no existen.',
        );
      }

      debugPrint('📤 Compartiendo ${validFiles.length} archivos válidos...');
      // Nota: No se incluye 'text' porque interfiere con el compartir de archivos en WhatsApp
      await Share.shareXFiles(validFiles);
      debugPrint('✅ Compartir completado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en shareMultipleFiles: $e');
      throw Exception('Error al compartir: $e');
    }
  }
}
