# 🔥 FASE 6: Configuración Firebase Real + Suscripciones Google Play

## 📋 Objetivo
Conectar la aplicación con Firebase real y configurar el sistema de suscripciones in-app purchases de Google Play.

---

## PASO 1: Crear Proyecto Firebase

### 1.1 Accede a Firebase Console
1. Ve a [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Inicia sesión con tu cuenta de Google
3. Click en **"Agregar proyecto"** / **"Add project"**

### 1.2 Configuración del Proyecto
```
Nombre del proyecto: autogestion-max (o el que prefieras)
✓ Acepta los términos
✓ Habilita Google Analytics (recomendado)
✓ Selecciona o crea una cuenta de Analytics
```

### 1.3 Espera a que se cree el proyecto
⏱️ Tarda aproximadamente 1-2 minutos

---

## PASO 2: Agregar App Android a Firebase

### 2.1 En la página principal del proyecto
1. Click en el icono de **Android** para agregar una app Android
2. Completa la información:

```
Nombre del paquete Android: com.mdigitals.autogestion_pro
Apodo de la app (opcional): AutoGestión Max Android
SHA-1 de certificado de firma: [LO OBTENDREMOS]
```

### 2.2 Obtener SHA-1 (Importante para Authentication)
Ejecuta este comando en PowerShell desde la raíz del proyecto:

```powershell
cd android
./gradlew signingReport
```

**Busca en el output:**
```
Variant: debug
Config: debug
Store: C:\Users\[TU_USUARIO]\.android\debug.keystore
Alias: AndroidDebugKey
MD5: ...
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: ...
```

Copia el valor del **SHA1** y pégalo en Firebase.

### 2.3 Descargar google-services.json
1. Click en **"Registrar app"**
2. Descarga el archivo `google-services.json`
3. **REEMPLAZA** el archivo actual en: `android/app/google-services.json`

### 2.4 No necesitas modificar build.gradle
Ya tenemos las dependencias configuradas, Firebase solo te pedirá confirmar.

---

## PASO 3: Configurar Firebase Authentication

### 3.1 En Firebase Console
1. Ve a **"Authentication"** en el menú lateral
2. Click en **"Comenzar"** / **"Get started"**
3. Ve a la pestaña **"Sign-in method"**

### 3.2 Habilitar proveedores de autenticación

#### ✅ Email/Contraseña
1. Click en **"Email/Password"**
2. **Habilita** el primer switch (Email/Password)
3. **Guarda**

#### ✅ Google Sign-In
1. Click en **"Google"**
2. **Habilita** el switch
3. Correo de asistencia del proyecto: [tu-email@gmail.com]
4. **Guarda**

### 3.3 Configurar dominios autorizados
1. Ve a la pestaña **"Settings"** → **"Authorized domains"**
2. Deberían estar ya autorizados:
   - `localhost`
   - `[tu-proyecto].firebaseapp.com`

---

## PASO 4: Configurar Firestore Database

### 4.1 Crear base de datos
1. Ve a **"Firestore Database"** en el menú lateral
2. Click en **"Crear base de datos"** / **"Create database"**

### 4.2 Configuración de seguridad inicial
Selecciona: **"Comenzar en modo de prueba"** / **"Start in test mode"**
```
Reglas iniciales (30 días):
allow read, write: if request.time < timestamp.date(2026, 3, 1);
```
⚠️ **Cambiaremos las reglas más adelante**

### 4.3 Ubicación
Selecciona la ubicación más cercana:
- `us-central1` (Iowa) - Recomendado para Latinoamérica
- `southamerica-east1` (São Paulo) - Si prefieres Sudamérica

**⚠️ No se puede cambiar después**

### 4.4 Click en **"Habilitar"**

### 4.5 Configurar reglas de seguridad definitivas
1. Ve a la pestaña **"Reglas"** / **"Rules"**
2. Reemplaza con nuestras reglas personalizadas:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Función auxiliar para verificar autenticación
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Función para verificar si el usuario es el propietario
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Colección de usuarios
    match /users/{userId} {
      // Leer: solo el propio usuario
      allow read: if isOwner(userId);
      
      // Crear: solo si es el propio usuario y los campos son válidos
      allow create: if isOwner(userId) && 
        request.resource.data.keys().hasAll(['email', 'displayName', 'subscriptionType']) &&
        request.resource.data.subscriptionType in ['free', 'basico', 'estandar', 'premium'];
      
      // Actualizar: solo el propio usuario
      allow update: if isOwner(userId);
      
      // Eliminar: solo el propio usuario
      allow delete: if isOwner(userId);
      
      // Sub-colección de vehículos
      match /vehicles/{vehicleId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) && 
          request.resource.data.keys().hasAll(['marca', 'modelo', 'anio', 'placa']);
        allow update: if isOwner(userId);
        allow delete: if isOwner(userId);
        
        // Sub-colección de mantenimientos
        match /maintenances/{maintenanceId} {
          allow read: if isOwner(userId);
          allow create: if isOwner(userId);
          allow update: if isOwner(userId);
          allow delete: if isOwner(userId);
        }
      }
    }
    
    // Colección de suscripciones (para validación de pagos)
    match /subscriptions/{subscriptionId} {
      allow read: if isSignedIn() && request.auth.uid == resource.data.userId;
      allow create: if isSignedIn() && request.auth.uid == request.resource.data.userId;
      allow update: if isSignedIn() && request.auth.uid == resource.data.userId;
    }
  }
}
```

3. Click en **"Publicar"** / **"Publish"**

---

## PASO 5: Actualizar Credenciales en la App

### 5.1 Ejecutar FlutterFire CLI
En PowerShell, desde la raíz del proyecto:

```powershell
# Instalar FlutterFire CLI (si no lo tienes)
dart pub global activate flutterfire_cli

# Configurar Firebase en el proyecto
flutterfire configure --project=autogestion-max
```

**Selecciona:**
- [x] android
- [ ] ios (opcional, si quieres iOS)
- [ ] web (opcional)

### 5.2 Esto generará/actualizará:
- ✅ `lib/firebase_options.dart` con las credenciales reales
- ✅ `android/app/google-services.json`

---

## PASO 6: Probar Firebase

### 6.1 Ejecutar la app
```powershell
flutter run
```

### 6.2 Probar Authentication
1. **Registro**: Crea una cuenta nueva
2. Ve a Firebase Console → Authentication → Users
3. Deberías ver el usuario creado ✅

### 6.3 Probar Firestore
1. **Agregar vehículo** en la app
2. Ve a Firebase Console → Firestore Database
3. Deberías ver:
   ```
   users/
     └─ [userId]/
         ├─ email: "..."
         ├─ displayName: "..."
         ├─ subscriptionType: "free"
         └─ vehicles/
             └─ [vehicleId]/
                 ├─ marca: "..."
                 ├─ modelo: "..."
                 └─ ...
   ```

---

## PASO 7: Configurar Google Play Console (Suscripciones)

### 7.1 Requisitos previos
- ✅ App publicada en Play Store (aunque sea en prueba interna/cerrada)
- ✅ Cuenta de desarrollador de Google Play ($25 USD único pago)
- ✅ Cuenta bancaria o PayPal vinculada para recibir pagos

### 7.2 Crear suscripciones in-app
1. Ve a [Google Play Console](https://play.google.com/console/)
2. Selecciona tu app: **AutoGestión Max**
3. Ve a **"Monetizar"** → **"Productos"** → **"Suscripciones"**
4. Click en **"Crear suscripción"**

### 7.3 Configurar cada suscripción

#### 🥉 Plan Básico
```
ID del producto: autogestion_basico
Nombre: Plan Básico
Descripción: Hasta 3 vehículos + Soporte
Precio: $2.99 USD/mes (ajusta según tu país)
Período de suscripción: 1 mes
Renovación automática: Sí
Prueba gratuita: 7 días (opcional)
```

#### 🥈 Plan Estándar
```
ID del producto: autogestion_estandar
Nombre: Plan Estándar
Descripción: Hasta 10 vehículos + Recordatorios + Soporte prioritario
Precio: $4.99 USD/mes
Período de suscripción: 1 mes
Renovación automática: Sí
Prueba gratuita: 7 días (opcional)
```

#### 🥇 Plan Premium
```
ID del producto: autogestion_premium
Nombre: Plan Premium
Descripción: Vehículos ilimitados + Respaldo en la nube + Reportes + Soporte VIP
Precio: $7.99 USD/mes
Período de suscripción: 1 mes
Renovación automática: Sí
Prueba gratuita: 7 días (opcional)
```

### 7.4 Activar las suscripciones
- Asegúrate de **activar** cada suscripción
- Guarda los **ID de producto** (los necesitaremos en el código)

---

## PASO 8: Configurar in_app_purchase en la App

### 8.1 Verificar dependencias
Ya tenemos `in_app_purchase` en `pubspec.yaml` ✅

### 8.2 Actualizar IDs de productos reales
Archivo: `lib/services/subscription_service.dart`

Cambiar de:
```dart
static const String basicSubscriptionId = 'autogestion_basico_test';
static const String standardSubscriptionId = 'autogestion_estandar_test';
static const String premiumSubscriptionId = 'autogestion_premium_test';
```

A:
```dart
static const String basicSubscriptionId = 'autogestion_basico';
static const String standardSubscriptionId = 'autogestion_estandar';
static const String premiumSubscriptionId = 'autogestion_premium';
```

### 8.3 Configurar licencia en Android
Ya está configurado en `android/app/build.gradle.kts` ✅

---

## PASO 9: Probar Suscripciones

### 9.1 Configurar cuenta de prueba
1. En Google Play Console → Configuración → Licencia y pruebas
2. Agrega tu email como **"Tester de licencia"**
3. Agrega tu email en **"Probadores internos"** o **"Prueba cerrada"**

### 9.2 Probar en dispositivo real
⚠️ **Las suscripciones NO funcionan en emulador**

```powershell
# Generar APK de prueba
flutter build apk --debug

# Instalar en dispositivo
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 9.3 Probar flujo completo
1. **Registro** de usuario
2. **Ver planes** disponibles
3. **Seleccionar** un plan (Básico/Estándar/Premium)
4. **Completar compra** (tarjeta de prueba de Google)
5. **Verificar** que se actualiza en Firestore
6. **Agregar vehículos** según el nuevo límite

### 9.4 Verificar en Firebase
```
users/[userId]/
  ├─ subscriptionType: "basico" | "estandar" | "premium"
  ├─ subscriptionStatus: "active"
  └─ subscriptionEndDate: Timestamp

subscriptions/[subscriptionId]/
  ├─ userId: "..."
  ├─ productId: "autogestion_basico"
  ├─ purchaseToken: "..."
  └─ ...
```

---

## PASO 10: Configurar Webhooks (Opcional pero recomendado)

Para validación server-side de compras, puedes configurar Cloud Functions que escuchen eventos de Google Play.

### 10.1 Habilitar Cloud Functions
```powershell
firebase init functions
```

### 10.2 Crear función de validación
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

exports.validatePurchase = functions.https.onCall(async (data, context) => {
  // Validar purchase token con Google Play API
  // Actualizar Firestore con el estado verificado
});
```

**Esto lo configuraremos más adelante si lo necesitas** 🚀

---

## 📋 Checklist Final

### Firebase
- [ ] Proyecto Firebase creado
- [ ] App Android agregada con SHA-1
- [ ] Authentication habilitado (Email + Google)
- [ ] Firestore creado con reglas de seguridad
- [ ] `firebase_options.dart` actualizado
- [ ] Registro de usuario funciona
- [ ] Guardar datos en Firestore funciona

### Google Play Console
- [ ] App publicada (prueba interna mínimo)
- [ ] Suscripciones creadas (Básico, Estándar, Premium)
- [ ] IDs de producto configurados en el código
- [ ] Cuenta de prueba agregada
- [ ] Compra de prueba realizada exitosamente

### Testing
- [ ] Usuario puede registrarse
- [ ] Usuario puede agregar vehículo (limite free)
- [ ] Usuario ve planes disponibles
- [ ] Usuario puede comprar suscripción
- [ ] Límite se actualiza según el plan
- [ ] Datos se sincronizan con Firebase

---

## 🎯 Próximos Pasos

Una vez completado todo esto:

1. **Pruebas exhaustivas** con diferentes escenarios
2. **Preparar para producción**:
   - Generar keystore de release
   - Firmar APK/AAB
   - Subir a Play Store
3. **Configurar Analytics** para monitorear conversiones
4. **Implementar recuperación de compras** (si usuario desinstala)
5. **Configurar notificaciones** para recordatorios de mantenimiento

---

## 🆘 Problemas Comunes

### Authentication no funciona
- Verifica que el SHA-1 esté correcto en Firebase
- Revisa que Google Sign-In esté habilitado
- Asegúrate de estar usando `google-services.json` correcto

### Firestore deniegada
- Revisa las reglas de seguridad
- Verifica que el usuario esté autenticado
- Comprueba la estructura de datos

### Suscripciones no aparecen
- Verifica que estés en dispositivo real (no emulador)
- Asegúrate de que las suscripciones estén **activadas** en Play Console
- Comprueba que los IDs coincidan exactamente
- Revisa que tu cuenta esté como tester

---

## 📞 Contacto

Si necesitas ayuda adicional, podemos:
- Revisar logs de error específicos
- Configurar Cloud Functions
- Optimizar la estructura de Firestore
- Implementar features adicionales

**¡Vamos paso a paso! 🚀**
