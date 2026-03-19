import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../services/employee_service.dart';
import '../utils/rate_limiter.dart';

/// Servicio para gestionar vehículos con restricciones freemium
class VehicleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorageService = LocalStorageService.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final EmployeeService _employeeService = EmployeeService();

  /// Obtener el usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Obtener vehículos del usuario actual
  Stream<List<Vehicle>> getVehicles() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firebaseService.getVehicles(currentUserId!);
  }

  /// Obtener un vehículo específico del usuario
  Future<Vehicle?> getVehicle(String vehicleId) async {
    if (currentUserId == null) return null;
    return await _firebaseService.getVehicle(vehicleId, currentUserId!);
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
      return {'current': 0, 'max': 0, 'canAdd': false, 'tier': 'none'};
    }

    final appUser = await _firebaseService.getUserData(currentUserId!);

    if (appUser == null) {
      // Usuario nuevo - límite gratis
      return {'current': 0, 'max': 1, 'canAdd': true, 'tier': 'free'};
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

    // Rate limiting: evitar creación masiva
    if (!RateLimiter().canProceed(
      'saveVehicle',
      minInterval: const Duration(seconds: 3),
      maxCallsPerWindow: 10,
      windowDuration: const Duration(minutes: 5),
    )) {
      throw Exception('Demasiadas operaciones. Espera un momento.');
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

    // Obtener empleado actual para el audit trail
    final currentEmployee = await _employeeService.getCurrentEmployee();

    // Asegurar que el vehículo tenga el userId correcto y audit trail
    final vehicleToSave = vehicle.copyWith(
      userId: currentUserId,
      lastEditedBy: currentEmployee?.name,
      lastEditedById: currentEmployee?.id,
      lastEditedAt: DateTime.now(),
    );

    // Guardar el vehículo en Firebase
    await _firebaseService.saveVehicle(vehicleToSave, currentUserId!);

    // Actualizar contador si es nuevo
    if (isNewVehicle) {
      await _updateVehicleCount(1);
      // Sincronizar inmediatamente para asegurar consistencia
      await syncVehicleCount();
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

    // Obtener empleado actual para el audit trail
    final currentEmployee = await _employeeService.getCurrentEmployee();

    // Actualizar con audit trail
    final vehicleToUpdate = vehicle.copyWith(
      lastEditedBy: currentEmployee?.name,
      lastEditedById: currentEmployee?.id,
      lastEditedAt: DateTime.now(),
    );

    await _firebaseService.updateVehicle(vehicleToUpdate, currentUserId!);
    return true;
  }

  /// Eliminar vehículo
  Future<void> deleteVehicle(String vehicleId) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    // Rate limiting: evitar eliminaciones masivas
    if (!RateLimiter().canProceed(
      'deleteVehicle',
      minInterval: const Duration(seconds: 3),
      maxCallsPerWindow: 5,
      windowDuration: const Duration(minutes: 1),
    )) {
      throw Exception('Demasiadas operaciones. Espera un momento.');
    }

    // Verificar que el vehículo pertenece al usuario
    final vehicle = await getVehicle(vehicleId);
    if (vehicle == null) {
      throw Exception('Vehículo no encontrado o no tienes permiso');
    }

    await _firebaseService.deleteVehicle(vehicleId, currentUserId!);
    await _updateVehicleCount(-1);
    // Sincronizar inmediatamente para asegurar consistencia
    await syncVehicleCount();
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

    return await _firebaseService.uploadImage(
      file,
      vehicleId,
      currentUserId!,
      folder,
    );
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

    return await _firebaseService.uploadPdf(
      file,
      vehicleId,
      currentUserId!,
      folder,
    );
  }

  /// Eliminar archivo
  Future<void> deleteFile(String path) async {
    await _firebaseService.deleteFile(path);
  }

  /// Sincronizar contador de vehículos con la realidad de Firebase
  /// Esto corrige inconsistencias donde el contador no coincide con los vehículos guardados
  Future<void> syncVehicleCount() async {
    if (currentUserId == null) {
      return;
    }

    try {
      // Obtener vehículos reales de Firebase
      final vehicles = await _firebaseService.getVehicles(currentUserId!).first;
      final realCount = vehicles.length;

      // Obtener contador de Firebase
      final appUser = await _firebaseService.getUserData(currentUserId!);
      final firebaseCount = appUser?.currentVehicles ?? 0;

      // Si no coinciden, actualizar Firebase con la realidad
      if (realCount != firebaseCount) {
        await _firebaseService.setUserVehicleCount(currentUserId!, realCount);
      }
    } catch (e) {
      // Error silencioso
    }
  }
}
