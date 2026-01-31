# Política de Privacidad - AutoGestión Max

**Última actualización:** 30 de enero de 2026

## 1. Introducción

Esta Política de Privacidad describe cómo AutoGestión Max ("nosotros", "la aplicación") recopila, usa y protege la información cuando utiliza nuestra aplicación móvil de gestión de flotilla de vehículos.

## 2. Información que Recopilamos

### 2.1 Información del Vehículo
- Datos del vehículo (marca, modelo, año, placa)
- Fotografías de vehículos
- Información de mantenimiento
- Documentos relacionados (seguro, tarjeta de circulación, contratos)
- Fechas de vencimiento de documentos
- Información del conductor (nombre, teléfono, correo electrónico)

### 2.2 Información Técnica
- Archivos de registro y diagnósticos
- Información del dispositivo

### 2.3 Permisos Utilizados
- **Cámara**: Para tomar fotografías de vehículos y documentos
- **Almacenamiento**: Para guardar y acceder a imágenes y documentos PDF
- **Internet**: Para sincronización con Firebase (opcional)
- **Teléfono**: Para facilitar llamadas telefónicas al conductor desde la aplicación (no se realizan llamadas sin su consentimiento explícito)

## 3. Cómo Usamos la Información

La información recopilada se utiliza exclusivamente para:
- Gestionar y organizar la información de su flotilla de vehículos
- Almacenar documentos e imágenes relacionadas con los vehículos
- Generar reportes y recordatorios de mantenimiento
- Sincronizar datos entre dispositivos (cuando Firebase está habilitado)
- Monitorear fechas de vencimiento y enviar alertas de renovación de documentos
- Facilitar la comunicación con conductores mediante llamadas telefónicas (solo cuando usted lo solicita explícitamente)

## 4. Almacenamiento de Datos

### 4.1 Almacenamiento Local
- Los datos se almacenan localmente en su dispositivo
- Las imágenes y documentos se guardan en el almacenamiento interno de la aplicación
- Los datos permanecen en su dispositivo y no son compartidos con terceros

### 4.2 Almacenamiento en la Nube (Opcional)
- Cuando Firebase está habilitado, los datos se sincronizan con Firebase Firestore y Firebase Storage
- Los datos en Firebase están protegidos con reglas de seguridad
- Solo los usuarios autorizados pueden acceder a estos datos

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
- Almacenamiento cifrado en el dispositivo mediante SQLite con cifrado
- Base de datos local protegida por el sistema de seguridad de Android
- Datos almacenados en el espacio privado de la aplicación (no accesibles por otras apps)
- Caché de imágenes protegido en directorio privado

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
- Copias de seguridad automáticas de Firebase con cifrado en reposo

### 6.3 Seguridad de la Aplicación
- Ofuscación de código en versiones de producción (ProGuard/R8)
- Validación de entradas del usuario para prevenir inyección de código
- Manejo seguro de credenciales (nunca se almacenan en texto plano)
- Gestión de permisos según el principio de mínimo privilegio
- Actualizaciones de seguridad regulares de dependencias

### 6.4 Prácticas de Seguridad del Usuario
Recomendamos:
- Usar contraseñas fuertes y únicas
- No compartir credenciales de acceso
- Mantener actualizado el sistema operativo de su dispositivo
- Cerrar sesión al terminar de usar la aplicación en dispositivos compartidos

## 7. Sus Derechos

Usted tiene derecho a:
- Acceder a todos sus datos almacenados
- Modificar o eliminar información
- Exportar sus datos
- Desinstalar la aplicación (elimina todos los datos locales)

## 8. Datos de Menores

Esta aplicación no está diseñada para menores de 13 años y no recopila intencionalmente información de menores.

## 9. Cambios en la Política

Podemos actualizar esta política ocasionalmente. Los cambios se notificarán mediante una actualización de la fecha de "Última actualización" en esta página.

## 10. Retención de Datos

- Los datos locales se conservan hasta que usted los elimine o desinstale la aplicación
- Los datos en Firebase se conservan según su configuración
- Puede eliminar todos sus datos en cualquier momento

## 11. Servicios de Terceros

La aplicación utiliza los siguientes servicios de terceros:
- **Firebase** (Google): Para almacenamiento y sincronización en la nube
  - Sujeto a la [Política de Privacidad de Google](https://policies.google.com/privacy)
- **Flutter**: Framework de desarrollo de aplicaciones

## 12. Uso Interno

Esta aplicación está diseñada para uso interno y privado:
- Destinada a un número limitado de usuarios (3-4 personas)
- Distribución cerrada a través de Google Play Store
- No es una aplicación pública

## 13. Contacto

Si tiene preguntas sobre esta Política de Privacidad, puede contactarnos en:
- **Email**: autogestionmax@mahondev.com
- **Desarrollador**: MahonDev
- **Paquete de aplicación**: com.mahondev.autogestionmax

## 14. Información Técnica de la Aplicación
Max
- **Nombre**: AutoGestión Max
- **Package ID**: com.mahondev.autogestionmax
- **Plataforma**: Android (API 24+)
- **Tipo de distribución**: Google Play Store (cerrada/interna)
- **Proyecto Firebase**: autogestion-pro

## 14. Consentimiento

Al usar AutoGestión Pro, usted consiente esta Política de Privacidad y acepta sus términos.

---

## Resumen de Permisos

| Permiso | Uso | Requerido |
|---------|-----|-----------|
| Cámara | Tomar fotos de vehículos y documentos | Sí |
| Almacenamiento | Guardar y leer imágenes/PDFs | Sí |
| Internet | Sincronizar con Firebase (opcional) | No |

## Nota para Play Store

Esta aplicación está configurada para distribución **cerrada interna** en Google Play Store, limitada a un grupo específico de usuarios (3-4 personas). No está disponible para el público en general.
