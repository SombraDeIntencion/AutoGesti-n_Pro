import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  // Descargar archivo desde URL y guardarlo temporalmente
  Future<String?> _downloadFileFromUrl(String url) async {
    try {
      // Si ya es una ruta local, devolverla directamente
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return url;
      }

      // Descargar el archivo con timeout
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar archivo: ${response.statusCode}');
      }

      // Obtener el directorio temporal
      final tempDir = await getTemporaryDirectory();

      // Extraer el nombre del archivo de la URL (antes de los parámetros de consulta)
      final uri = Uri.parse(url);
      String fileName = '';

      // Para URLs de Firebase Storage, extraer solo el nombre del archivo (última parte del path)
      if (uri.pathSegments.isNotEmpty) {
        // Tomar el último segmento y decodificar caracteres especiales
        String lastSegment = uri.pathSegments.last;
        fileName = Uri.decodeComponent(lastSegment);

        // Si aún contiene barras (path completo), tomar solo la última parte
        if (fileName.contains('/')) {
          fileName = fileName.split('/').last;
        }

        // Si el nombre tiene caracteres no válidos para Windows/Android, limpiarlos
        fileName = fileName.replaceAll(RegExp(r'[<>:"|?*\\\/]'), '_');
      }

      // Si no se puede extraer el nombre o no tiene extensión, usar uno genérico
      if (fileName.isEmpty || !fileName.contains('.')) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        // Intentar determinar la extensión del tipo de contenido
        final contentType = response.headers['content-type'] ?? '';
        String extension = '.bin';
        if (contentType.contains('pdf')) {
          extension = '.pdf';
        } else if (contentType.contains('image/jpeg') ||
            contentType.contains('image/jpg')) {
          extension = '.jpg';
        } else if (contentType.contains('image/png')) {
          extension = '.png';
        }
        fileName = 'documento_$timestamp$extension';
      }

      // Crear el archivo temporal
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      return tempFile.path;
    } catch (e) {
      // Error al descargar archivo
      return null;
    }
  }

  // Descargar múltiples archivos
  Future<List<String>> _downloadMultipleFiles(List<String> urls) async {
    final List<String> localPaths = [];

    for (final url in urls) {
      final localPath = await _downloadFileFromUrl(url);
      if (localPath != null) {
        localPaths.add(localPath);
      }
    }

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

      final url = Uri.parse('whatsapp://send?text=$message');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        // Esperar un momento y luego compartir el archivo
        await Future.delayed(const Duration(milliseconds: 500));
        await Share.shareXFiles([XFile(localPath)], text: message);
      } else {
        // Si WhatsApp no está disponible, compartir directamente
        await Share.shareXFiles([XFile(localPath)], text: message);
      }
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

      final emailUri = Uri(
        scheme: 'mailto',
        path: recipient,
        query: _encodeQueryParameters({'subject': subject, 'body': body}),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        // Compartir el archivo
        await Share.shareXFiles([XFile(localPath)], subject: subject);
      } else {
        // Si no se puede abrir el cliente de correo, compartir directamente
        await Share.shareXFiles([XFile(localPath)], subject: subject);
      }
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

      await Share.shareXFiles([XFile(localPath)], text: message);
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
      // Descargar todos los archivos si son URLs
      final localPaths = await _downloadMultipleFiles(filePaths);

      if (localPaths.isEmpty) {
        throw Exception('No se pudo descargar ningún archivo');
      }

      await Share.shareXFiles(
        localPaths.map((path) => XFile(path)).toList(),
        text: message,
      );
    } catch (e) {
      throw Exception('Error al compartir: $e');
    }
  }

  // Codificar parámetros de query para URLs
  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
