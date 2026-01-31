import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/vehicle.dart';

/// Servicio de almacenamiento local para desarrollo sin Firebase
/// Este servicio simula Firebase pero guarda datos localmente
class LocalStorageService {
  // Singleton para evitar múltiples instancias y fugas de memoria
  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._internal();
    return _instance!;
  }

  final List<Vehicle> _vehicles = [];
  final StreamController<List<Vehicle>> _vehiclesController =
      StreamController<List<Vehicle>>.broadcast();

  bool _isInitialized = false;

  // Constructor privado para singleton
  LocalStorageService._internal() {
    _loadVehicles();
  }

  // Método factory para mantener compatibilidad
  factory LocalStorageService() {
    return instance;
  }

  // Método para limpiar recursos cuando sea necesario
  static void disposeInstance() {
    _instance?._vehiclesController.close();
    _instance = null;
  }

  // Cargar vehículos desde almacenamiento local
  Future<void> _loadVehicles() async {
    if (_isInitialized) return; // Prevenir carga múltiple

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vehicles.json');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _vehicles.clear();
        _vehicles.addAll(
          jsonList
              .map((json) => Vehicle.fromJson(json as Map<String, dynamic>))
              .toList(),
        );
        _isInitialized = true;
        _vehiclesController.add(List.unmodifiable(_vehicles));
      } else {
        _isInitialized = true;
        _vehiclesController.add([]);
      }
    } catch (e) {
      // Error al cargar vehículos - inicializar con lista vacía
      _isInitialized = true;
      _vehiclesController.add([]);
    }
  }

  // Guardar vehículos en almacenamiento local
  Future<void> _saveVehicles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/vehicles.json');
      final jsonList = _vehicles.map((vehicle) => vehicle.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
      // Emitir una copia inmutable para evitar modificaciones externas
      _vehiclesController.add(List.unmodifiable(_vehicles));
    } catch (e) {
      // Error al guardar vehículos - silenciado para producción
    }
  }

  // Guardar vehículo
  Future<void> saveVehicle(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) {
      _vehicles[index] = vehicle;
    } else {
      _vehicles.add(vehicle);
    }
    await _saveVehicles();
  }

  // Obtener todos los vehículos
  Stream<List<Vehicle>> getVehicles() async* {
    // Esperar a que se carguen los datos iniciales
    if (!_isInitialized) {
      await _loadVehicles();
    }
    // Emitir inmediatamente la lista actual
    yield List.unmodifiable(_vehicles);
    // Luego emitir actualizaciones futuras
    yield* _vehiclesController.stream;
  }

  // Obtener un vehículo específico
  Future<Vehicle?> getVehicle(String id) async {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  // Actualizar vehículo
  Future<void> updateVehicle(Vehicle vehicle) async {
    await saveVehicle(vehicle);
  }

  // Eliminar vehículo
  Future<void> deleteVehicle(String id) async {
    _vehicles.removeWhere((v) => v.id == id);
    await _saveVehicles();
    // También eliminar archivos asociados si es necesario
    await _deleteVehicleFiles(id);
  }

  // Subir imagen (guardar localmente)
  Future<String> uploadImage(File file, String vehicleId, String folder) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final vehicleDir = Directory(
        '${directory.path}/vehicles/$vehicleId/$folder',
      );

      if (!await vehicleDir.exists()) {
        await vehicleDir.create(recursive: true);
      }

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = file.path.split('.').last;
      final newFile = File('${vehicleDir.path}/$fileName.$extension');

      await file.copy(newFile.path);
      return newFile.path; // Retornar ruta local en lugar de URL
    } catch (e) {
      // Error al guardar imagen - silenciado para producción
      return '';
    }
  }

  // Subir PDF (guardar localmente)
  Future<String> uploadPdf(File file, String vehicleId, String folder) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final vehicleDir = Directory(
        '${directory.path}/vehicles/$vehicleId/$folder',
      );

      if (!await vehicleDir.exists()) {
        await vehicleDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final newFile = File('${vehicleDir.path}/$fileName');

      await file.copy(newFile.path);
      return newFile.path;
    } catch (e) {
      // Error al guardar PDF - silenciado para producción
      return '';
    }
  }

  // Eliminar archivo
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Error al eliminar archivo - silenciado para producción
    }
  }

  // Eliminar todos los archivos de un vehículo
  Future<void> _deleteVehicleFiles(String vehicleId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final vehicleDir = Directory('${directory.path}/vehicles/$vehicleId');

      if (await vehicleDir.exists()) {
        await vehicleDir.delete(recursive: true);
      }
    } catch (e) {
      // Error al eliminar archivos del vehículo - silenciado para producción
    }
  }

  // Cerrar el stream controller al terminar
  void dispose() {
    _vehiclesController.close();
  }
}
