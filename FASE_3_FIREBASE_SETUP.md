# 🔥 FASE 3: Configuración de Firebase + Autenticación

## Paso 1: Crear nuevo proyecto en Firebase Console

### 1.1 Acceder a Firebase Console
1. Ve a: https://console.firebase.google.com/
2. Click en "Agregar proyecto" o "Add project"

### 1.2 Configurar el proyecto
- **Nombre del proyecto**: `autogestion-max` (o el que prefieras)
- **Google Analytics**: Opcional (recomendado: Sí)
- **Cuenta de Analytics**: Selecciona una existente o crea nueva

### 1.3 Esperar a que se cree el proyecto (~30 segundos)

---

## Paso 2: Agregar apps al proyecto Firebase

### 2.1 Agregar app Android
1. En la consola de Firebase, click en el ícono de Android
2. **Package name**: `com.fartinara.autogestionmax`
3. **App nickname**: `AutoGestión Max Android`
4. **SHA-1**: (Opcional por ahora, se puede agregar después)
5. Click "Registrar app"
6. **Descargar google-services.json**
7. Colocar en: `android/app/google-services.json`

### 2.2 Agregar app iOS
1. Click en el ícono de iOS
2. **Bundle ID**: `com.fartinara.autogestionmax`
3. **App nickname**: `AutoGestión Max iOS`
4. Click "Registrar app"
5. **Descargar GoogleService-Info.plist**
6. Colocar en: `ios/Runner/GoogleService-Info.plist`

### 2.3 Agregar app Web (Opcional)
1. Click en el ícono de Web
2. **Nombre de la app**: `AutoGestión Max Web`
3. Click "Registrar app"
4. Copiar la configuración que aparece

---

## Paso 3: Habilitar Firebase Authentication

### 3.1 En Firebase Console
1. En el menú lateral, ir a **Build** > **Authentication**
2. Click "Get started" o "Comenzar"
3. En la pestaña "Sign-in method":

#### Habilitar Email/Password:
- Click en "Email/Password"
- Toggle ON en "Email/Password"
- **NO** habilites "Email link (passwordless sign-in)" por ahora
- Click "Save"

#### (Opcional) Habilitar Google Sign-In:
- Click en "Google"
- Toggle ON
- Seleccionar email de soporte del proyecto
- Click "Save"

### 3.2 Configurar Firestore Database
1. En el menú lateral, ir a **Build** > **Firestore Database**
2. Click "Create database"
3. **Ubicación**: Selecciona la más cercana (ej: `us-central`, `southamerica-east1`)
4. **Reglas de seguridad**: 
   - Seleccionar "Start in production mode"
   - Click "Next" y luego "Enable"

---

## Paso 4: Ejecutar FlutterFire CLI

### 4.1 Instalar FlutterFire CLI (si no lo tienes)
```bash
dart pub global activate flutterfire_cli
```

### 4.2 Configurar Firebase en el proyecto
```bash
cd c:\Dev\FlutterProjects\autogestion_max
flutterfire configure
```

Este comando:
- Detectará las apps configuradas
- Generará `lib/firebase_options.dart`
- Actualizará la configuración de Firebase

**Selecciona:**
- El proyecto que creaste (`autogestion-max`)
- Las plataformas: Android, iOS, Web (las que necesites)

---

## Paso 5: Verificar instalación

### 5.1 Archivos que deben existir:
- ✅ `android/app/google-services.json`
- ✅ `ios/Runner/GoogleService-Info.plist`
- ✅ `lib/firebase_options.dart`

### 5.2 Verificar que el proyecto compila:
```bash
flutter pub get
flutter run
```

---

## Paso 6: Configurar reglas de Firestore

### 6.1 En Firebase Console > Firestore Database > Rules

Reemplazar las reglas con:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Función helper para verificar autenticación
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Función helper para verificar dueño del documento
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Usuarios: solo el usuario puede leer/escribir sus propios datos
    match /users/{userId} {
      allow read, write: if isOwner(userId);
    }
    
    // Vehículos: solo el dueño puede leer/escribir
    match /vehicles/{vehicleId} {
      allow read, write: if isAuthenticated() 
        && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() 
        && request.resource.data.userId == request.auth.uid;
    }
    
    // Gastos: solo el dueño del vehículo puede acceder
    match /expenses/{expenseId} {
      allow read, write: if isAuthenticated() 
        && get(/databases/$(database)/documents/vehicles/$(resource.data.vehicleId)).data.userId == request.auth.uid;
    }
    
    // Mantenimientos: solo el dueño del vehículo puede acceder
    match /maintenance/{maintenanceId} {
      allow read, write: if isAuthenticated() 
        && get(/databases/$(database)/documents/vehicles/$(resource.data.vehicleId)).data.userId == request.auth.uid;
    }
    
    // Suscripciones: solo el usuario puede ver su suscripción
    match /subscriptions/{userId} {
      allow read: if isOwner(userId);
      allow write: if false; // Solo se escribe desde funciones del servidor
    }
  }
}
```

Click **"Publish"**

---

## 📋 CHECKLIST - Completar antes de continuar:

- [ ] Proyecto Firebase creado
- [ ] App Android agregada
- [ ] App iOS agregada
- [ ] `google-services.json` descargado y colocado
- [ ] `GoogleService-Info.plist` descargado y colocado
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore Database creado
- [ ] `flutterfire configure` ejecutado
- [ ] `lib/firebase_options.dart` generado
- [ ] Reglas de Firestore actualizadas
- [ ] `flutter pub get` ejecutado sin errores

---

## ⏭️ Siguiente paso:
Una vez completado todo el checklist, continuaremos con la implementación del código de autenticación (pantallas de login/registro).

**Avísame cuando hayas completado estos pasos o si necesitas ayuda con alguno.**
