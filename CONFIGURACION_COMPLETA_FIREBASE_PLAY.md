# 🚀 Guía Completa de Configuración Firebase y Google Play
## AutoGestión Pro - Configuración de Guardado en Línea y Suscripciones

---

## 📋 ÍNDICE

1. [Configuración de Firebase](#1-configuración-de-firebase)
2. [Configuración de Google Play Console](#2-configuración-de-google-play-console)
3. [Configuración de Suscripciones](#3-configuración-de-suscripciones)
4. [Despliegue de Reglas de Seguridad](#4-despliegue-de-reglas-de-seguridad)
5. [Pruebas](#5-pruebas)
6. [Precios Acordados](#6-precios-acordados)

---

## 1. Configuración de Firebase

### 1.1 Crear Proyecto Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Clic en "Agregar proyecto"
3. **Nombre del proyecto**: `autogestion-pro` (ya existe según firebase_options.dart)
4. Continúa con la configuración

### 1.2 Habilitar Servicios Necesarios

#### A. Firestore Database

1. En Firebase Console, ve a **Firestore Database**
2. Clic en "Crear base de datos"
3. Selecciona "Iniciar en modo de prueba" (luego aplicaremos reglas)
4. Ubicación: `us-central` (o la que prefieras)
5. Clic en "Habilitar"

#### B. Storage

1. Ve a **Storage** en Firebase Console
2. Clic en "Comenzar"
3. Acepta las reglas predeterminadas
4. Ubicación: la misma que Firestore
5. Clic en "Listo"

#### C. Authentication

1. Ve a **Authentication** en Firebase Console
2. Clic en "Comenzar"
3. En la pestaña "Sign-in method", habilita:
   - ✅ **Correo electrónico/contraseña**
4. Guarda los cambios

### 1.3 Descargar Archivos de Configuración

#### Para Android:

Ya tienes `google-services.json` en `android/app/`

Si necesitas actualizarlo:
1. Ve a **Configuración del proyecto** (ícono de engranaje)
2. Selecciona tu app Android
3. Descarga `google-services.json`
4. Reemplaza el archivo en `android/app/google-services.json`

#### Verificar Package Name:

En `android/app/build.gradle.kts`, verifica que coincida:
```kotlin
applicationId = "com.example.autogestion_pro"
```

---

## 2. Configuración de Google Play Console

### 2.1 Crear Aplicación en Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Crea nueva aplicación o selecciona existente
3. **Nombre**: AutoGestión Pro
4. **Categoría**: Productividad
5. **Tipo**: Aplicación

### 2.2 Vincular Firebase con Play Console

1. En Firebase Console, ve a **Configuración del proyecto**
2. En la pestaña "Integraciones"
3. Busca "Google Play"
4. Clic en "Vincular" y sigue los pasos

---

## 3. Configuración de Suscripciones

### 3.1 Crear Productos de Suscripción en Play Console

1. En Play Console, ve a **Monetización** > **Productos** > **Suscripciones**
2. Clic en "Crear suscripción"

#### Suscripción 1: Basic Monthly

```
ID del producto: basic_monthly
Nombre: Plan Basic Mensual
Descripción: Gestión de hasta 5 vehículos con sincronización en la nube

Precio base: USD $9.99
Período: 1 mes
Período de prueba: 7 días gratis (opcional)
```

#### Suscripción 2: Pro Monthly

```
ID del producto: pro_monthly
Nombre: Plan Pro Mensual
Descripción: Gestión de hasta 20 vehículos con reportes avanzados

Precio base: USD $24.99
Período: 1 mes
Período de prueba: 7 días gratis (opcional)
```

#### Suscripción 3: Enterprise Monthly

```
ID del producto: enterprise_monthly
Nombre: Plan Enterprise Mensual
Descripción: Vehículos ilimitados con soporte dedicado

Precio base: USD $99.99
Período: 1 mes
Sin período de prueba
```

### 3.2 Configurar Precios por País

Para cada suscripción, configura precios localizados:

| País    | Basic    | Pro      | Enterprise |
|---------|----------|----------|------------|
| 🇺🇸 USA  | $9.99   | $24.99   | $99.99     |
| 🇲🇽 MX   | $199 MXN| $499 MXN | $1,999 MXN |
| 🇪🇸 ES   | €8.99   | €21.99   | €89.99     |

### 3.3 Activar Licencia de Testing

1. En Play Console, ve a **Configuración** > **Licencia**
2. En "Cuentas de prueba", agrega emails de prueba:
   ```
   tu-email@example.com
   ```
3. Los testers podrán comprar sin cargos reales

### 3.4 Configurar Notificaciones en Tiempo Real

1. En Play Console, ve a **Monetización** > **Configuración de monetización**
2. En "Notificaciones en tiempo real", habilítalo
3. Copia la URL del tema de Pub/Sub

**Para Cloud Functions (opcional, configuración avanzada):**
```javascript
// Crear función en Firebase Functions para validar compras
exports.validatePurchase = functions.pubsub
  .topic('play-subscriptions')
  .onPublish(async (message) => {
    // Validar y actualizar estado de suscripción
  });
```

---

## 4. Despliegue de Reglas de Seguridad

### 4.1 Instalar Firebase CLI

```powershell
npm install -g firebase-tools
```

### 4.2 Iniciar Sesión

```powershell
firebase login
```

### 4.3 Inicializar Firebase en el Proyecto

```powershell
cd c:\Dev\FlutterProjects\autogestion_max

firebase init
```

Selecciona:
- ✅ Firestore
- ✅ Storage

Cuando pregunte por archivos de reglas, usa:
- Firestore rules: `firestore.rules`
- Storage rules: `storage.rules`

### 4.4 Desplegar Reglas

```powershell
# Desplegar solo Firestore
firebase deploy --only firestore:rules

# Desplegar solo Storage
firebase deploy --only storage:rules

# Desplegar ambos
firebase deploy --only firestore:rules,storage:rules
```

### 4.5 Verificar Reglas en Console

1. Ve a **Firestore Database** > **Reglas**
2. Verifica que se vean las reglas actualizadas
3. Haz lo mismo para **Storage** > **Reglas**

---

## 5. Pruebas

### 5.1 Probar Autenticación

```powershell
flutter run
```

1. Crear cuenta con email y contraseña
2. Verificar que aparece en Firebase Console > Authentication

### 5.2 Probar Firestore

1. Agregar un vehículo en la app
2. Verificar en Firebase Console > Firestore Database
3. Debería aparecer en: `users/{userId}/vehicles/{vehicleId}`

### 5.3 Probar Storage

1. Agregar foto a un vehículo
2. Verificar en Firebase Console > Storage
3. Debería aparecer en: `users/{userId}/vehicles/{vehicleId}/`

### 5.4 Probar Suscripciones (Modo Prueba)

1. Agregar tu email como tester en Play Console
2. Instalar APK firmado en dispositivo real
3. Ir a "Planes y Precios"
4. Seleccionar un plan
5. Completar compra (no se hará cargo real)
6. Verificar que se actualiza el tier en Firestore

#### Verificar en Firestore:

```
users/{userId}
  - subscriptionTier: "basic" | "pro" | "enterprise"
  - maxVehicles: 5 | 20 | 999999
  - isSubscriptionActive: true
  - subscriptionExpiresAt: "2026-02-28T..."
```

---

## 6. Precios Acordados

### 6.1 Estructura de Planes

| Plan       | Precio/mes | Vehículos | Características Principales              |
|------------|------------|-----------|------------------------------------------|
| Free       | $0         | 1         | Almacenamiento local, funciones básicas  |
| Basic      | $9.99      | 5         | Sincronización en la nube, backup        |
| Pro        | $24.99     | 20        | Reportes avanzados, múltiples usuarios   |
| Enterprise | $99.99     | Ilimitado | API, capacitación, gerente de cuenta     |

### 6.2 Margen de Ganancia

Google Play se queda con el **15%** de las ventas (para primeros $1M USD al año).

| Plan       | Precio | Google (15%) | Tu Ganancia (85%) |
|------------|--------|--------------|-------------------|
| Basic      | $9.99  | $1.50        | $8.49             |
| Pro        | $24.99 | $3.75        | $21.24            |
| Enterprise | $99.99 | $15.00       | $84.99            |

### 6.3 Proyección de Ingresos (Ejemplo)

Si tienes 100 suscriptores:

| Plan       | Usuarios | Ingreso Mensual | Ingreso Anual |
|------------|----------|-----------------|---------------|
| Basic      | 60       | $509.40         | $6,112.80     |
| Pro        | 35       | $743.40         | $8,920.80     |
| Enterprise | 5        | $424.95         | $5,099.40     |
| **TOTAL**  | **100**  | **$1,677.75**   | **$20,133.00** |

---

## 7. Comandos Útiles

### Instalar Dependencias

```powershell
cd c:\Dev\FlutterProjects\autogestion_max
flutter pub get
```

### Compilar para Testing

```powershell
# APK de debug (sin firma)
flutter build apk --debug

# APK de release (firmado)
flutter build apk --release

# App Bundle para Play Store
flutter build appbundle --release
```

### Ver Logs de Firebase

```powershell
# En terminal mientras ejecutas la app
flutter run --verbose
```

---

## 8. Checklist Final

### Firebase
- [ ] Proyecto creado
- [ ] Firestore habilitado
- [ ] Storage habilitado
- [ ] Authentication con Email habilitado
- [ ] Reglas de Firestore desplegadas
- [ ] Reglas de Storage desplegadas
- [ ] google-services.json actualizado

### Google Play Console
- [ ] Aplicación creada
- [ ] 3 suscripciones configuradas (basic, pro, enterprise)
- [ ] Precios configurados por país
- [ ] Emails de prueba agregados
- [ ] Vinculación con Firebase completada

### Código
- [ ] `firebase_auth` agregado a pubspec.yaml
- [ ] `in_app_purchase` agregado a pubspec.yaml
- [ ] SubscriptionService implementado
- [ ] AuthService actualizado
- [ ] SubscriptionPlansScreen integrado
- [ ] `flutter pub get` ejecutado

### Testing
- [ ] Registro de usuario funciona
- [ ] Login funciona
- [ ] Guardar vehículo en Firestore funciona
- [ ] Subir fotos a Storage funciona
- [ ] Compra de suscripción funciona (modo prueba)
- [ ] Límite de vehículos se respeta

---

## 9. Solución de Problemas

### Error: "FirebaseException: Permission denied"

**Solución**: Verifica que las reglas de Firestore/Storage estén desplegadas correctamente.

```powershell
firebase deploy --only firestore:rules,storage:rules
```

### Error: "PlatformException: BillingClient is not ready"

**Solución**: 
1. Asegúrate de estar probando en dispositivo real
2. Verifica que la app esté firmada
3. Confirma que el email está en lista de testers

### Error: "Product not found"

**Solución**:
1. Verifica que los IDs en `subscription_service.dart` coincidan con Play Console
2. Espera 2-4 horas después de crear productos (propagación)
3. Verifica que la app esté en modo de prueba cerrada/abierta

### Los vehículos no se sincronizan

**Solución**:
1. Verifica que el usuario esté autenticado
2. Revisa las reglas de Firestore
3. Verifica la conexión a internet
4. Revisa los logs: `flutter run --verbose`

---

## 10. Próximos Pasos

1. **Configurar Cloud Functions** para validar compras server-side
2. **Implementar Analytics** para trackear uso
3. **Agregar Remote Config** para cambiar precios sin actualizar app
4. **Configurar Crashlytics** para monitorear errores
5. **Implementar Push Notifications** para alertas

---

## 📞 Soporte

Si tienes problemas con la configuración:

1. Revisa la [documentación de Firebase](https://firebase.google.com/docs)
2. Consulta [documentación de Google Play Billing](https://developer.android.com/google/play/billing)
3. Verifica los logs en Firebase Console

---

## ✅ ¡Todo Listo!

Una vez completados todos los pasos, tu app AutoGestión Pro estará lista para:
- ✅ Guardar datos en la nube
- ✅ Sincronizar entre dispositivos
- ✅ Aceptar pagos por suscripciones
- ✅ Gestionar diferentes planes de usuario

**¡Felicidades! 🎉**
