import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();

  // Compresión optimizada para móviles/tablets
  // Reduce significativamente el tamaño sin perder calidad visible
  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75, // Calidad 75% - buen balance para móviles
        minWidth: 1280, // Ancho máximo 1280px - perfecto para tablets
        minHeight: 720, // Alto máximo 720px
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
      return file; // Si falla la compresión, retornar original
    } catch (e) {
      return file; // Si hay error, retornar archivo original
    }
  }

  // Tomar foto con la cámara
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final file = File(photo.path);
        return await _compressImage(file);
      }
      return null;
    } catch (e) {
      // Error al tomar foto - silenciado para producción
      return null;
    }
  }

  // Seleccionar imagen de la galería
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        return await _compressImage(file);
      }
      return null;
    } catch (e) {
      // Error al seleccionar imagen - silenciado para producción
      return null;
    }
  }

  // Seleccionar múltiples imágenes
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      // Comprimir todas las imágenes seleccionadas
      final List<File> compressedFiles = [];
      for (final image in images) {
        final file = File(image.path);
        final compressed = await _compressImage(file);
        if (compressed != null) {
          compressedFiles.add(compressed);
        }
      }

      return compressedFiles;
    } catch (e) {
      // Error al seleccionar imágenes - silenciado para producción
      return [];
    }
  }

  // Seleccionar archivo PDF
  Future<File?> pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      // Error al seleccionar PDF - silenciado para producción
      return null;
    }
  }

  // Seleccionar múltiples PDFs
  Future<List<File>> pickMultiplePdfs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      }
      return [];
    } catch (e) {
      // Debug removed for production
      return [];
    }
  }
}
