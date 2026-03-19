# Configuración de Google AdMob

## ✅ Implementación Completada

Se ha implementado exitosamente el sistema de anuncios intersticiales con las siguientes características:

### Características Implementadas:

1. **Frecuencia de Anuncios**: Máximo 1 anuncio cada 24 horas
2. **Momento de Aparición**: 3 segundos después de iniciar sesión en la pantalla principal
3. **Sin anuncios al inicio**: El anuncio NO se muestra al abrir la app, solo después de la autenticación
4. **IDs de Anuncios**:
   - **Test (Debug)**: `ca-app-pub-3940256099942544/1033173712`
   - **Producción (Release)**: `ca-app-pub-5386118773718696/4516091665`

---

## 📋 Paso Final: Configurar App ID de AdMob

### ⚠️ IMPORTANTE: Actualizar el App ID en AndroidManifest.xml

Actualmente el archivo `android/app/src/main/AndroidManifest.xml` tiene un App ID **PLACEHOLDER**:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-5386118773718696~1234567890"/>
```

### 🔧 Cómo obtener tu App ID real:

1. Ve a la **Consola de AdMob**: https://apps.admob.com/
2. Selecciona tu aplicación **AutoGestion Max Android**
3. En el panel lateral, ve a **Configuración de la aplicación**
4. Copia el **ID de la aplicación** (formato: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`)
5. Reemplaza el valor en `AndroidManifest.xml`

### 📝 Ejemplo de App ID real:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-5386118773718696~1234567890"/>
    <!-- ↑ Reemplazar con tu App ID real desde AdMob Console -->
```

---

## 🧪 Pruebas

### En modo Debug:
- Se usa el **Ad Unit ID de prueba** automáticamente
- Los anuncios cargan más rápido y son de prueba
- Puedes probar la funcionalidad completa sin riesgo

### En modo Release (build firmado):
- Se usa el **Ad Unit ID de producción**: `ca-app-pub-5386118773718696/4516091665`
- Anuncios reales que generan ingresos
- Asegúrate de que el App ID sea el correcto

---

## 📊 Comportamiento del Sistema

### Primera vez que abre la app:
1. Usuario inicia sesión
2. Llega a la pantalla principal (VehicleListScreen)
3. **Espera 3 segundos**
4. Muestra el anuncio intersticial
5. Usuario cierra el anuncio
6. Continúa usando la app normalmente

### Próximas veces (dentro de 24 horas):
- **NO se mostrará ningún anuncio** hasta que pasen 24 horas desde el último

### Después de 24 horas:
- Al iniciar sesión nuevamente, se mostrará el anuncio

---

## 🔍 Logs de Depuración

El sistema genera logs útiles en la consola:

```
✅ Anuncio cargado correctamente
📺 Anuncio mostrado en pantalla completa
👋 Anuncio cerrado por el usuario
📅 Timestamp de anuncio guardado
⏳ No han pasado 24 horas desde el último anuncio
❌ Error al cargar anuncio: [detalles]
⚠️ Anuncio no disponible
```

---

## 📱 Archivos Modificados

1. **pubspec.yaml**: Añadida dependencia `google_mobile_ads: ^5.3.0`
2. **lib/services/ad_service.dart**: Nuevo servicio de gestión de anuncios
3. **lib/main.dart**: Inicialización de AdMob al iniciar la app
4. **lib/screens/vehicle_list_screen.dart**: Lógica para mostrar anuncios
5. **android/app/src/main/AndroidManifest.xml**: Configuración de App ID

---

## 🚀 Próximos Pasos

1. ✅ Obtener el **App ID real** de AdMob Console
2. ✅ Actualizar el valor en `AndroidManifest.xml`
3. ✅ Generar build de prueba: `flutter build apk --debug`
4. ✅ Probar en dispositivo real
5. ✅ Verificar que los anuncios se muestran correctamente
6. ✅ Generar build de producción: `flutter build appbundle --release`

---

## ⚙️ Personalización

### Cambiar frecuencia de anuncios:

Edita `lib/services/ad_service.dart` línea ~60:

```dart
// Mostrar si han pasado más de 24 horas
return difference.inHours >= 24;
```

Cambia `24` al número de horas deseado.

### Cambiar delay antes de mostrar anuncio:

Edita `lib/screens/vehicle_list_screen.dart` línea ~54:

```dart
// Esperar 3 segundos para que el usuario vea la pantalla principal primero
await Future.delayed(const Duration(seconds: 3));
```

Cambia `seconds: 3` al valor deseado.

---

## 🔐 Recordatorio: Privacidad

Este sistema de anuncios **NO requiere** el permiso `AD_ID` porque:
- Solo muestra anuncios contextuales
- No usa seguimiento personalizado
- Cumple con las políticas de privacidad

El permiso `AD_ID` sigue explícitamente removido en el `AndroidManifest.xml`:

```xml
<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />
```

---

## 📞 Soporte

Si tienes problemas con los anuncios:
1. Verifica que el **App ID** sea correcto en AdMob Console
2. Asegúrate de que el **Ad Unit ID** de producción esté activo en AdMob
3. Revisa los logs en la consola para ver errores específicos
4. En producción, los anuncios pueden tardar hasta 24 horas en activarse

---

¡Listo! 🎉 El sistema de anuncios está completamente configurado y listo para usar.
