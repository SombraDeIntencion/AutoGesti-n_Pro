/// Protección contra llamadas masivas a APIs.
/// Implementa rate limiting y debouncing para operaciones de Firebase.
class RateLimiter {
  final Map<String, DateTime> _lastCallTimes = {};
  final Map<String, int> _callCounts = {};
  final Map<String, DateTime> _windowStarts = {};

  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  /// Verifica si una operación puede ejecutarse según su límite.
  /// [key] identifica la operación (ej: 'deleteVehicle', 'uploadImage').
  /// [minInterval] tiempo mínimo entre llamadas consecutivas.
  /// [maxCallsPerWindow] máximo de llamadas permitidas en [windowDuration].
  bool canProceed(
    String key, {
    Duration minInterval = const Duration(seconds: 2),
    int maxCallsPerWindow = 10,
    Duration windowDuration = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();

    // Verificar intervalo mínimo entre llamadas
    final lastCall = _lastCallTimes[key];
    if (lastCall != null && now.difference(lastCall) < minInterval) {
      return false;
    }

    // Verificar ventana de rate limiting
    final windowStart = _windowStarts[key];
    if (windowStart == null || now.difference(windowStart) > windowDuration) {
      // Nueva ventana
      _windowStarts[key] = now;
      _callCounts[key] = 1;
    } else {
      final count = (_callCounts[key] ?? 0) + 1;
      if (count > maxCallsPerWindow) {
        return false;
      }
      _callCounts[key] = count;
    }

    _lastCallTimes[key] = now;
    return true;
  }

  /// Resetear contadores para una clave específica.
  void reset(String key) {
    _lastCallTimes.remove(key);
    _callCounts.remove(key);
    _windowStarts.remove(key);
  }
}
