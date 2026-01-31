import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

/// Servicio para gestionar vehículos con restricciones freemium
class VehicleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorageService = LocalStorageService.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Obtener el usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Obtener vehículos del usuario actual
  Stream<List<Vehicle>> getVehicles() async* {
    if (currentUserId == null) {
      yield [];
      return;
    }

    // Obtener vehículos y filtrar por usuario
    await for (final vehicles in _localStorageService.getVehicles()) {
      yield vehicles.where((v) => v.userId == currentUserId).toList();
    }
  }

  /// Obtener un vehículo específico del usuario
  Future<Vehicle?> getVehicle(String vehicleId) async {
    final vehicle = await _localStorageService.getVehicle(vehicleId);
    
    // Verificar que el vehículo pertenece al usuario actual
    if (vehicle != null && vehicle.userId == currentUserId) {
      return vehicle;
    }
    return null;
  }

  /// Verificar si el usuario puede agregar más vehículos
  Future<bool> canAddVehicle() async {
    if (currentUserId == null) return false;

    // Obtener información del usuario
    final appUser = await _firebaseService.getUserData(currentUserId!);
    if (appUser == null) {
      // Usuario nuevo sin datos - permitir 1 vehículo gratis
      return true;
    }

    return appUser.canAddVehicle();
  }

  /// Obtener límite de vehículos del usuario
  Future<Map<String, dynamic>> getVehicleLimits() async {
    if (currentUserId == null) {
      return {
        'current': 0,
        'max': 0,
        'canAdd': false,
        'tier': 'none',
      };
    }

    final appUser = await _firebaseService.getUserData(currentUserId!);
    
    if (appUser == null) {
      // Usuario nuevo - límite gratis
      return {
        'current': 0,
        'max': 1,
        'canAdd': true,
        'tier': 'free',
      };
    }

    return {
      'current': appUser.currentVehicles,
      'max': appUser.maxVehicles,
      'canAdd': appUser.canAddVehicle(),
      'tier': appUser.subscriptionTier,
    };
  }

  /// Guardar vehículo con validación freemium
  Future<bool> saveVehicle(Vehicle vehicle) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Verificar si es un vehículo nuevo
    final existingVehicle = await _localStorageService.getVehicle(vehicle.id);
    final isNewVehicle = existingVehicle == null;

    // Si es nuevo, verificar límites
    if (isNewVehicle) {
      final canAdd = await canAddVehicle();
      if (!canAdd) {
        return false; // No se puede agregar más vehículos
      }
    }

    // Asegurar que el vehículo tenga el userId correcto
    final vehicleToSave = vehicle.copyWith(userId: currentUserId);

    // Guardar el vehículo
    await _localStorageService.saveVehicle(vehicleToSave);

    // Actualizar contador si es nuevo
    if (isNewVehicle) {
      await _updateVehicleCount(1);
    }

    return true;
  }

  /// Actualizar vehículo existente
  Future<bool> updateVehicle(Vehicle vehicle) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Verificar que el vehículo pertenece al usuario
    if (vehicle.userId != currentUserId) {
      throw Exception('No tienes permiso para editar este vehículo');
    }

    await _localStorageService.updateVehicle(vehicle);
    return true;
  }

  /// Eliminar vehículo
  Future<void> deleteVehicle(String vehicleId) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Verificar que el vehículo pertenece al usuario
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) {
      throw Exception('Vehículo no encontrado o no tienes permiso');
    }

    await _localStorageService.deleteVehicle(vehicleId);
    await _updateVehicleCount(-1);
  }

  /// Actualizar contador de vehículos del usuario
  Future<void> _updateVehicleCount(int delta) async {
    if (currentUserId == null) return;

    try {
      await _firebaseService.updateUserVehicleCount(currentUserId!, delta);
    } catch (e) {
      // Error al actualizar contador - será corregido en la próxima sincronización
    }
  }

  /// Subir imagen del vehículo
  Future<String> uploadImage(File file, String vehicleId, String folder) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Verificar que el vehículo pertenece al usuario
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) {
      throw Exception('Vehículo no encontrado o no tienes permiso');
    }

    return await _localStorageService.uploadImage(file, vehicleId, folder);
  }

  /// Subir PDF del vehículo
  Future<String> uploadPdf(File file, String vehicleId, String folder) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Verificar que el vehículo pertenece al usuario
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) {
      throw Exception('Vehículo no encontrado o no tienes permiso');
    }

    return await _localStorageService.uploadPdf(file, vehicleId, folder);
  }

  /// Eliminar archivo
  Future<void> deleteFile(String path) async {
    await _localStorageService.deleteFile(path);
  }
}
