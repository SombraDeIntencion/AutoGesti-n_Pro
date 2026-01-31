# Configuración de Firebase para AutoGestión Pro

Esta guía te ayudará a configurar Firebase para la aplicación AutoGestión Pro.

## Paso 1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Ingresa el nombre: "AutoGestión Pro"
4. Acepta los términos y continúa
5. (Opcional) Habilita Google Analytics
6. Haz clic en "Crear proyecto"

## Paso 2: Configurar Android

1. En la página de inicio del proyecto, haz clic en el ícono de Android
2. Ingresa los siguientes datos:
   - **Nombre del paquete de Android**: `com.example.autogestion_pro`
   - **Alias de la app**: AutoGestión Pro
   - **Certificado de firma SHA-1**: (opcional por ahora)

3. Haz clic en "Registrar app"

4. **Descargar google-services.json**
   - Descarga el archivo `google-services.json`
   - Copia el archivo a: `android/app/google-services.json`

5. **Configurar build.gradle**

   Archivo: `android/build.gradle.kts`
   ```kotlin
   buildscript {
       dependencies {
           // ... otras dependencias
           classpath("com.google.gms:google-services:4.4.0")
       }
   }
   ```

   Archivo: `android/app/build.gradle.kts`
   ```kotlin
   plugins {
       // ... otros plugins
       id("com.google.gms.google-services")
   }
   ```

6. Haz clic en "Siguiente" y luego en "Continuar a la consola"

## Paso 3: Configurar iOS (Opcional)

1. En la consola de Firebase, haz clic en el ícono de iOS
2. Ingresa:
   - **ID del paquete de iOS**: `com.example.autogestionPro`
   - **Alias de la app**: AutoGestión Pro

3. Descarga `GoogleService-Info.plist`
4. Copia el archivo a: `ios/Runner/GoogleService-Info.plist`

## Paso 4: Habilitar Cloud Firestore

1. En el menú lateral, ve a **Compilación > Firestore Database**
2. Haz clic en "Crear base de datos"
3. Selecciona "Iniciar en modo de prueba"
4. Elige una ubicación (por ejemplo: `us-central`)
5. Haz clic en "Habilitar"

### Configurar Reglas de Seguridad

En la pestaña "Reglas", reemplaza el contenido con:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Colección de vehículos
    match /vehicles/{vehicleId} {
      // Por ahora, permitir lectura y escritura a todos
      // TODO: Agregar autenticación de usuarios
      allow read, write: if true;
    }
  }
}
```

**IMPORTANTE**: Estas reglas son para desarrollo. Para producción, debes implementar autenticación.

## Paso 5: Habilitar Firebase Storage

1. En el menú lateral, ve a **Compilación > Storage**
2. Haz clic en "Comenzar"
3. Selecciona "Iniciar en modo de prueba"
4. Haz clic en "Siguiente"
5. Elige una ubicación (la misma que Firestore)
6. Haz clic en "Listo"

### Configurar Reglas de Seguridad

En la pestaña "Reglas", reemplaza el contenido con:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /vehicles/{vehicleId}/{allPaths=**} {
      // Por ahora, permitir lectura y escritura a todos
      // TODO: Agregar autenticación de usuarios
      allow read, write: if true;
    }
  }
}
```

## Paso 6: Verificar Instalación

1. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

2. Si ves errores de Firebase, verifica:
   - Que `google-services.json` esté en `android/app/`
   - Que hayas ejecutado `flutter pub get`
   - Que las reglas de Firestore y Storage estén configuradas

## Estructura de Datos en Firestore

### Colección: vehicles

Cada documento representa un vehículo:

```json
{
  "id": "uuid-del-vehiculo",
  "name": "Nissan Versa",
  "brand": "Nissan",
  "model": "Versa",
  "year": 2022,
  "plate": "ABC-123",
  "photo": "url-de-la-foto-opcional",
  "insurance": {
    "photos": ["url1", "url2"],
    "pdfs": ["url-pdf1"],
    "notes": "Notas sobre el seguro"
  },
  "driver": {
    "name": "Juan Pérez",
    "phone": "+52 123 456 7890",
    "email": "juan@example.com",
    "photos": ["url-licencia"],
    "pdfs": [],
    "notes": ""
  },
  "contract": {
    "photos": [],
    "pdfs": ["url-contrato"],
    "notes": ""
  },
  "circulationCard": {
    "photos": ["url-tarjeta"],
    "pdfs": [],
    "notes": ""
  },
  "maintenance": {
    "checklist": [],
    "sections": [
      {
        "id": "motor",
        "name": "Motor",
        "items": [
          {
            "id": "uuid-item",
            "what": "Cambio de aceite",
            "problemPhotos": [],
            "oldPartsPhotos": ["url-aceite-viejo"],
            "newPartsPhotos": ["url-aceite-nuevo"],
            "afterPhotos": ["url-motor-limpio"],
            "currentKm": 50000,
            "nextChangeKm": 55000,
            "date": "2024-01-15T10:00:00.000Z"
          }
        ]
      }
    ]
  }
}
```

## Estructura de Storage

```
vehicles/
├── {vehicleId}/
│   ├── seguro/
│   │   ├── 1642345678901.jpg
│   │   ├── 1642345678902.jpg
│   │   └── 1642345678903.pdf
│   ├── conductor/
│   │   └── 1642345678904.jpg
│   ├── contrato/
│   │   └── 1642345678905.pdf
│   ├── tarjeta_circulacion/
│   │   └── 1642345678906.jpg
│   └── mantenimiento/
│       ├── 1642345678907.jpg
│       ├── 1642345678908.jpg
│       └── 1642345678909.jpg
```

## Solución de Problemas

### Error: "Default FirebaseApp is not initialized"

1. Verifica que `google-services.json` esté en la ubicación correcta
2. Ejecuta `flutter clean` y luego `flutter pub get`
3. Reconstruye la aplicación

### Error: "FirebaseException: PERMISSION_DENIED"

1. Verifica las reglas de Firestore y Storage
2. Asegúrate de que las reglas permitan acceso (modo de prueba)

### La app no se conecta a Firebase

1. Verifica tu conexión a internet
2. Revisa que el proyecto de Firebase esté activo
3. Verifica que el paquete de la app coincida con el configurado en Firebase

## Próximos Pasos

1. **Implementar Autenticación**
   - Habilitar Firebase Authentication
   - Agregar inicio de sesión con email/password o Google
   - Actualizar reglas de seguridad para requerir autenticación

2. **Configurar Índices**
   - Firestore puede requerir índices para consultas complejas
   - Los índices se crearán automáticamente cuando sean necesarios

3. **Monitoreo y Analytics**
   - Habilitar Firebase Analytics para rastrear uso
   - Configurar Firebase Crashlytics para reportes de errores

## Recursos Adicionales

- [Documentación de FlutterFire](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Reglas de Seguridad de Firestore](https://firebase.google.com/docs/firestore/security/get-started)
- [Reglas de Seguridad de Storage](https://firebase.google.com/docs/storage/security/start)
