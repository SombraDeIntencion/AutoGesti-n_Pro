# 🎯 Guía Completa: Configurar Suscripciones en Google Play Console
## AutoGestión Max - Sistema Freemium

---

## 📋 INFORMACIÓN DE TU APP

```
Package Name: com.mahondev.autogestionmax
App Name: AutoGestión Max
Version: 2.1.6+7
```

---

## 🚀 PASO 1: ACCEDER A GOOGLE PLAY CONSOLE

1. Ve a: [https://play.google.com/console](https://play.google.com/console)
2. Inicia sesión con tu cuenta de desarrollador de Google
3. Busca y selecciona **"AutoGestión Max"** (o tu app con package `com.mahondev.autogestionmax`)

> ⚠️ **IMPORTANTE:** Si aún no has subido tu app al Play Console, hazlo primero con el archivo `.aab` que generaste.

---

## 🏪 PASO 2: CONFIGURAR LA APP PARA COMPRAS

### 2.1. Configurar cuenta de comerciante

1. En el menú lateral, ve a: **Monetización y anuncios** > **Configuración de monetización**
2. Si no tienes una cuenta de Google Merchant Center:
   - Haz clic en **"Crear cuenta de comerciante"**
   - Completa la información:
     - Nombre de la empresa
     - Dirección
     - Información fiscal
   - Acepta los términos y condiciones
3. Vincula la cuenta de comerciante con Play Console

### 2.2. Configurar política de privacidad

1. Ve a: **Configuración** > **Información de la app** > **Tienda**
2. En **"Política de privacidad"**, agrega la URL de tu política:
   ```
   https://[tu-dominio]/privacy-policy.html
   ```
   (O usa Firebase Hosting si ya la subiste)

---

## 💳 PASO 3: CREAR LAS 5 SUSCRIPCIONES

### 📍 Ubicación en Play Console:

**Monetización y anuncios** > **Productos** > **Suscripciones** > **Crear suscripción**

---

### ✅ SUSCRIPCIÓN 1: STARTER (2-5 Vehículos)

1. **Haz clic en:** "Crear suscripción"

2. **ID del producto:** 
   ```
   starter_monthly
   ```
   > ⚠️ **CRÍTICO:** Debe ser exactamente así (minúsculas, con guion bajo)

3. **Nombre:**
   ```
   Plan Starter Mensual
   ```

4. **Descripción:**
   ```
   Plan Starter: 1 vehículo gratis + hasta 4 adicionales. Sincronización en la nube, respaldos automáticos y soporte por email.
   ```

5. **Beneficios (opcional pero recomendado):**
   - Sincronización en la nube
   - 2-5 vehículos
   - Respaldos automáticos
   - Soporte por email

6. **Período de suscripción:**
   - Selecciona: **1 mes**

7. **Precio:**
   - Haz clic en **"Agregar precio"**
   - **México (MXN):** `$700.00` (o ajusta según tu estrategia)
   - **Estados Unidos (USD):** `$40.00`
   - Haz clic en **"Aplicar precios a otros países"** (Google calcula automáticamente)

8. **Período de prueba (opcional):**
   - Si quieres ofrecer prueba gratis: `7 días`
   - De lo contrario, deja sin periodo de prueba

9. **Precio de oferta introductoria (opcional):**
   - Puedes ofrecer 50% de descuento el primer mes
   - Ejemplo: `$350 MXN` por 1 mes

10. **Guardar y activar**

---

### ✅ SUSCRIPCIÓN 2: SMALL (6-10 Vehículos)

1. **ID del producto:** 
   ```
   small_monthly
   ```

2. **Nombre:**
   ```
   Plan Small Mensual
   ```

3. **Descripción:**
   ```
   Plan Small: 1 vehículo gratis + hasta 9 adicionales. Ideal para pequeñas empresas. Incluye reportes avanzados y sincronización en la nube.
   ```

4. **Beneficios:**
   - Sincronización en la nube
   - 6-10 vehículos
   - Reportes avanzados
   - Soporte prioritario

5. **Período de suscripción:** 1 mes

6. **Precio:**
   - **México:** `$1,485.00 MXN`
   - **Estados Unidos:** `$83.00 USD`

7. **Período de prueba:** 7 días (opcional)

8. **Guardar y activar**

---

### ✅ SUSCRIPCIÓN 3: MEDIUM (11-20 Vehículos)

1. **ID del producto:** 
   ```
   medium_monthly
   ```

2. **Nombre:**
   ```
   Plan Medium Mensual
   ```

3. **Descripción:**
   ```
   Plan Medium: 1 vehículo gratis + hasta 19 adicionales. Para empresas en crecimiento. Reportes avanzados, alertas y notificaciones.
   ```

4. **Beneficios:**
   - Sincronización en la nube
   - 11-20 vehículos
   - Reportes personalizados
   - Alertas automáticas
   - Soporte prioritario

5. **Período de suscripción:** 1 mes

6. **Precio:**
   - **México:** `$2,945.00 MXN`
   - **Estados Unidos:** `$164.00 USD`

7. **Período de prueba:** 7 días (opcional)

8. **Guardar y activar**

---

### ✅ SUSCRIPCIÓN 4: LARGE (21-35 Vehículos)

1. **ID del producto:** 
   ```
   large_monthly
   ```

2. **Nombre:**
   ```
   Plan Large Mensual
   ```

3. **Descripción:**
   ```
   Plan Large: 1 vehículo gratis + hasta 34 adicionales. Para medianas empresas. Descuentos por volumen y soporte telefónico.
   ```

4. **Beneficios:**
   - Todo de Medium +
   - 21-35 vehículos
   - Descuentos por volumen
   - Soporte telefónico
   - Exportación masiva de datos

5. **Período de suscripción:** 1 mes

6. **Precio:**
   - **México:** `$4,930.00 MXN`
   - **Estados Unidos:** `$274.00 USD`

7. **Período de prueba:** 14 días (recomendado para planes grandes)

8. **Guardar y activar**

---

### ✅ SUSCRIPCIÓN 5: ENTERPRISE (36-50 Vehículos)

1. **ID del producto:** 
   ```
   enterprise_monthly
   ```

2. **Nombre:**
   ```
   Plan Enterprise Mensual
   ```

3. **Descripción:**
   ```
   Plan Enterprise: 1 vehículo gratis + hasta 49 adicionales. Para grandes flotillas. Soporte dedicado 24/7 y onboarding personalizado.
   ```

4. **Beneficios:**
   - Todo de Large +
   - 36-50 vehículos
   - Soporte dedicado 24/7
   - Onboarding personalizado
   - API personalizada
   - Account manager

5. **Período de suscripción:** 1 mes

6. **Precio:**
   - **México:** `$6,615.00 MXN`
   - **Estados Unidos:** `$368.00 USD`

7. **Período de prueba:** 14 días

8. **Guardar y activar**

---

## 🧪 PASO 4: CONFIGURAR TESTING (MUY IMPORTANTE)

### 4.1. Agregar cuentas de prueba

1. Ve a: **Configuración** > **Configuración de licencias**
2. En **"Testers de licencia"**, agrega tu email de prueba:
   ```
   gconsolereviewgeneraltest@gmail.com
   ```
3. Guarda

### 4.2. Crear una pista de prueba cerrada (Closed Testing)

1. Ve a: **Lanzamiento** > **Testing** > **Pistas de prueba cerradas**
2. Haz clic en **"Crear pista"**
3. Nombre: `Prueba de Suscripciones`
4. En **"Testers"**, crea una lista de correos:
   - Agrega los emails de prueba
5. Sube el archivo `.aab` si aún no lo has hecho
6. Envía para revisión

> 📧 Los testers recibirán un link para unirse al testing

### 4.3. Probar compras sin cargos

Los emails agregados en 4.1 podrán:
- ✅ Comprar suscripciones sin cargo real
- ✅ Probar renovaciones automáticas
- ✅ Cancelar y reactivar
- ✅ Ver todo el flujo de compra

---

## 📱 PASO 5: PROBAR EN LA APP

### 5.1. Instalar versión de prueba

1. En tu dispositivo Android, abre el email de invitación a testing
2. Acepta la invitación
3. Descarga e instala la app desde Play Store

### 5.2. Probar flujo de suscripción

1. Abre la app y navega a **"Ver Planes"**
2. Selecciona un plan (ej: Starter)
3. Haz clic en **"Suscribirme"**
4. Completa el proceso de pago (será sin cargo para testers)
5. Verifica que:
   - ✅ Se active la suscripción
   - ✅ Se actualice el límite de vehículos
   - ✅ Se muestre el plan activo en el perfil

### 5.3. Verificar en Firebase

1. Abre Firebase Console
2. Ve a Firestore Database
3. Navega a: `autogestion_max/data/users/[tu-uid]`
4. Verifica que se actualizó:
   ```
   subscriptionTier: "starter"
   maxVehicles: 5
   isSubscriptionActive: true
   ```

---

## ⚠️ PROBLEMAS COMUNES Y SOLUCIONES

### Problema 1: "Producto no encontrado"

**Solución:**
- Verifica que los IDs sean exactos (minúsculas, con guion bajo)
- Espera 2-4 horas después de crear las suscripciones
- Los productos pueden tardar en propagarse

### Problema 2: "La tienda no está disponible"

**Solución:**
- Asegúrate de estar en un dispositivo Android real (no emulador)
- Verifica que Play Store esté instalado y actualizado
- Usa una cuenta de Google válida

### Problema 3: No aparecen los precios

**Solución:**
- Verifica que las suscripciones estén **Activas** en Play Console
- Asegúrate de haber configurado precios para México y USA
- Espera propagación (2-4 horas)

### Problema 4: Error de "Licencia no válida"

**Solución:**
- Verifica que el email esté agregado como tester
- Usa el mismo email en Play Store del dispositivo
- Reinstala la app desde el link de testing

---

## 📊 PASO 6: MONITOREO Y ANÁLISIS

### 6.1. Ver suscripciones activas

1. Ve a: **Monetización y anuncios** > **Suscripciones**
2. Aquí verás:
   - Suscripciones activas
   - Ingresos mensuales
   - Tasa de renovación
   - Cancelaciones

### 6.2. Configurar notificaciones

1. Ve a: **Configuración** > **Notificaciones**
2. Activa notificaciones para:
   - Nuevas suscripciones
   - Cancelaciones
   - Problemas de pago

---

## ✅ CHECKLIST FINAL

Antes de lanzar en producción, verifica:

- [ ] Las 5 suscripciones están creadas con los IDs correctos
- [ ] Todas las suscripciones están en estado **Activo**
- [ ] Los precios están configurados (MXN y USD mínimo)
- [ ] La cuenta de Google Merchant está vinculada
- [ ] Los emails de prueba están agregados
- [ ] Has probado al menos una compra de prueba exitosa
- [ ] La suscripción se refleja en Firebase correctamente
- [ ] La app muestra el plan correcto después de comprar
- [ ] El límite de vehículos se actualiza correctamente

---

## 🚀 SIGUIENTE PASO: PRODUCCIÓN

Una vez que todo funcione en testing:

1. Ve a: **Lanzamiento** > **Producción**
2. Sube el mismo archivo `.aab`
3. Completa todos los requisitos:
   - Contenido de la app (capturas, descripción)
   - Clasificación de contenido
   - Países de distribución
   - Política de privacidad
4. Envía para revisión
5. Espera aprobación (2-7 días)

---

## 📞 SOPORTE

Si tienes problemas:

1. **Documentación oficial:** [Google Play Billing](https://developer.android.com/google/play/billing)
2. **Soporte de Play Console:** [https://support.google.com/googleplay](https://support.google.com/googleplay)
3. **Logs de la app:** Revisa los logs en `subscription_service.dart`

---

## 🎉 ¡LISTO!

Una vez configurado, tu app tendrá un sistema completo de suscripciones freemium funcionando con Google Play Billing.

**Fecha de configuración:** 31 de Enero, 2026  
**Package:** com.mahondev.autogestionmax  
**Versión:** 2.1.6+7
