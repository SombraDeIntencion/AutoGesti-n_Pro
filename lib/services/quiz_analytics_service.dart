import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar respuestas del quiz de onboarding y analytics
class QuizAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _quizCompletedKey = 'quiz_completed';
  static const String _quizVehicleCountKey = 'quiz_vehicle_count';
  static const String _quizUsageTypeKey = 'quiz_usage_type';
  static const String _lastRetentionShownKey = 'last_retention_shown';

  /// Rangos internos de vehículos → tier recomendado
  static const List<_VehicleRange> _ranges = [
    _VehicleRange(1, 1, 'free', 1),
    _VehicleRange(2, 3, 'starter2', 3),
    _VehicleRange(4, 5, 'starter5', 5),
    _VehicleRange(6, 8, 'small8', 8),
    _VehicleRange(9, 12, 'small12', 12),
    _VehicleRange(13, 17, 'medium17', 17),
    _VehicleRange(18, 23, 'medium23', 23),
    _VehicleRange(24, 30, 'large30', 30),
    _VehicleRange(31, 40, 'large40', 40),
    _VehicleRange(41, 50, 'enterprise50', 50),
  ];

  /// Obtener el tier recomendado según el número de vehículos
  static String getRecommendedTier(int vehicleCount) {
    if (vehicleCount <= 0) return 'free';
    if (vehicleCount > 50) return 'enterprise50+';
    for (final range in _ranges) {
      if (vehicleCount >= range.min && vehicleCount <= range.max) {
        return range.tier;
      }
    }
    return 'free';
  }

  /// Obtener el máximo de vehículos para un tier
  static int getMaxVehiclesForTier(String tier) {
    for (final range in _ranges) {
      if (range.tier == tier) return range.maxVehicles;
    }
    return 1;
  }

  /// Guardar respuestas del quiz en Firestore y SharedPreferences
  Future<void> saveQuizResponse({
    required int vehicleCount,
    required String usageType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final recommendedTier = getRecommendedTier(vehicleCount);

    // Guardar localmente
    await prefs.setBool(_quizCompletedKey, true);
    await prefs.setInt(_quizVehicleCountKey, vehicleCount);
    await prefs.setString(_quizUsageTypeKey, usageType);

    // Guardar en Firestore para analytics
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_responses')
          .add({
            'vehicleCount': vehicleCount,
            'usageType': usageType,
            'recommendedTier': recommendedTier,
            'timestamp': FieldValue.serverTimestamp(),
            'convertedToPurchase': false,
          });

      // Marcar quiz completado en el perfil del usuario
      await _firestore.collection('users').doc(user.uid).set({
        'quizCompleted': true,
        'quizVehicleCount': vehicleCount,
        'quizUsageType': usageType,
        'quizRecommendedTier': recommendedTier,
      }, SetOptions(merge: true));
    }
  }

  /// Verificar si el quiz ya fue completado
  Future<bool> isQuizCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quizCompletedKey) ?? false;
  }

  /// Obtener el número de vehículos del último quiz
  Future<int?> getLastVehicleCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_quizVehicleCountKey);
    return count;
  }

  /// Obtener el tipo de uso del último quiz
  Future<String?> getLastUsageType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_quizUsageTypeKey);
  }

  /// Resetear quiz (para "Recalcular mi plan")
  Future<void> resetQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quizCompletedKey);
    await prefs.remove(_quizVehicleCountKey);
    await prefs.remove(_quizUsageTypeKey);
  }

  /// Verificar si se puede mostrar el diálogo de retención (máx 1 vez cada 7 días)
  Future<bool> canShowRetention() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_lastRetentionShownKey);
    if (lastShown == null) return true;

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastShown);
    final daysSince = DateTime.now().difference(lastDate).inDays;
    return daysSince >= 7;
  }

  /// Registrar que se mostró el diálogo de retención
  Future<void> markRetentionShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastRetentionShownKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Marcar que el usuario convirtió después del quiz
  Future<void> markConversion() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Actualizar la última respuesta del quiz como convertida
    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_responses')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'convertedToPurchase': true,
        'conversionTimestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}

/// Rango de vehículos interno
class _VehicleRange {
  final int min;
  final int max;
  final String tier;
  final int maxVehicles;

  const _VehicleRange(this.min, this.max, this.tier, this.maxVehicles);
}
