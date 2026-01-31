# 🚀 Inicio Rápido - AutoGestión Pro

## Pasos para Ejecutar la Aplicación

### 1. Instalar Dependencias ✅ (Ya Hecho)
```bash
flutter pub get
```

### 2. Configurar Firebase (IMPORTANTE)

Antes de ejecutar la app, necesitas configurar Firebase:

#### Opción A: Configuración Completa (Recomendada)
Sigue la guía detallada en [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

#### Opción B: Ejecutar Sin Firebase (Solo para Pruebas de UI)
La app está configurada para ejecutarse sin Firebase si no está disponible, pero NO podrás:
- Guardar vehículos
- Subir fotos
- Compartir documentos

### 3. Ejecutar la Aplicación

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en un dispositivo específico
flutter run -d <device-id>

# Ejecutar en modo release
flutter run --release
```

## 📱 Características Disponibles

### ✅ Ya Implementado
- Lista de vehículos con diseño moderno
- Agregar/Editar vehículos
- Secciones de documentos (Seguro, Conductor, Contrato, Tarjeta)
- Sistema de mantenimiento con checklist
- Mantenimiento detallado por sección (Motor, Frenos, etc.)
- Captura y almacenamiento de fotos
- Subida de documentos PDF
- Notas por sección
- Compartir por WhatsApp/Email
- Sincronización con Firebase

### 🎨 Diseño
- Gradientes azules modernos
- Iconos SVG personalizados (en `public/images/`)
- Responsive design
- Animaciones fluidas

## 🛠️ Comandos Útiles

```bash
# Limpiar el proyecto
flutter clean

# Obtener dependencias nuevamente
flutter pub get

# Verificar errores
flutter analyze

# Ver dispositivos conectados
flutter devices

# Hot reload (durante desarrollo)
# Presiona 'r' en la terminal

# Hot restart (durante desarrollo)
# Presiona 'R' en la terminal

# Generar APK para Android
flutter build apk --release

# Generar App Bundle para Google Play
flutter build appbundle --release

# Generar IPA para iOS
flutter build ios --release
```

## 📁 Assets Disponibles

Los siguientes assets SVG están en `public/images/`:
- `agregar-vehiculo.svg`
- `conductor.svg`
- `contrato.svg`
- `globo-de-agregar-mantenimiento.svg`
- `mantenimiento.svg`
- `menu-de-globo-de-mantenimiento.svg`
- `menu-mantenimiento.svg`
- `pantalla-principal.svg`
- `seguro.svg`
- `tarjeta-de-circulacion.svg`

## 🔧 Solución de Problemas Comunes

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "No Firebase App"
- Asegúrate de haber configurado Firebase correctamente
- Verifica que `google-services.json` esté en `android/app/`
- Para iOS, verifica `GoogleService-Info.plist` en `ios/Runner/`

### Error de permisos en Android
Agrega en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### Error de permisos en iOS
Agrega en `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para tomar fotos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a la galería para seleccionar fotos</string>
```

## 📊 Estructura de la App

```
Pantalla Principal (Lista de Vehículos)
│
├─ Agregar Vehículo
│  └─ Formulario (Nombre, Marca, Modelo, Año, Placa)
│
└─ Detalles del Vehículo
   ├─ Tab: Seguro (Fotos, PDFs, Notas)
   ├─ Tab: Conductor (Info, Fotos, PDFs, Notas)
   ├─ Tab: Contrato (Fotos, PDFs, Notas)
   ├─ Tab: Tarjeta de Circulación (Fotos, PDFs, Notas)
   └─ Tab: Mantenimiento
      ├─ Checklist de Inspección
      │  ├─ Interior/Exterior
      │  ├─ Bajo el Capó
      │  └─ Neumáticos
      └─ Mantenimiento Detallado
         ├─ Motor
         ├─ Dirección
         ├─ Pintura y Hojalatería
         ├─ Radiador
         ├─ Suspensión
         ├─ A/C
         ├─ Sistema Eléctrico
         ├─ Frenos
         └─ Transmisión
```

## 🎯 Próximos Pasos

1. **Configurar Firebase** (si aún no lo has hecho)
   - Sigue [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

2. **Agregar Autenticación**
   - Implementar Firebase Auth
   - Login con email/password

3. **Mejorar UI**
   - Usar los SVG personalizados
   - Agregar más animaciones

4. **Testing**
   - Probar en dispositivos reales
   - Agregar tests unitarios

## 📞 Ayuda

Si encuentras algún problema:
1. Revisa [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
2. Revisa [README.md](README.md)
3. Ejecuta `flutter doctor` para verificar tu instalación

## 🎉 ¡Listo para Empezar!

Ejecuta:
```bash
flutter run
```

Y comienza a gestionar tu flotilla de vehículos! 🚗
