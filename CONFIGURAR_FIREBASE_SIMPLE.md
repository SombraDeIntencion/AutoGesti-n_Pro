# 🚀 Guía Rápida: Configurar Firebase para AutoGestión Max

## OPCIÓN 1: Usar mismo proyecto Firebase (Más Rápido) ⚡

Si quieres probar rápido, puedes usar el mismo proyecto Firebase:

```bash
cd c:\Dev\FlutterProjects\autogestion_max
dart pub global run flutterfire_cli:flutterfire configure
```

Cuando pregunte:
1. "Reuse firebase.json?" → **NO**
2. Seleccionar proyecto → **autogestion-pro**
3. Plataformas → Seleccionar: **android, ios, web**

✅ Esto configurará automáticamente todo

---

## OPCIÓN 2: Crear proyecto nuevo Firebase (Recomendado) 🎯

### Paso 1: Crear proyecto en Firebase Console

1. Abre: https://console.firebase.google.com/
2. Click "Agregar proyecto"
3. Nombre: `AutoGestion Max` (o `autogestion-max`)
4. Habilitar Google Analytics: **Sí** (recomendado)
5. Seleccionar cuenta de Analytics
6. Click "Crear proyecto"
7. Esperar ~30 segundos

### Paso 2: Configurar con FlutterFire CLI

```bash
cd c:\Dev\FlutterProjects\autogestion_max
dart pub global run flutterfire_cli:flutterfire configure --project=autogestion-max
```

Seleccionar plataformas:
- ✅ android
- ✅ ios  
- ✅ web
- ❌ macos (opcional)
- ❌ windows (opcional)

### Paso 3: Habilitar Authentication

1. En Firebase Console → Build → **Authentication**
2. Click "Get started"
3. Pestaña "Sign-in method"
4. Click en **"Email/Password"**
5. Toggle **ON** el primero (Email/Password)
6. Click **"Save"**

### Paso 4: Crear Firestore Database

1. En Firebase Console → Build → **Firestore Database**
2. Click "Create database"
3. **Ubicación**: us-central o southamerica-east1
4. **Reglas**: Start in **production mode**
5. Click "Enable"

### Paso 5: Actualizar reglas de Firestore

En Firestore Database → Rules → Pegar esto:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    match /vehicles/{vehicleId} {
      allow read, write: if isAuthenticated() 
        && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() 
        && request.resource.data.userId == request.auth.uid;
    }
    
    match /expenses/{expenseId} {
      allow read, write: if isAuthenticated() 
        && get(/databases/$(database)/documents/vehicles/$(resource.data.vehicleId)).data.userId == request.auth.uid;
    }
    
    match /maintenance/{maintenanceId} {
      allow read, write: if isAuthenticated() 
        && get(/databases/$(database)/documents/vehicles/$(resource.data.vehicleId)).data.userId == request.auth.uid;
    }
  }
}
```

Click **"Publish"**

---

## Verificar que todo esté OK ✅

Después de configurar, debes tener:

```
autogestion_max/
├── lib/firebase_options.dart          ← ✅ Generado por FlutterFire
├── android/app/google-services.json   ← ✅ Generado por FlutterFire
├── ios/Runner/GoogleService-Info.plist ← ✅ Generado por FlutterFire
└── firebase.json                       ← ✅ Generado por FlutterFire
```

---

## Actualizar main.dart

Después de configurar Firebase, ejecuta:

```bash
# Actualizar dependencias
flutter pub get

# Probar que compile
flutter run
```

---

## ¿Qué opción elegir?

| Opción | Ventajas | Desventajas |
|--------|----------|-------------|
| **Opción 1** (mismo proyecto) | ⚡ Rápido, ya configurado | 🔴 Ambas apps comparten datos |
| **Opción 2** (nuevo proyecto) | ✅ Apps completamente separadas | ⏱️ Toma ~5 minutos más |

### Recomendación:
- **Para desarrollo/pruebas**: Opción 1
- **Para producción**: Opción 2

---

**¿Qué opción prefieres?** Avísame y te ayudo con los siguientes pasos.
