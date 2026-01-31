# Guía de Publicación en Play Store - AutoGestión Pro
## Distribución Interna Cerrada (3-4 usuarios)

### 1. Preparación de la Aplicación

#### 1.1 Icono de la Aplicación
- **Requisitos**: 512x512 píxeles, PNG de 32 bits, máximo 1 MB
- **Ubicación**: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Crear diferentes resoluciones:
  - mipmap-mdpi: 48x48
  - mipmap-hdpi: 72x72
  - mipmap-xhdpi: 96x96
  - mipmap-xxhdpi: 144x144
  - mipmap-xxxhdpi: 192x192

#### 1.2 Capturas de Pantalla
Para el listado de Play Store, necesitarás:
- Al menos 2 capturas de pantalla
- Formato: JPG o PNG de 24 bits
- Dimensiones mínimas: 320 píxeles
- Dimensiones máximas: 3840 píxeles
- Proporción: Entre 16:9 y 9:16

#### 1.3 Gráfico de Funciones
- **Tamaño**: 1024 x 500 píxeles
- **Formato**: PNG o JPG de 24 bits

### 2. Generar el App Bundle (.aab)

#### 2.1 Crear Keystore para Firma (IMPORTANTE)

```bash
# Ejecutar en la terminal
keytool -genkey -v -keystore c:\Dev\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Guardar la contraseña en un lugar seguro
```

#### 2.2 Configurar key.properties

Crear archivo: `android/key.properties`
```properties
storePassword=<tu-contraseña>
keyPassword=<tu-contraseña>
keyAlias=upload
storeFile=c:/Dev/upload-keystore.jks
```

#### 2.3 Modificar build.gradle.kts

Ya está configurado en el archivo actual. Asegúrate de tener la configuración de firma.

#### 2.4 Compilar el App Bundle

```bash
# Limpiar proyecto
flutter clean

# Obtener dependencias
flutter pub get

# Compilar para release
flutter build appbundle --release
```

El archivo generado estará en:
`build/app/outputs/bundle/release/app-release.aab`

### 3. Configuración de Google Play Console

#### 3.1 Crear Aplicación en Play Console
1. Ve a https://play.google.com/console
2. Crea una nueva aplicación
3. Selecciona "Aplicación" como tipo
4. Define el idioma predeterminado (Español)
5. Título: "AutoGestión Pro"
6. Nombre corto: "AutoGestión Pro"

#### 3.2 Completar Información de la Tienda

**Descripción Breve** (80 caracteres):
```
Gestión profesional de flotilla de vehículos para uso interno
```

**Descripción Completa** (4000 caracteres):
```
AutoGestión Pro es una aplicación de gestión de flotilla de vehículos diseñada para uso interno empresarial.

CARACTERÍSTICAS PRINCIPALES:
✓ Registro completo de vehículos
✓ Gestión de mantenimientos
✓ Seguimiento de conductores
✓ Almacenamiento de documentos
✓ Generación de reportes
✓ Recordatorios automáticos

PERMISOS:
• Cámara: Para fotografiar vehículos y documentos
• Almacenamiento: Para guardar imágenes y PDFs
• Internet: Para sincronización opcional

NOTA: Esta aplicación está diseñada para uso interno y distribuida de forma cerrada.
```

#### 3.3 Categorización
- **Categoría**: Productividad
- **Etiquetas**: empresa, vehículos, gestión, flotilla

#### 3.4 Información de Contacto
- Email de desarrollador: [tu-email@ejemplo.com]
- Sitio web (opcional): [tu-sitio-web]
- Política de privacidad: [URL donde hospedarás privacy_policy.html]

### 4. Configurar Prueba Interna/Cerrada

#### 4.1 Opción 1: Prueba Interna (Recomendado para 3-4 usuarios)
1. En Play Console, ve a "Pruebas" > "Prueba interna"
2. Crea una nueva versión
3. Sube el archivo `app-release.aab`
4. Configura los evaluadores:
   - Crea una lista de correos electrónicos
   - Añade los 3-4 usuarios (sus cuentas de Gmail)
5. Guarda y publica la versión de prueba

#### 4.2 Opción 2: Prueba Cerrada
1. Ve a "Pruebas" > "Prueba cerrada"
2. Sube el app bundle
3. Crea una lista de evaluadores
4. Define el número de usuarios (3-4)

#### 4.3 Opción 3: Lanzamiento Gestionado (Más privado)
1. Publica en producción pero sin hacer público
2. Usa la función "País/Región" para limitar disponibilidad
3. No completes el listado público para que no aparezca en búsquedas

### 5. Configuración de Seguridad y Privacidad

#### 5.1 Declaración de Seguridad de Datos
En Play Console > "Seguridad de datos":

**Datos Recopilados:**
- Fotos y vídeos
- Archivos y documentos
- Información del dispositivo

**Uso de los datos:**
- Funcionalidad de la aplicación
- Almacenamiento y sincronización

**Compartir datos:**
- No se comparten datos con terceros

#### 5.2 Política de Privacidad
- Sube `privacy_policy.html` a un servidor web o GitHub Pages
- Añade la URL en Play Console

### 6. Revisión de Contenido

#### 6.1 Cuestionario de Contenido
- Clasificación de contenido: Para todos
- Sin anuncios
- Sin compras dentro de la app
- Sin contenido sensible

#### 6.2 Cumplimiento
- Declarar que cumple con las políticas de Google
- No contiene contenido restringido
- Uso interno empresarial

### 7. Lanzamiento

#### 7.1 Para Prueba Interna (Más Rápido)
```
Play Console > Pruebas > Prueba interna > Nueva versión
- Subir AAB
- Notas de versión: "Versión inicial 1.0.0"
- Revisar > Implementar
```

**Tiempo de revisión:** Normalmente instantáneo o 1-2 horas

#### 7.2 Invitar Usuarios
1. Los usuarios recibirán un link de invitación
2. Deben aceptar ser evaluadores
3. Descargan desde Play Store con su cuenta de Gmail

### 8. Actualizaciones Futuras

```bash
# Incrementar versión en build.gradle.kts
# versionCode = 2
# versionName = "1.0.1"

# Compilar nueva versión
flutter build appbundle --release

# Subir a Play Console
# Play Console > Prueba interna > Nueva versión
```

### 9. Consideraciones Importantes

#### 9.1 Para Distribución Cerrada Permanente
- ✅ Mantener en "Prueba interna" indefinidamente
- ✅ No requiere revisión completa de Google
- ✅ Actualizaciones más rápidas
- ✅ Hasta 100 evaluadores permitidos
- ✅ Ideal para 3-4 usuarios

#### 9.2 Límites de Prueba Interna
- No aparece en búsquedas de Play Store
- Usuarios necesitan link de invitación
- Requiere cuenta de Gmail
- Sin revisión de contenido extensa

#### 9.3 Alternativa: App Signing de Google
- Play Console > Configuración > Integridad de la app
- Permitir que Google gestione la clave de firma
- Más seguro y recomendado

### 10. Checklist Final

Antes de publicar, verifica:
- [ ] App Bundle compilado (.aab)
- [ ] Keystore guardado en lugar seguro
- [ ] Versión configurada (1.0.0)
- [ ] Icono de 512x512 creado
- [ ] Capturas de pantalla tomadas
- [ ] Política de privacidad publicada
- [ ] Usuarios evaluadores listados (3-4 emails)
- [ ] Descripción completada
- [ ] Categoría seleccionada
- [ ] Declaración de seguridad de datos
- [ ] Cuestionario de contenido completado

### 11. Comandos Útiles

```bash
# Ver información de la app compilada
flutter build appbundle --release --verbose

# Verificar firma del bundle
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab

# Analizar tamaño del bundle
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks
```

### 12. Solución de Problemas Comunes

#### Error: "La app no está firmada"
- Verifica que `key.properties` existe
- Comprueba las rutas en build.gradle.kts

#### Error: "Version code must be higher"
- Incrementa versionCode en build.gradle.kts

#### Error: "Bundle contains native code"
- Normal, ignóralo si no usas código nativo específico

### 13. Contacto y Soporte

Para problemas durante la publicación:
- Google Play Console Help: https://support.google.com/googleplay/android-developer
- Flutter Documentation: https://docs.flutter.dev/deployment/android

---

## Resumen Rápido para 3-4 Usuarios

**Opción Recomendada:** PRUEBA INTERNA

1. Crear keystore y firmar app
2. `flutter build appbundle --release`
3. Subir AAB a Play Console > Prueba interna
4. Añadir 3-4 emails de usuarios
5. Enviar link de invitación
6. Usuarios descargan desde Play Store

**Ventajas:**
- ✅ Sin revisión pública
- ✅ Actualizaciones inmediatas
- ✅ Privado y seguro
- ✅ Fácil de gestionar
