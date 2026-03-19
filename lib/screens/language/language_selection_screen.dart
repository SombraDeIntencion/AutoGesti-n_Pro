import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/locale_service.dart';

/// Pantalla de selección de idioma inicial
class LanguageSelectionScreen extends StatefulWidget {
  final bool
  isInitialSetup; // true si es la primera vez, false si es cambio de idioma
  final VoidCallback? onLanguageSelected; // Callback para notificar cambio

  const LanguageSelectionScreen({
    super.key,
    this.isInitialSetup = true,
    this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  LocaleInfo? _selectedLocale;

  @override
  void initState() {
    super.initState();
    // Seleccionar el idioma actual del Provider por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeService = Provider.of<LocaleService>(context, listen: false);
      final currentLocale = localeService.currentLocale;

      // Buscar el LocaleInfo correspondiente
      final localeInfo = LocaleService.supportedLocales.firstWhere(
        (info) => info.locale.languageCode == currentLocale.languageCode,
        orElse: () => LocaleService.supportedLocales.first,
      );

      setState(() {
        _selectedLocale = localeInfo;
      });
    });
  }

  void _onLanguageSelected(LocaleInfo localeInfo) {
    setState(() {
      _selectedLocale = localeInfo;
    });
  }

  Future<void> _onContinue() async {
    if (_selectedLocale == null) return;

    // Obtener el servicio de localización del Provider
    final localeService = Provider.of<LocaleService>(context, listen: false);

    // Cambiar idioma (esto guarda en SharedPreferences)
    await localeService.changeLocale(_selectedLocale!.locale);

    // Si es configuración inicial, marcar explícitamente como seleccionado
    // Esto asegura que el flag esté guardado en SharedPreferences
    if (widget.isInitialSetup) {
      await localeService.markLocaleAsSelected();

      // Verificar que se guardó correctamente (para debug)
      final saved = await localeService.hasSelectedLocale();
      if (!saved) {
        // Si por alguna razón no se guardó, intentar de nuevo
        await Future.delayed(const Duration(milliseconds: 100));
        await localeService.changeLocale(_selectedLocale!.locale);
        await localeService.markLocaleAsSelected();
      }
    }

    if (!mounted) return;

    if (widget.isInitialSetup) {
      // Si es configuración inicial, notificar al callback
      widget.onLanguageSelected?.call();
    } else {
      // Si es cambio de idioma, simplemente regresar
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF17A2B8),
              const Color(0xFF17A2B8).withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Ícono de la app
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 50,
                        color: Color(0xFF17A2B8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Título
                    const Text(
                      'AutoGestion Max',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtítulo
                    Text(
                      widget.isInitialSetup
                          ? 'Select your language'
                          : 'Change language',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isInitialSetup
                          ? 'Choose your preferred language'
                          : 'Selecciona tu idioma preferido',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de idiomas
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: LocaleService.supportedLocales.length,
                          itemBuilder: (context, index) {
                            final localeInfo =
                                LocaleService.supportedLocales[index];
                            final isSelected = _selectedLocale == localeInfo;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _onLanguageSelected(localeInfo),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF17A2B8,
                                            ).withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF17A2B8)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Emoji de bandera
                                        Text(
                                          localeInfo.flag,
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                        const SizedBox(width: 16),
                                        // Nombres de idioma
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localeInfo.nativeName,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? const Color(0xFF17A2B8)
                                                      : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                localeInfo.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? const Color(
                                                          0xFF17A2B8,
                                                        ).withValues(alpha: 0.7)
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Check icon
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF17A2B8),
                                            size: 28,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Botón continuar
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _selectedLocale != null
                                ? _onContinue
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF17A2B8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.isInitialSetup ? 'Continue' : 'Guardar',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
