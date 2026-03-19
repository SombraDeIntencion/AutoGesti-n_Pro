# Política de Privacidad - AutoGestión Max

**Última actualización:** 15 de marzo de 2026

## 1. Introducción

Esta Política de Privacidad describe cómo AutoGestión Max ("nosotros", "la aplicación") recopila, usa y protege la información cuando utiliza nuestra aplicación móvil de gestión de flotilla de vehículos.

## 2. Información que Recopilamos

### 2.1 Información de la Cuenta del Usuario
- Dirección de correo electrónico (para autenticación mediante Firebase Authentication)
- Nombre (opcional, editable por el usuario)
- Foto de perfil (opcional, almacenada en Firebase Storage)
- Fecha de registro y último inicio de sesión

### 2.2 Información del Vehículo
- Datos del vehículo (marca, modelo, año, placa)
- Fotografías de vehículos
- Información de mantenimiento (historial, costos, kilometraje, fotos de partes)
- Documentos relacionados (seguro, tarjeta de circulación, contratos, calcomanía ecológica)
- Fechas de vencimiento de documentos
- Información del conductor asignado (nombre, teléfono, correo electrónico, fotos de licencia/identificación)
- Historial de ediciones (nombre del editor, fecha y hora del cambio)

### 2.3 Información de Gastos y Comprobantes
- Registros de gastos por vehículo (monto, categoría, fecha, descripción, kilometraje)
- Comprobantes fotográficos de gastos (fotos de tickets o facturas tomadas con la cámara o seleccionadas de la galería)
- Comprobantes en formato PDF adjuntados como recibo de un gasto
- Fotos del odómetro (para registro de kilometraje)
- Datos extraídos de códigos QR de facturas electrónicas del SAT (RFC emisor/receptor, monto total, folio fiscal, fecha de emisión); estos datos únicamente se usan para autocompletar el formulario de registro de gasto y **no se envían a terceros**

### 2.4 Inspecciones de Vehículos
- Registros de inspección con checklist de componentes (exterior, interior, motor, llantas)
- Estado de cada componente inspeccionado (OK, requiere atención, urgente)
- Fotografías por componente y notas del inspector

### 2.5 Información de Empleados
- Número de empleado, nombre y estado (activo/inactivo)
- Registro de qué empleado realiza cada edición en los vehículos (auditoría)

### 2.6 Información de Suscripción y Onboarding
- Respuestas del cuestionario de personalización (cantidad de vehículos, tipo de uso, timestamp de respuesta)
- Plan recomendado según sus respuestas
- Estado de suscripción (plan activo, fecha de expiración)
- Historial de compras procesadas a través de Google Play Billing

### 2.7 Información Técnica
- Información del dispositivo (modelo, versión de Android) usada únicamente para diagnóstico en caso de errores reportados por el usuario

### 2.8 Información que NO Recopilamos
- **No usamos Firebase Analytics ni Crashlytics** — no recopilamos datos de uso automatizados
- **No recopilamos ubicación** — no accedemos al GPS ni a datos de localización
- **No accedemos a contactos, calendario ni micrófono**
- **No usamos identificadores de publicidad** ni rastreadores de terceros

### 2.9 Permisos Utilizados
- **Cámara**: Para tomar fotografías de vehículos, documentos, comprobantes de gastos e inspecciones; y para escanear códigos QR de facturas electrónicas (SAT)
- **Almacenamiento** (solo Android 12 e inferior): Para guardar y acceder a imágenes y documentos PDF. En Android 13+, la aplicación utiliza el selector de fotos del sistema que no requiere este permiso
- **Internet**: Para comunicación con Firebase (requerido para el funcionamiento completo de la aplicación)
- **Estado de red**: Para verificar la conectividad a Internet y mostrar avisos de modo offline
- **Teléfono**: Para facilitar llamadas telefónicas al conductor desde la aplicación (no se realizan llamadas sin su consentimiento explícito)
- **Biometría** (Huella Dactilar / Reconocimiento Facial): Para facilitar el acceso seguro a la aplicación mediante autenticación biométrica. Este permiso es completamente opcional y solo se activa si usted decide habilitarlo en la configuración de su perfil

## 3. Cómo Usamos la Información

La información recopilada se utiliza exclusivamente para:
- Gestionar y organizar la información de su flotilla de vehículos
- Almacenar documentos e imágenes relacionadas con los vehículos
- Registrar y clasificar gastos por vehículo (combustible, mantenimiento, seguros, peajes, estacionamientos, reparaciones)
- Almacenar comprobantes de gastos (fotos de tickets y PDFs de facturas) en Firebase Storage
- Generar reportes de gastos exportables en PDF y CSV/Excel, incluyendo imágenes de comprobantes cuando estén disponibles
- Extraer automáticamente datos de facturas electrónicas mediante escaneo de códigos QR del SAT
- Generar reportes de mantenimiento
- Registrar inspecciones de vehículos con checklist de componentes y evidencia fotográfica
- Sincronizar datos entre dispositivos a través de Firebase
- Mostrar avisos visuales dentro de la aplicación cuando un documento esté próximo a vencer o haya vencido
- Facilitar la comunicación con conductores mediante llamadas telefónicas (solo cuando usted lo solicita explícitamente)
- Personalizar la experiencia mediante el cuestionario de onboarding para recomendar el plan más adecuado a sus necesidades
- Gestionar su suscripción y acceso a funciones según el plan contratado

## 4. Almacenamiento de Datos

### 4.1 Almacenamiento Local
- Las preferencias de configuración y tokens de sesión se guardan localmente mediante almacenamiento cifrado del sistema operativo (Android Keystore a través de `flutter_secure_storage` y `shared_preferences`)
- La caché offline de Firestore permite acceder a datos ya cargados sin conexión
- Las imágenes y documentos se guardan en el almacenamiento interno privado de la aplicación

### 4.2 Almacenamiento en la Nube (Requerido)
- La aplicación utiliza Firebase como almacén principal de datos. Se requiere conexión a Internet para el funcionamiento completo
- Los datos se almacenan en Firebase Firestore (base de datos) y Firebase Storage (archivos e imágenes)
- Los datos en Firebase están protegidos con reglas de seguridad
- Solo el usuario autenticado puede acceder a sus propios datos

## 5. Compartir Información

### 5.1 No Vendemos Datos
No vendemos, alquilamos ni comercializamos su información personal a terceros.

### 5.2 Funcionalidad de Compartir
- La aplicación permite compartir reportes y documentos voluntariamente
- Esto se hace solo cuando usted selecciona explícitamente la opción de compartir
- Usted controla qué información comparte y con quién

## 6. Seguridad de los Datos

Implementamos múltiples capas de medidas de seguridad para proteger su información:

### 6.1 Seguridad Local
- Tokens de sesión y credenciales almacenados con `flutter_secure_storage`, respaldado por Android Keystore (cifrado a nivel de hardware)
- Preferencias de configuración guardadas con `shared_preferences` en el espacio privado de la aplicación (no accesible por otras apps)
- Caché de imágenes protegido en directorio privado del sistema

### 6.2 Seguridad en la Nube (Firebase)
- Comunicaciones seguras mediante HTTPS/TLS 1.3
- Autenticación obligatoria mediante Firebase Authentication
- Reglas de seguridad de Firestore que garantizan:
  - Los usuarios solo pueden acceder a sus propios datos
  - No se permite acceso anónimo a datos sensibles
  - Validación de tipos y estructura de datos en el servidor
- Firebase Storage con reglas que verifican:
  - Autenticación del usuario
  - Límite de tamaño de archivos (10MB por archivo)
  - Tipos de archivo permitidos (solo imágenes y PDFs)
- Los datos en Firebase están cifrados en reposo por la infraestructura de Google Cloud

### 6.3 Seguridad de la Aplicación
- Ofuscación de código en versiones de producción (ProGuard/R8)
- Validación de entradas del usuario para prevenir datos malformados o inválidos
- Manejo seguro de credenciales (nunca se almacenan en texto plano)
- Gestión de permisos según el principio de mínimo privilegio
- Actualizaciones de seguridad regulares de dependencias

### 6.4 Seguridad Biométrica
- **Autenticación local**: La huella dactilar o reconocimiento facial se verifica localmente en su dispositivo mediante el hardware biométrico del fabricante
- **No se almacenan datos biométricos**: La aplicación no almacena, transmite ni tiene acceso a sus datos biométricos
- **Control total del usuario**: Puede habilitar o deshabilitar la autenticación biométrica en cualquier momento desde la configuración de su perfil
- **Fallback seguro**: Si la autenticación biométrica falla, siempre puede acceder mediante su contraseña
- **Estándar de la industria**: Utilizamos las API oficiales de Android (BiometricPrompt) que cumplen con los estándares de seguridad de Google

### 6.5 Prácticas de Seguridad del Usuario
Recomendamos:
- Usar contraseñas fuertes y únicas
- No compartir credenciales de acceso
- Mantener actualizado el sistema operativo de su dispositivo
- Cerrar sesión al terminar de usar la aplicación en dispositivos compartidos
- Solo habilitar la biometría en dispositivos personales de su confianza

## 7. Sus Derechos

Usted tiene derecho a:
- Acceder a todos sus datos almacenados
- Modificar o eliminar información
- Exportar sus datos en formato PDF o CSV
- Solicitar la eliminación de su cuenta y datos en Firebase contactando al desarrollador
- Desinstalar la aplicación (elimina los datos locales del dispositivo; los datos en Firebase persisten hasta que solicite su eliminación)

## 8. Datos de Menores

Esta aplicación no está diseñada para menores de 13 años y no recopila intencionalmente información de menores.

## 9. Cambios en la Política

Podemos actualizar esta política ocasionalmente. Los cambios se notificarán mediante una actualización de la fecha de "Última actualización" en esta página.

## 10. Retención de Datos

- Los datos locales se conservan hasta que usted los elimine o desinstale la aplicación
- Los datos en Firebase se conservan indefinidamente hasta que el usuario los elimine desde la app o solicite la eliminación de su cuenta al desarrollador
- Puede eliminar registros individuales en cualquier momento desde la propia aplicación

## 11. Servicios de Terceros

La aplicación utiliza los siguientes servicios de terceros:
- **Firebase Authentication, Firestore y Storage** (Google): Almacenamiento principal de datos, autenticación y archivos — sujeto a la [Política de Privacidad de Google](https://policies.google.com/privacy)
- **Google Play Billing**: Para procesamiento de pagos de suscripciones — sujeto a los [Términos de Servicio de Google Play](https://play.google.com/intl/es/about/play-terms/)
- **Flutter**: Framework de desarrollo de aplicaciones (no recopila datos de usuario)

No utilizamos servicios de análisis de terceros como Google Analytics, Firebase Analytics ni Crashlytics.

## 12. Modelo de Distribución

AutoGestión Max opera bajo un modelo freemium:
- **Plan gratuito**: Permite gestionar 1 vehículo sin costo
- **Planes de pago**: Disponibles en modalidad mensual y anual, permiten gestionar desde 2 hasta 50 vehículos según el plan contratado
- Los pagos se procesan exclusivamente a través de Google Play Billing
- No almacenamos datos de tarjetas de crédito ni información de pago directamente

## 13. Contacto

Para consultas sobre esta Política de Privacidad, solicitudes de eliminación de datos o cualquier duda relacionada con el manejo de su información:

- **Correo electrónico:** autogestionmax@mahondev.com
- **Desarrollador:** MahonDev

## 14. Consentimiento

Al descargar, instalar o utilizar AutoGestión Max, usted acepta las prácticas descritas en esta Política de Privacidad. Si no está de acuerdo con alguna parte de esta política, le recomendamos no utilizar la aplicación.

## Resumen de Permisos

| Permiso | Uso | Requerido |
|---------|-----|-----------|
| Cámara | Tomar fotos de vehículos, documentos y comprobantes de gastos | Sí |
| Cámara (QR) | Escanear códigos QR de facturas electrónicas del SAT | No |
| Almacenamiento | Guardar y leer imágenes/PDFs | Sí |
| Internet | Comunicación con Firebase (requerido para el funcionamiento completo) | Sí |
| Teléfono | Facilitar llamadas al conductor | No |
| Biometría (Huella/Rostro) | Acceso rápido y seguro mediante autenticación biométrica | No |

## Nota para Play Store

Esta aplicación está disponible públicamente en Google Play Store con modelo freemium, dirigida a propietarios y gestores de flotillas de vehículos.
