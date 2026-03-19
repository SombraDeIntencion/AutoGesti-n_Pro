import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Resultado de la operación biométrica
class BiometricResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;

  BiometricResult({required this.success, this.errorCode, this.errorMessage});
}

/// Servicio para gestionar autenticación biométrica (huella dactilar/Face ID)
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // 🔒 SEGURIDAD: Configuración segura de FlutterSecureStorage
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys para SharedPreferences
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserIdKey = 'biometric_user_id';

  // Keys para SecureStorage (solo email, NO contraseña)
  // 🔒 SEGURIDAD: NO almacenamos contraseñas - Firebase Auth maneja tokens
  static const String _secureEmailKey = 'biometric_email';

  /// Verificar si el dispositivo soporta biometría
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    }
  }

  /// Obtener lista de biométricos disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }

  /// Verificar si el usuario tiene biometría habilitada
  Future<bool> isBiometricEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(_biometricUserIdKey);
      final isEnabled = prefs.getBool(_biometricEnabledKey) ?? false;

      // Verificar que el userId coincida con el guardado
      return isEnabled && savedUserId == userId;
    } catch (e) {
      return false;
    }
  }

  /// Habilitar autenticación biométrica para un usuario
  /// Solo guarda el email - Firebase Auth maneja la persistencia de tokens
  /// 🔒 SEGURIDAD: No guardamos contraseñas en el dispositivo
  Future<BiometricResult> enableBiometric(
    String userId,
    String userEmail,
    String localizedReason,
  ) async {
    try {
      // Verificar que el dispositivo soporte biometría
      if (!await isBiometricAvailable()) {
        return BiometricResult(
          success: false,
          errorCode: 'not_available',
          errorMessage: 'El dispositivo no soporta autenticación biométrica',
        );
      }

      // Verificar que haya biométricos enrollados
      if (!await hasEnrolledBiometrics()) {
        return BiometricResult(
          success: false,
          errorCode: 'not_enrolled',
          errorMessage:
              'No hay huellas dactilares registradas en el dispositivo',
        );
      }

      // Solicitar autenticación biométrica para confirmar
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              false, // Cambiado a false para permitir PIN como fallback
        ),
      );

      if (didAuthenticate) {
        // Guardar preferencias
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);
        await prefs.setString(_biometricUserIdKey, userId);

        // 🔒 SEGURIDAD: Solo guardamos el email, NO la contraseña
        // Firebase Auth mantiene los tokens de refresh automáticamente
        await _secureStorage.write(key: _secureEmailKey, value: userEmail);

        return BiometricResult(success: true);
      }

      return BiometricResult(
        success: false,
        errorCode: 'auth_failed',
        errorMessage: 'Autenticación cancelada o fallida',
      );
    } on PlatformException catch (e) {
      // Error al habilitar autenticación biométrica
      return BiometricResult(
        success: false,
        errorCode: e.code,
        errorMessage: e.message ?? 'Error desconocido: ${e.code}',
      );
    } catch (e) {
      return BiometricResult(
        success: false,
        errorCode: 'unknown',
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  /// Deshabilitar autenticación biométrica
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_biometricUserIdKey);

      // Eliminar email guardado
      await _secureStorage.delete(key: _secureEmailKey);
    } catch (_) {
      // Error silencioso
    }
  }

  /// Autenticar usuario con biometría
  Future<bool> authenticate(String localizedReason) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN/contraseña como alternativa
        ),
      );

      return didAuthenticate;
    } on PlatformException {
      // Errores comunes:
      // - PermanentlyLockedOut: Demasiados intentos fallidos
      // - LockedOut: Temporalmente bloqueado
      // - NotAvailable: No hay biometría configurada
      // - NotEnrolled: No hay huellas registradas
      return false;
    }
  }

  /// Autenticar con biometría y verificar sesión de Firebase
  /// 🔒 SEGURIDAD: No retorna contraseñas - Firebase Auth maneja la autenticación
  /// Retorna el email si la autenticación biométrica es exitosa
  Future<String?> authenticateAndGetEmail(String localizedReason) async {
    try {
      // Verificar que hay email guardado
      final email = await _secureStorage.read(key: _secureEmailKey);

      if (email == null) {
        return null; // No hay email guardado
      }

      // Solicitar autenticación biométrica
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        // Retornar solo el email - Firebase Auth maneja el resto
        return email;
      }

      return null;
    } on PlatformException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener el tipo de biometría disponible como String
  Future<String> getBiometricTypeString() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) {
      return 'none';
    }

    if (biometrics.contains(BiometricType.face)) {
      return 'face'; // Face ID/Face Unlock
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'fingerprint'; // Huella dactilar
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'iris'; // Iris (raro)
    } else {
      return 'strong'; // Autenticación fuerte (PIN/patrón)
    }
  }

  /// Obtener el ID del último usuario que configuró biometría
  Future<String?> getLastBiometricUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_biometricUserIdKey);
    } catch (_) {
      return null;
    }
  }

  /// Verificar si hay configuración biométrica guardada
  Future<bool> hasStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _secureEmailKey);
      return email != null;
    } catch (_) {
      return false;
    }
  }

  /// Verificar si hay biométricos enrollados/registrados
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
