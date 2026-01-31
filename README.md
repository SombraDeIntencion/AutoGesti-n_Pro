# utoGestión Pro

Aplicación móvil Flutter para la gestión completa de flotillas de vehículos, incluyendo mantenimiento, documentos, seguros y más.

## 📱 Características

### Gestión de Vehículos
- ✅ Agregar/Editar/Eliminar vehículos
- ✅ Información detallada de cada vehículo
- ✅ Foto del vehículo
- ✅ Datos: marca, modelo, año, placa

### Secciones por Vehículo

#### 1. Seguro
- 📷 Fotos de póliza
- 📄 Documentos PDF
- 📝 Notas
- 🔄 Compartir por WhatsApp/Email

#### 2. Conductor
- 👤 Información personal (nombre, teléfono, email)
- 📷 Fotos (licencia, identificación)
- 📄 Documentos PDF
- 📝 Notas

#### 3. Contrato
- 📷 Fotos del contrato
- 📄 Documentos PDF
- 📝 Notas

#### 4. Tarjeta de Circulación
- 📷 Fotos
- 📄 Documentos PDF
- 📝 Notas

#### 5. Mantenimiento
##### Checklist de Inspección
- 🔍 Inspección visual del vehículo
- 📊 Estados: OK, Requiere Atención, Atención Inmediata
- 🎨 Código de colores (Verde, Amarillo, Rojo)
- 📍 Categorías: Interior/Exterior, Bajo el Capó, Neumáticos

##### Mantenimiento Detallado por Sección
- 🔧 Motor
- 🎯 Dirección
- 🎨 Pintura y Hojalatería
- ❄️ Radiador
- ⚙️ Suspensión
- 🌬️ A/C
- ⚡ Sistema Eléctrico
- 🛑 Frenos
- 🔄 Transmisión

Cada registro de mantenimiento incluye:
- Descripción del problema/trabajo
- 📷 Fotos del problema
- 📷 Fotos de piezas viejas
- 📷 Fotos de piezas nuevas
- 📷 Fotos del resultado final
- 📏 Kilometraje actual
- 📏 Próximo cambio (km)
- 📅 Fecha del servicio

### Almacenamiento en la Nube
- ☁️ Firebase Storage para fotos y PDFs
- ☁️ Cloud Firestore para datos
- 🔄 Sincronización automática

### Compartir
- 📱 WhatsApp
- 📧 Correo electrónico
- 📤 Compartir documentos PDF

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK (>=3.9.2)
- Dart SDK
- Android Studio / Xcode
- Cuenta de Firebase

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd autogestion_pro
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**

#### Android
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o usa uno existente
3. Agrega una aplicación Android
4. Descarga `google-services.json`
5. Coloca el archivo en `android/app/`

#### iOS
1. En Firebase Console, agrega una aplicación iOS
2. Descarga `GoogleService-Info.plist`
3. Coloca el archivo en `ios/Runner/`

4. **Configurar Firebase Storage y Firestore**
- Habilita Cloud Firestore en Firebase Console
- Habilita Firebase Storage en Firebase Console
- Configura las reglas de seguridad:

**Firestore Rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /vehicles/{vehicleId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Storage Rules:**
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /vehicles/{vehicleId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

5. **Ejecutar la aplicación**
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/                   # Modelos de datos
│   ├── vehicle.dart
│   ├── document_section.dart
│   ├── driver_section.dart
│   ├── maintenance_data.dart
│   ├── maintenance_item.dart
│   ├── checklist_item.dart
│   └── maintenance_section_data.dart
├── screens/                  # Pantallas de la app
│   ├── vehicle_list_screen.dart
│   ├── vehicle_form_screen.dart
│   └── vehicle_details_screen.dart
├── widgets/                  # Widgets reutilizables
│   ├── document_section_tab.dart
│   ├── driver_section_tab.dart
│   └── maintenance_section_tab.dart
└── services/                 # Servicios
    ├── firebase_service.dart
    ├── media_service.dart
    └── share_service.dart
```

## 🎨 Paleta de Colores

- **Azul Oscuro**: `#1E40AF` - Header y elementos principales
- **Azul Medio**: `#3B82F6` - Gradientes
- **Cyan**: `#06B6D4` - Botones de acción
- **Verde**: `#22C55E` - Estado OK
- **Amarillo**: `#FBBF24` - Requiere atención
- **Rojo**: `#EF4444` - Atención inmediata

## 📦 Dependencias Principales

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_storage: ^12.3.8
  cloud_firestore: ^5.5.2
  image_picker: ^1.1.2
  file_picker: ^8.1.4
  share_plus: ^10.1.2
  url_launcher: ^6.3.1
  pdf: ^3.11.1
  printing: ^5.13.4
  provider: ^6.1.2
  uuid: ^4.5.1
  intl: ^0.20.1
  flutter_svg: ^2.0.10+1
```

## 🔧 Configuración de Permisos

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Esta app necesita acceso a la cámara para tomar fotos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Esta app necesita acceso a la galería para seleccionar fotos</string>
```

## 🎯 Próximas Características

- [ ] Autenticación de usuarios
- [ ] Notificaciones de mantenimiento pendiente
- [ ] Exportar reportes completos en PDF
- [ ] Dashboard con estadísticas
- [ ] Modo offline
- [ ] Multi-idioma

## 📄 Licencia

Este proyecto es de uso privado.

## 👨‍💻 Desarrollo

Para contribuir al desarrollo:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Para soporte, contacta al equipo de desarrollo.

