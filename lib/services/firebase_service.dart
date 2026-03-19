import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import '../models/vehicle.dart';
import '../models/app_user.dart';
import '../utils/rate_limiter.dart';
import 'local_storage_service.dart';

class FirebaseService {
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  final LocalStorageService _localStorage = LocalStorageService();
  bool _useFirebase = false;

  FirebaseService() {
    try {
      // Verificar si Firebase está inicializado
      Firebase.app();
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _useFirebase = true;
      // Firebase initialized successfully
    } catch (e) {
      _useFirebase = false;
      // Using local storage fallback
    }
  }

  // Colección de vehículos para un usuario específico con prefijo para separación de apps
  CollectionReference? vehiclesCollectionForUser(String userId) => _useFirebase
      ? _firestore
            .collection('autogestion_max')
            .doc('data')
            .collection('users')
            .doc(userId)
            .collection('vehicles')
      : null;

  // Colección de usuarios con prefijo para separación de apps
  CollectionReference? get usersCollection => _useFirebase
      ? _firestore.collection('autogestion_max').doc('data').collection('users')
      : null;

  // ============ MÉTODOS DE USUARIOS ============

  /// Obtener datos del usuario
  Future<AppUser?> getUserData(String userId) async {
    if (!_useFirebase || usersCollection == null) {
      // Sin Firebase, retornar usuario por defecto
      return AppUser(
        id: userId,
        email: '',
        createdAt: DateTime.now(),
        subscriptionTier: 'free',
        maxVehicles: 1,
        currentVehicles: 0,
      );
    }

    try {
      final doc = await usersCollection!.doc(userId).get();
      if (doc.exists) {
        return AppUser.fromFirestore(
          doc.data() as Map<String, dynamic>,
          userId,
        );
      }
      return null;
    } catch (e) {
      // Error al obtener datos del usuario
      return null;
    }
  }

  /// Crear o actualizar usuario
  Future<void> saveUserData(AppUser user) async {
    if (_useFirebase && usersCollection != null) {
      await usersCollection!.doc(user.id).set(user.toFirestore());
    }
  }

  /// Actualizar contador de vehículos del usuario
  Future<void> updateUserVehicleCount(String userId, int delta) async {
    if (!_useFirebase || usersCollection == null) return;

    try {
      final docRef = usersCollection!.doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // Crear usuario si no existe
          transaction.set(docRef, {
            'email': '',
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
            'maxVehicles': 1,
            'currentVehicles': delta > 0 ? delta : 0,
            'isSubscriptionActive': true,
          });
        } else {
          final data = snapshot.data() as Map<String, dynamic>?;
          final currentCount = data?['currentVehicles'] ?? 0;
          final newCount = (currentCount + delta)
              .clamp(0, double.infinity)
              .toInt();
          transaction.update(docRef, {'currentVehicles': newCount});
        }
      });
    } catch (e) {
      // Error al actualizar contador de vehículos
    }
  }

  /// Establecer contador de vehículos del usuario a un valor específico
  /// Útil para sincronizar el contador con la realidad del almacenamiento local
  Future<void> setUserVehicleCount(String userId, int count) async {
    if (!_useFirebase || usersCollection == null) return;

    try {
      final docRef = usersCollection!.doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // Crear usuario si no existe
          transaction.set(docRef, {
            'email': '',
            'createdAt': DateTime.now().toIso8601String(),
            'subscriptionTier': 'free',
            'maxVehicles': 1,
            'currentVehicles': count.clamp(0, double.infinity).toInt(),
            'isSubscriptionActive': true,
          });
        } else {
          transaction.update(docRef, {
            'currentVehicles': count.clamp(0, double.infinity).toInt(),
          });
        }
      });
    } catch (e) {
      // Error al establecer contador de vehículos
    }
  }

  /// Actualizar último login del usuario
  Future<void> updateLastLogin(String userId) async {
    if (_useFirebase && usersCollection != null) {
      await usersCollection!.doc(userId).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // ============ MÉTODOS DE VEHÍCULOS ============

  // Guardar vehículo
  Future<void> saveVehicle(Vehicle vehicle, String userId) async {
    if (_useFirebase) {
      await vehiclesCollectionForUser(
        userId,
      )!.doc(vehicle.id).set(vehicle.toJson());
    } else {
      await _localStorage.saveVehicle(vehicle);
    }
  }

  // Obtener todos los vehículos de un usuario
  Stream<List<Vehicle>> getVehicles(String userId) {
    if (_useFirebase) {
      return vehiclesCollectionForUser(userId)!.snapshots().map((snapshot) {
        final vehicles = <Vehicle>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            // Inyectar el doc ID si no existe campo 'id'
            if (data['id'] == null || data['id'] == '') {
              data['id'] = doc.id;
            }
            vehicles.add(Vehicle.fromJson(data));
          } catch (e) {
            // Saltar documentos corruptos para no romper toda la lista
            // ignore: avoid_print
            print('Error parsing vehicle ${doc.id}: $e');
          }
        }
        return vehicles;
      });
    } else {
      return _localStorage.getVehicles();
    }
  }

  // Obtener un vehículo específico
  Future<Vehicle?> getVehicle(String id, String userId) async {
    if (_useFirebase) {
      try {
        final doc = await vehiclesCollectionForUser(userId)!.doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['id'] == null || data['id'] == '') {
            data['id'] = doc.id;
          }
          return Vehicle.fromJson(data);
        }
      } catch (e) {
        print('Error parsing vehicle $id: $e');
      }
      return null;
    } else {
      return await _localStorage.getVehicle(id);
    }
  }

  // Actualizar vehículo
  Future<void> updateVehicle(Vehicle vehicle, String userId) async {
    if (_useFirebase) {
      await vehiclesCollectionForUser(
        userId,
      )!.doc(vehicle.id).update(vehicle.toJson());
    } else {
      await _localStorage.updateVehicle(vehicle);
    }
  }

  // Eliminar vehículo
  Future<void> deleteVehicle(String id, String userId) async {
    if (_useFirebase) {
      await vehiclesCollectionForUser(userId)!.doc(id).delete();
      // También eliminar archivos asociados del storage
      await _deleteVehicleFiles(id, userId);
    } else {
      await _localStorage.deleteVehicle(id);
    }
  }

  // Liberar recursos
  void dispose() {
    // LocalStorageService es singleton, no debemos dispose aquí
    // Solo limpiamos referencias locales si es necesario
  }

  // Subir imagen a Firebase Storage
  Future<String> uploadImage(
    File file,
    String vehicleId,
    String userId,
    String folder,
  ) async {
    // Rate limiting: evitar subidas masivas
    if (!RateLimiter().canProceed(
      'upload_$userId',
      minInterval: const Duration(seconds: 2),
      maxCallsPerWindow: 20,
      windowDuration: const Duration(minutes: 5),
    )) {
      throw Exception('Demasiadas subidas. Espera un momento.');
    }

    // Validar tamaño del archivo (máximo 10MB)
    final fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('El archivo excede el tamaño máximo de 10MB');
    }

    if (_useFirebase) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child(
        'autogestion_max/users/$userId/vehicles/$vehicleId/$folder/$fileName',
      );

      // Determinar content type según extensión del archivo
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = _resolveContentType(ext);

      await ref.putFile(file, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } else {
      return await _localStorage.uploadImage(file, vehicleId, folder);
    }
  }

  // Subir PDF a Firebase Storage
  Future<String> uploadPdf(
    File file,
    String vehicleId,
    String userId,
    String folder,
  ) async {
    // Rate limiting
    if (!RateLimiter().canProceed(
      'upload_$userId',
      minInterval: const Duration(seconds: 2),
      maxCallsPerWindow: 20,
      windowDuration: const Duration(minutes: 5),
    )) {
      throw Exception('Demasiadas subidas. Espera un momento.');
    }

    // Validar tamaño del archivo (máximo 10MB)
    final fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) {
      throw Exception('El archivo excede el tamaño máximo de 10MB');
    }

    if (_useFirebase) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child(
        'autogestion_max/users/$userId/vehicles/$vehicleId/$folder/$fileName',
      );

      await ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));
      return await ref.getDownloadURL();
    } else {
      return await _localStorage.uploadPdf(file, vehicleId, folder);
    }
  }

  /// Determina el content type según extensión del archivo
  String _resolveContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // Subir cualquier archivo (genérico)
  Future<String> uploadFile(File file, String userId, String path) async {
    if (_useFirebase) {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // Si userId no está vacío, construir ruta con usuarios
      final fullPath = userId.isNotEmpty
          ? 'autogestion_max/users/$userId/$path/$fileName'
          : 'autogestion_max/$path/$fileName';

      final ref = _storage.ref().child(fullPath);

      // Determinar content type según extensión
      final ext = file.path.split('.').last.toLowerCase();
      final contentType = _resolveContentType(ext);

      await ref.putFile(file, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } else {
      // Para local storage, usar el path del archivo directamente
      final parts = path.split('/');
      final vehicleId = parts.length > 1 ? parts[1] : 'default';
      final folder = parts.length > 2 ? parts[2] : 'general';
      return await _localStorage.uploadImage(file, vehicleId, folder);
    }
  }

  // Eliminar archivo de Storage
  Future<void> deleteFile(String url) async {
    try {
      if (_useFirebase) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      } else {
        await _localStorage.deleteFile(url);
      }
    } catch (e) {
      // Error al eliminar archivo
    }
  }

  // Eliminar todos los archivos de un vehículo
  Future<void> _deleteVehicleFiles(String vehicleId, String userId) async {
    if (!_useFirebase) return;

    try {
      final ref = _storage.ref().child(
        'autogestion_max/users/$userId/vehicles/$vehicleId',
      );
      final result = await ref.listAll();

      for (var item in result.items) {
        await item.delete();
      }

      for (var prefix in result.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      // Error al eliminar archivos del vehículo
    }
  }

  // Eliminar carpeta recursivamente
  Future<void> _deleteFolder(Reference folderRef) async {
    if (!_useFirebase) return;

    final result = await folderRef.listAll();

    for (var item in result.items) {
      await item.delete();
    }

    for (var prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }
  }
}
