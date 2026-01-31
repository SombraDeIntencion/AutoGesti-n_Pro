# INSTRUCCIONES PARA ACTUALIZAR FIREBASE

## Fecha: 30 de enero de 2026

### CAMBIO DE PAQUETE
- **Paquete antiguo**: com.mahondev.autogestionpro
- **Paquete nuevo**: com.mahondev.autogestionmax

---

## PASOS PARA FIREBASE CONSOLE:

### 1. Acceder a Firebase Console
https://console.firebase.google.com/project/autogestion-pro

### 2. Agregar Nueva App Android

1. Ve a: **Project settings** (⚙️) → **Your apps**
2. Click en "Add app" → Selecciona **Android**
3. Completa el registro:
   ```
   Package name: com.mahondev.autogestionmax
   App nickname: AutoGestión Max
   ```

### 3. Agregar SHA-1 Certificates

**Debug SHA-1:**
```
65:19:76:4E:1A:AB:3D:48:BA:EF:09:D7:5E:25:4E:E8:E8:C4:49:C7
```

**Release SHA-1:**
```
64:3C:78:99:A2:5F:50:94:A6:AF:8C:4E:C3:4B:61:93:F9:6D:53:51
```

### 4. Descargar google-services.json

1. Después de registrar la app, descarga el nuevo `google-services.json`
2. Reemplaza el archivo en:
   ```
   android/app/google-services.json
   ```

### 5. Reconfigurar FlutterFire (OPCIONAL - solo si hay problemas)

Si necesitas regenerar firebase_options.dart:

```powershell
flutterfire configure --project=autogestion-pro --platforms=android,ios,web,windows,macos
```

---

## IMPORTANTE:

### Mantener la App Antigua (Recomendado)
- **NO ELIMINES** la app antigua `com.mahondev.autogestionpro` de Firebase
- Los usuarios existentes aún pueden tener esa versión instalada
- Firebase puede manejar múltiples apps en el mismo proyecto

### Google Play Console
- El nuevo paquete `com.mahondev.autogestionmax` es único y no tiene conflictos
- Puedes subir el nuevo AAB sin problemas

---

## VERIFICACIÓN

Después de actualizar google-services.json, ejecuta:

```powershell
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build appbundle --release
```

---

## Notas Adicionales

- El proyecto Firebase sigue siendo: `autogestion-pro`
- Solo cambia el package name de la app Android
- Las suscripciones de Google Play están configuradas para el proyecto
- Los usuarios actuales NO se verán afectados si mantienen la versión antigua
