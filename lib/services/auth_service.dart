import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Servicio de autenticación para AutoGestión Max
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actual (Firebase)
  User? get currentUser => _auth.currentUser;

  /// Stream del usuario de la app con datos de Firestore
  Stream<AppUser?> get appUserStream {
    return authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      return await getAppUser(user.uid);
    });
  }

  /// Obtener datos del usuario desde Firestore
  Future<AppUser?> getAppUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  /// Registrar nuevo usuario con email y contraseña
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Actualizar displayName si se proporcionó
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // ENVIAR EMAIL DE VERIFICACIÓN
      await user.sendEmailVerification();

      // Crear documento de usuario en Firestore
      final appUser = AppUser(
        id: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        subscriptionTier: 'free',
        maxVehicles: 1, // 1 vehículo gratis
        currentVehicles: 0,
        isSubscriptionActive: true,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toFirestore());

      return appUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al crear cuenta: $e';
    }
  }

  /// Verificar si el email del usuario actual está verificado
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reenviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) throw 'No hay usuario autenticado';
      if (user.emailVerified) throw 'El email ya está verificado';

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar email de verificación: $e';
    }
  }

  /// Recargar información del usuario (para verificar si verificó el email)
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      print('Error recargando usuario: $e');
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // VERIFICAR SI EL EMAIL ESTÁ VERIFICADO
      if (!user.emailVerified) {
        // Permitir login pero marcar que necesita verificación
        print('Usuario no ha verificado su email');
      }

      // Actualizar última fecha de login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      return await getAppUser(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al iniciar sesión: $e';
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  /// Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar email de recuperación: $e';
    }
  }

  /// Actualizar perfil de usuario
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = currentUser;
      if (user == null) throw 'No hay usuario autenticado';

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Actualizar en Firestore
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
    } catch (e) {
      throw 'Error al actualizar perfil: $e';
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw 'No hay usuario autenticado';
      }

      // Reautenticar usuario
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Cambiar contraseña
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al cambiar contraseña: $e';
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String password) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw 'No hay usuario autenticado';
      }

      // Reautenticar antes de eliminar
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Eliminar datos de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar todos los vehículos del usuario
      final vehicles = await _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in vehicles.docs) {
        await doc.reference.delete();
      }

      // Eliminar cuenta de Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al eliminar cuenta: $e';
    }
  }

  /// Actualizar contador de vehículos del usuario
  Future<void> updateVehicleCount(String userId, int count) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'currentVehicles': count,
      });
    } catch (e) {
      print('Error actualizando contador de vehículos: $e');
    }
  }

  /// Verificar si el usuario puede agregar más vehículos
  Future<bool> canAddVehicle() async {
    final user = currentUser;
    if (user == null) return false;

    final appUser = await getAppUser(user.uid);
    if (appUser == null) return false;

    return appUser.canAddVehicle();
  }

  /// Obtener número de vehículos del usuario
  Future<int> getCurrentVehicleCount() async {
    final user = currentUser;
    if (user == null) return 0;

    try {
      final vehicles = await _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: user.uid)
          .get();

      return vehicles.docs.length;
    } catch (e) {
      print('Error obteniendo contador de vehículos: $e');
      return 0;
    }
  }

  /// Manejar excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email ya está registrado. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'user-not-found':
        return 'No existe una cuenta con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta soporte.';
      case 'requires-recent-login':
        return 'Por seguridad, necesitas iniciar sesión nuevamente.';
      default:
        return e.message ?? 'Error de autenticación';
    }
  }
}
