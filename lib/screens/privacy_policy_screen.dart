import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: const Color(0xFF17A2B8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Política de Privacidad de AutoGestión Max',
              'Última actualización: 25 de febrero de 2026',
              isHeader: true,
            ),
            const SizedBox(height: 20),
            _buildSection('1. Información que Recopilamos', '''
1.1 Información de Cuenta:
• Dirección de correo electrónico
• Contraseña (cifrada)
• Fecha de registro

1.2 Información de Vehículos y Gastos:
• Datos del vehículo (marca, modelo, año, placa)
• Fotografías de vehículos
• Documentos de seguros y contratos (PDFs)
• Información de conductores
• Historial de mantenimiento
• Registros de gastos (monto, categoría, fecha, km)
• Comprobantes de gastos (fotos de tickets, PDFs de facturas)
• Datos de facturas escaneadas por código QR del SAT (RFC, monto, folio fiscal)

1.3 Información Técnica:
• Modelo y versión de Android (solo para diagnóstico si reportas un error)'''),
            _buildSection('2. Cómo Usamos tu Información', '''
• Proporcionar y mantener el servicio
• Gestionar tu cuenta y suscripción
• Almacenar y organizar tus datos de vehículos y gastos
• Mostrar avisos visuales dentro de la app cuando un documento esté próximo a vencer
• Generar reportes exportables en PDF y CSV
• Procesar pagos de suscripción a través de Google Play'''),
            _buildSection(
              '3. Almacenamiento de Datos',
              '''
• Almacenamiento local cifrado: Los tokens de sesión y preferencias se guardan mediante flutter_secure_storage (Android Keystore).

• Firebase Storage: Las imágenes y documentos PDF se almacenan en Firebase Storage con reglas de seguridad.

• Firebase Authentication: Gestiona tu autenticación de forma segura.

• Firebase Firestore: Almacena todos los datos de vehículos, gastos, mantenimiento y suscripción en la nube.

Se requiere conexión a Internet para el funcionamiento completo de la aplicación.''',
            ),
            _buildSection('4. Seguridad de Datos', '''
• Cifrado de credenciales con flutter_secure_storage (Android Keystore)
• Autenticación segura con Firebase
• Reglas de seguridad que impiden acceso no autorizado
• Cada usuario solo puede acceder a sus propios datos
• Datos en reposo protegidos por cifrado de Google Cloud Platform'''),
            _buildSection('5. Compartir Información', '''
NO compartimos, vendemos ni alquilamos tu información personal a terceros.

Excepciones:
• Cuando lo requiera la ley
• Para proteger nuestros derechos legales
• Con tu consentimiento explícito'''),
            _buildSection(
              '6. Tus Derechos',
              '''
Tienes derecho a:
• Acceder a tus datos personales
• Corregir información incorrecta
• Eliminar tu cuenta y todos tus datos
• Exportar tus datos
• Revocar consentimientos

Para ejercer estos derechos, usa la opción "Descargar mis datos" o "Eliminar mi cuenta" en la app.''',
            ),
            _buildSection('7. Retención de Datos', '''
• Mientras tu cuenta esté activa, tus datos se conservan indefinidamente
• Si eliminas tu cuenta, todos los datos se borran de forma permanente e inmediata
• Puedes exportar tus datos en PDF o CSV antes de eliminar tu cuenta'''),
            _buildSection('8. Cookies y Tecnologías Similares', '''
La aplicación móvil no utiliza cookies tradicionales, pero puede usar:
• Almacenamiento local del dispositivo
• Tokens de autenticación
• Identificadores de sesión'''),
            _buildSection(
              '9. Privacidad de Menores',
              '''
Esta aplicación no está diseñada para menores de 13 años y no recopilamos intencionalmente información de menores de edad.''',
            ),
            _buildSection(
              '10. Cambios a esta Política',
              '''
Podemos actualizar esta política ocasionalmente. Los cambios se notificarán mediante una actualización de la fecha de "Última actualización" visible en esta pantalla.''',
            ),
            _buildSection('11. Contacto', '''
Si tienes preguntas sobre esta política de privacidad, contáctanos:

Email: autogestionmax@mahondev.com
Desarrollador: MahonDev
Package ID: com.mahondev.autogestionmax'''),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Sobre tus Datos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tus datos de vehículos están almacenados de forma segura y privada. Solo tú tienes acceso a ellos. Puedes exportar o eliminar todos tus datos en cualquier momento desde "Mi Perfil".',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isHeader = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isHeader ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isHeader ? const Color(0xFF17A2B8) : const Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: isHeader ? 14 : 15,
            color: isHeader ? Colors.grey.shade600 : Colors.black87,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
