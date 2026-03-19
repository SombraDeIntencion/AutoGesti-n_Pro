import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import 'employee_service.dart';

/// Servicio de autenticación para AutoGestión Max
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keys para SharedPreferences - persistencia adicional de sesión
  static const String _lastUserIdKey = 'last_user_id';
  static const String _lastLoginSuccessKey = 'last_login_success';

  /// Stream del usuario actual
  /// Usa userChanges() para detectar cambios en emailVerified
  Stream<User?> get authStateChanges => _auth.userChanges();

  /// Usuario actual (Firebase)
  User? get currentUser => _auth.currentUser;

  /// Obtener datos del usuario desde Firestore
  Future<AppUser?> getAppUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error obteniendo usuario: $e');
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

      // ENVIAR EMAIL DE VERIFICACIÓN (método simple sin ActionCodeSettings)
      try {
        debugPrint(
          '📧 Enviando email de verificación inicial a: ${user.email}',
        );
        await user.sendEmailVerification();
        debugPrint('✓ Email de verificación inicial enviado correctamente');
      } catch (e) {
        // No fallar el registro si el email no se envía
        debugPrint('⚠️ Error enviando email de verificación inicial: $e');
        debugPrint(
          '   El usuario podrá reenviarlo desde la pantalla de verificación',
        );
      }

      // Guardar sesión en SharedPreferences como respaldo
      await _saveSessionPreferences(user.uid);

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
      throw 'Error al crear cuenta';
    }
  }

  /// Verificar si el email del usuario actual está verificado
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reenviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado');
        throw 'No hay usuario autenticado';
      }
      if (user.emailVerified) {
        debugPrint('ℹ️ El email ya está verificado');
        throw 'El email ya está verificado';
      }

      debugPrint('📧 Enviando email de verificación a: ${user.email}');

      // Enviar directamente SIN ActionCodeSettings para evitar problemas
      await user.sendEmailVerification();

      debugPrint('✓ Email de verificación enviado exitosamente');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');

      // Manejar errores específicos de Firebase
      if (e.code == 'too-many-requests') {
        throw 'Demasiados intentos. Por favor espera unos minutos antes de intentar nuevamente.';
      }

      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Error general al enviar email: $e');
      throw 'Error al enviar email de verificación: $e';
    }
  }

  /// Recargar información del usuario (para verificar si verificó el email)
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      // Ignorar error de "too-many-requests" en reloadUser
      // para evitar interrumpir la verificación automática
      if (e.code == 'too-many-requests') {
        debugPrint('⚠️ Too many reload requests, skipping...');
        return;
      }
      debugPrint('Error recargando usuario: $e');
    } catch (e) {
      debugPrint('Error recargando usuario: $e');
    }
  }

  /// Verificar y restaurar sesión persistida (útil al iniciar la app)
  /// 🔒 SEGURIDAD: Verifica tokens y los renueva automáticamente
  /// Retorna true si hay una sesión activa y válida
  Future<bool> checkPersistedSession() async {
    try {
      // Breve espera para asegurar que Firebase Auth haya restaurado la sesión
      await Future.delayed(const Duration(milliseconds: 100));

      final user = currentUser;
      if (user == null) {
        // No hay usuario en Firebase Auth
        debugPrint('checkPersistedSession: No hay usuario en Firebase Auth');
        return false;
      }

      debugPrint('checkPersistedSession: Usuario encontrado - ${user.email}');

      // 🔒 Intentar renovar token proactivamente
      // Firebase Auth renueva tokens automáticamente, pero forzamos
      // un refresh si es posible para mantener la sesión fresca
      try {
        await user.getIdToken(true);
        debugPrint('✓ Token renovado exitosamente');
      } catch (e) {
        if (e is FirebaseAuthException) {
          // Solo cerrar sesión en errores críticos irrecuperables
          if (e.code == 'user-disabled' || e.code == 'user-not-found') {
            debugPrint('🔒 Error crítico de autenticación. Cerrando sesión.');
            await signOut();
            return false;
          }
        }
        // Para errores de red u otros, mantener la sesión local
        // Firebase renovará el token cuando haya conexión
        debugPrint(
          'ℹ️ No se pudo renovar token (posible sin conexión). Manteniendo sesión local.',
        );
      }

      // Verificar que coincida con la sesión guardada en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_lastUserIdKey);

      // Si hay usuario en Firebase pero no coincide con el guardado, actualizar
      if (savedUserId != null && savedUserId != user.uid) {
        debugPrint(
          'Usuario en Firebase no coincide con sesión guardada, actualizando',
        );
      }

      // Intentar recargar datos del usuario (no fatal si falla por red)
      try {
        await user.reload();
        final reloadedUser = _auth.currentUser;
        if (reloadedUser == null) {
          debugPrint('checkPersistedSession: Usuario eliminado/deshabilitado');
          await _clearSessionPreferences();
          return false;
        }
      } catch (e) {
        // Si no hay red, user.reload() falla - NO cerrar sesión
        debugPrint(
          'ℹ️ No se pudo recargar usuario (posible sin conexión). Manteniendo sesión.',
        );
      }

      // Guardar sesión válida en SharedPreferences
      await _saveSessionPreferences(user.uid);

      debugPrint(
        '✓ Sesión persistida restaurada exitosamente para: ${user.email}',
      );
      return true;
    } catch (e) {
      debugPrint('Error verificando sesión persistida: $e');
      // No cerrar sesión por errores genéricos - mantener sesión local
      return currentUser != null;
    }
  }

  /// Guardar información de sesión en SharedPreferences como respaldo
  Future<void> _saveSessionPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, userId);
      await prefs.setBool(_lastLoginSuccessKey, true);
      debugPrint('Sesión guardada en SharedPreferences para: $userId');
    } catch (e) {
      debugPrint('Error guardando sesión en SharedPreferences: $e');
    }
  }

  /// Limpiar información de sesión de SharedPreferences
  Future<void> _clearSessionPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUserIdKey);
      await prefs.remove(_lastLoginSuccessKey);
    } catch (e) {
      debugPrint('Error limpiando sesión de SharedPreferences: $e');
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
        debugPrint('Usuario no ha verificado su email');
      }

      // Guardar sesión en SharedPreferences como respaldo
      await _saveSessionPreferences(user.uid);

      // Actualizar última fecha de login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });

      return await getAppUser(user.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al iniciar sesión';
    }
  }

  /// Cerrar sesión local (solo limpia empleado, mantiene Firebase Auth)
  /// 🔒 SEGURIDAD: Usado cuando el usuario tiene biometría habilitada
  /// para permitir login rápido con huella sin perder la sesión de Firebase
  Future<void> signOutLocal() async {
    try {
      // Limpiar sesión de empleado solamente
      final employeeService = EmployeeService();
      await employeeService.clearSession();

      debugPrint(
        '✓ Sesión local cerrada (Firebase Auth activo para biometría)',
      );
    } catch (e) {
      throw 'Error al cerrar sesión local: $e';
    }
  }

  /// Cerrar sesión completa (incluye Firebase Auth)
  /// 🔒 SEGURIDAD: Usado cuando el usuario no tiene biometría o quiere cerrar completamente
  Future<void> signOut() async {
    try {
      // Limpiar sesión de empleado antes de cerrar sesión de Firebase
      final employeeService = EmployeeService();
      await employeeService.clearSession();

      // Limpiar sesión guardada en SharedPreferences
      await _clearSessionPreferences();

      // Cerrar sesión de Firebase Auth
      await _auth.signOut();

      debugPrint('✓ Sesión completa cerrada (Firebase Auth + local)');
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
      throw 'Error al enviar email de recuperación';
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
      throw 'Error al actualizar perfil';
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
      throw 'Error al cambiar contraseña';
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

      // Eliminar vehículos del usuario desde la ruta correcta
      try {
        final vehiclesRef = _firestore
            .collection('autogestion_max')
            .doc('data')
            .collection('users')
            .doc(user.uid)
            .collection('vehicles');
        final vehicles = await vehiclesRef.get();
        for (final doc in vehicles.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('Aviso: no se pudieron eliminar vehículos: $e');
      }

      // Intentar limpiar documentos de Firestore (puede fallar por reglas de seguridad;
      // la limpieza definitiva ocurre en el trigger server-side de Auth)
      try {
        await _firestore.collection('users').doc(user.uid).delete();
      } catch (_) {}
      try {
        await _firestore
            .collection('autogestion_max')
            .doc('data')
            .collection('users')
            .doc(user.uid)
            .delete();
      } catch (_) {}

      // Eliminar cuenta de Auth (siempre se ejecuta)
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al eliminar cuenta';
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
