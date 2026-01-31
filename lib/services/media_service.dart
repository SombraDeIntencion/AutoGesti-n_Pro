import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();

  // Tomar foto con la cámara
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
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
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
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
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return images.map((image) => File(image.path)).toList();
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
