# ⚡ INICIO RÁPIDO - Configuración Firebase y Suscripciones
## AutoGestión Pro

---

## 🎯 Lo Que Se Ha Implementado

### ✅ Código Listo
1. **Servicio de Autenticación** (`auth_service.dart`)
   - Registro con email/contraseña
   - Login/Logout
   - Gestión de usuarios en Firestore

2. **Servicio de Suscripciones** (`subscription_service.dart`)
   - Integración con Google Play Billing
   - 3 planes: Basic ($9.99), Pro ($24.99), Enterprise ($99.99)
   - Validación y activación automática

3. **Reglas de Seguridad**
   - Firestore: Solo usuarios autenticados pueden acceder a sus datos
   - Storage: Solo usuarios autenticados pueden subir/descargar archivos

4. **UI Actualizada**
   - Pantalla de planes mejorada con integración real
   - Indicadores de límites de vehículos

### 📦 Dependencias Agregadas
```yaml
firebase_auth: ^5.3.4
in_app_purchase: ^3.2.0
```

---

## 🚀 PASOS PARA ACTIVAR (15-20 minutos)

### Paso 1: Ejecutar Setup (2 min)
```powershell
cd c:\Dev\FlutterProjects\autogestion_max
.\setup_firebase_subscriptions.ps1
```

### Paso 2: Configurar Firebase Console (5 min)

1. **Ir a** [Firebase Console](https://console.firebase.google.com/)
2. **Proyecto**: autogestion-pro (ya existe)

#### A. Authentication
- Menú: Authentication > Sign-in method
- ✅ Habilitar **Email/Password**

#### B. Firestore Database
- Menú: Firestore Database
- Clic en "Crear base de datos"
- Modo: **Producción** (las reglas ya están listas)
- Ubicación: us-central (o tu preferencia)

#### C. Storage
- Menú: Storage
- Clic en "Comenzar"
- Modo: **Producción** (las reglas ya están listas)

### Paso 3: Desplegar Reglas de Seguridad (3 min)

```powershell
# Si no tienes Firebase CLI instalado:
npm install -g firebase-tools

# Iniciar sesión
firebase login

# Inicializar en el proyecto
firebase init

# Selecciona:
# ✅ Firestore
# ✅ Storage
# Archivos: firestore.rules y storage.rules (ya existen)

# Desplegar reglas
firebase deploy --only firestore:rules,storage:rules
```

### Paso 4: Configurar Google Play Console (10 min)

1. **Ir a** [Play Console](https://play.google.com/console)
2. **Menú**: Monetización > Productos > Suscripciones

#### Crear 3 Suscripciones:

**Suscripción 1:**
```
ID: basic_monthly
Nombre: Plan Basic Mensual
Precio: USD $9.99 / mes
Período de prueba: 7 días (opcional)
```

**Suscripción 2:**
```
ID: pro_monthly
Nombre: Plan Pro Mensual
Precio: USD $24.99 / mes
Período de prueba: 7 días (opcional)
```

**Suscripción 3:**
```
ID: enterprise_monthly
Nombre: Plan Enterprise Mensual
Precio: USD $99.99 / mes
```

#### Agregar Testers:
- Configuración > Licencia
- Agregar emails de prueba para testing sin cargos reales

---

## 🧪 PROBAR LA APP

### Opción A: Emulador (sin suscripciones reales)
```powershell
flutter run
```
- Las suscripciones mostrarán un diálogo de prueba
- Los datos se guardan localmente

### Opción B: Dispositivo Real (con Firebase activo)
```powershell
flutter build apk --release
```
- Instalar APK en dispositivo con Google Play
- Probar registro/login
- Probar guardado en Firestore
- Probar compra de suscripciones (modo prueba)

---

## 📊 ESTRUCTURA DE DATOS EN FIRESTORE

### Colección: `users`
```
users/{userId}
  - email: string
  - displayName: string
  - subscriptionTier: 'free' | 'basic' | 'pro' | 'enterprise'
  - maxVehicles: number (1, 5, 20, 999999)
  - currentVehicles: number
  - isSubscriptionActive: boolean
  - subscriptionExpiresAt: timestamp
  - createdAt: timestamp
  - lastLoginAt: timestamp
```

### Subcolección: `vehicles`
```
users/{userId}/vehicles/{vehicleId}
  - id: string
  - name: string
  - brand: string
  - model: string
  - year: number
  - licensePlate: string
  - documents: []
  - driverInfo: {}
  - maintenance: []
```

### Subcolección: `subscriptions` (registro de compras)
```
users/{userId}/subscriptions/{subscriptionId}
  - productId: string
  - purchaseId: string
  - transactionDate: timestamp
  - status: string
  - tier: string
```

---

## 🔐 REGLAS DE SEGURIDAD

### Firestore (`firestore.rules`)
- ✅ Solo usuarios autenticados pueden leer/escribir
- ✅ Cada usuario solo accede a sus propios datos
- ✅ Las suscripciones solo las escribe el servidor

### Storage (`storage.rules`)
- ✅ Solo usuarios autenticados pueden subir archivos
- ✅ Límite: 10MB por archivo
- ✅ Tipos permitidos: imágenes y PDFs
- ✅ Solo el propietario puede leer/escribir/eliminar

---

## 💰 PRECIOS Y PLANES

| Plan       | Precio/mes | Vehículos | Características Clave               |
|------------|------------|-----------|-------------------------------------|
| Free       | $0         | 1         | Almacenamiento local                |
| Basic      | $9.99      | 5         | Nube, backup automático             |
| Pro        | $24.99     | 20        | Reportes, múltiples usuarios        |
| Enterprise | $99.99     | Ilimitado | API, soporte dedicado               |

**Comisión Google Play**: 15% (primeros $1M al año)

**Ganancia Neta**:
- Basic: $8.49/mes
- Pro: $21.24/mes
- Enterprise: $84.99/mes

---

## 🐛 TROUBLESHOOTING

### "Permission denied" en Firestore
```powershell
# Verificar que las reglas estén desplegadas
firebase deploy --only firestore:rules
```

### "Product not found" en suscripciones
- Espera 2-4 horas después de crear productos en Play Console
- Verifica que los IDs coincidan exactamente
- Asegúrate que la app esté en modo prueba cerrada/abierta

### Los vehículos no se sincronizan
1. Verifica que el usuario esté autenticado
2. Revisa que Firebase esté inicializado
3. Comprueba la conexión a internet

---

## 📚 DOCUMENTACIÓN COMPLETA

Para más detalles, consulta:
- **CONFIGURACION_COMPLETA_FIREBASE_PLAY.md** - Guía paso a paso completa
- **GUIA_PLAY_STORE.md** - Publicación en Play Store
- **PROJECT_SUMMARY.md** - Resumen del proyecto

---

## ✅ CHECKLIST PRE-LANZAMIENTO

### Firebase
- [ ] Authentication habilitado
- [ ] Firestore creado
- [ ] Storage habilitado
- [ ] Reglas desplegadas

### Google Play
- [ ] 3 suscripciones creadas
- [ ] Precios configurados
- [ ] Testers agregados

### Código
- [ ] `flutter pub get` ejecutado
- [ ] Sin errores de compilación
- [ ] Probado en dispositivo real

### Testing
- [ ] Registro funciona
- [ ] Login funciona
- [ ] Guardado en Firestore funciona
- [ ] Compra de suscripción funciona

---

## 🎉 ¡LISTO PARA PRODUCCIÓN!

Una vez completados todos los pasos, tu app tendrá:
- ✅ Sincronización en la nube
- ✅ Sistema de autenticación seguro
- ✅ Suscripciones con pagos reales
- ✅ Límites por plan aplicados
- ✅ Backup automático de datos

**¡Felicidades! Tu app está lista para generar ingresos.** 💰
