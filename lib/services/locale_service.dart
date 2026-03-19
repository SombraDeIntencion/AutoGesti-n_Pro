import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar el idioma de la aplicación
class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';

  Locale _currentLocale = const Locale('es', 'ES'); // Español por defecto

  Locale get currentLocale => _currentLocale;

  /// Lista de idiomas soportados con información completa
  static const List<LocaleInfo> supportedLocales = [
    LocaleInfo(
      locale: Locale('es', 'ES'),
      name: 'Español',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LocaleInfo(
      locale: Locale('en', 'US'),
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LocaleInfo(
      locale: Locale('pt', 'BR'),
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇧🇷',
    ),
    LocaleInfo(
      locale: Locale('fr', 'FR'),
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LocaleInfo(
      locale: Locale('de', 'DE'),
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    LocaleInfo(
      locale: Locale('it', 'IT'),
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    LocaleInfo(
      locale: Locale('zh', 'CN'),
      name: 'Chinese (Simplified)',
      nativeName: '简体中文',
      flag: '🇨🇳',
    ),
    LocaleInfo(
      locale: Locale('ja', 'JP'),
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    LocaleInfo(
      locale: Locale('ar', 'SA'),
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
    LocaleInfo(
      locale: Locale('ru', 'RU'),
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
    LocaleInfo(
      locale: Locale('hi', 'IN'),
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
    LocaleInfo(
      locale: Locale('ko', 'KR'),
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
  ];

  LocaleService();

  /// Inicializar el servicio cargando el idioma guardado.
  /// Debe llamarse antes de pasar el servicio al Provider.
  Future<void> initialize() async {
    await _loadSavedLocale();
  }

  /// Cargar idioma guardado
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);

    if (localeCode != null) {
      final parts = localeCode.split('_');
      if (parts.length == 2) {
        _currentLocale = Locale(parts[0], parts[1]);
        notifyListeners();
      }
    }
  }

  /// Cambiar idioma
  Future<void> changeLocale(Locale newLocale) async {
    _currentLocale = newLocale;

    // Guardar en preferencias (siempre, incluso si es el mismo)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localeKey,
      '${newLocale.languageCode}_${newLocale.countryCode}',
    );

    notifyListeners();
  }

  /// Verificar si ya se seleccionó un idioma
  Future<bool> hasSelectedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_localeKey);
  }

  /// Marcar que el idioma fue seleccionado
  Future<void> markLocaleAsSelected() async {
    // Forzar guardado del locale actual si no existe
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_localeKey)) {
      await prefs.setString(
        _localeKey,
        '${_currentLocale.languageCode}_${_currentLocale.countryCode}',
      );
    }
  }

  /// Obtener información del idioma actual
  LocaleInfo get currentLocaleInfo {
    return supportedLocales.firstWhere(
      (info) => info.locale == _currentLocale,
      orElse: () => supportedLocales.first,
    );
  }

  /// Limpiar el idioma seleccionado (útil para testing)
  Future<void> clearSelectedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    _currentLocale = const Locale('es', 'ES');
    notifyListeners();
  }
}

/// Información completa de un idioma soportado
class LocaleInfo {
  final Locale locale;
  final String name; // Nombre en inglés
  final String nativeName; // Nombre en el idioma nativo
  final String flag; // Emoji de bandera

  const LocaleInfo({
    required this.locale,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
