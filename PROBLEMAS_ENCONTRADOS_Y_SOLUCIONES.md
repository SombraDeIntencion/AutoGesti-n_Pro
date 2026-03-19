# 🐛 Problemas Encontrados y Soluciones Implementadas

## Fecha: 31 de Enero, 2026

---

## ❌ PROBLEMAS REPORTADOS

### 1. **Vehículo guardado no se muestra**
- **Síntoma:** El contador dice "1/1" pero la lista muestra "No hay vehículos"
- **Causa:** Filtrado por `userId` - vehículos antiguos sin userId o con userId diferente
- **Severidad:** 🔴 CRÍTICA

### 2. **Permisos de cámara en primer registro**
- **Síntoma:** Error de permisos al intentar tomar foto en primer registro
- **Causa:** Permisos no solicitados correctamente antes de usar la cámara
- **Severidad:** 🔴 ALTA

### 3. **No puede cargar archivos/fotos en pestañas internas**
- **Síntoma:** Botones no funcionan o dan error
- **Causa:** Posible falta de manejo de permisos o errores silenciosos
- **Severidad:** 🔴 ALTA

### 4. **Botones de perfil "próximamente"**
- **Síntoma:** "Cambiar contraseña" y "Descargar datos" muestran "Funcionalidad próximamente"
- **Causa:** TODOs no implementados (pero las funciones sí existen)
- **Severidad:** 🟡 MEDIA

---

## ✅ SOLUCIONES APLICADAS

### Solución 1: Limpiar y corregir datos de vehículos

**Opción A - Limpieza manual (RECOMENDADO):**
```
1. En el emulador, mantén presionada la app
2. Toca "Información de la app"
3. Toca "Almacenamiento"
4. Toca "Borrar datos"
5. Abre la app y registra el vehículo nuevamente
```

**Opción B - Script de corrección (si tienes muchos vehículos):**
He agregado logs de depuración para identificar el problema exacto:
- Ver userId de cada vehículo guardado
- Ver userId del usuario actual
- Ver qué vehículos pasan el filtro

**Logs agregados en:** `lib/services/vehicle_service.dart`

### Solución 2: Implementar solicitud de permisos

**Necesita implementación:**

1. **Agregar paquete de permisos:**
```yaml
# En pubspec.yaml
dependencies:
  permission_handler: ^11.3.1
```

2. **Solicitar permisos antes de usar cámara:**
```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> _requestCameraPermission() async {
  final status = await Permission.camera.request();
  return status.isGranted;
}

Future<bool> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.photos.request();
    return status.isGranted;
  }
  return true;
}
```

3. **Usar antes de tomar foto:**
```dart
Future<void> _takePhoto() async {
  final hasPermission = await _requestCameraPermission();
  if (!hasPermission) {
    // Mostrar diálogo explicando por qué necesita el permiso
    return;
  }
  // Continuar con la cámara...
}
```

### Solución 3: Completar funciones del perfil

**Cambiar contraseña - Ya implementado:**
- Función `changePassword()` existe en `auth_service.dart`
- Solo necesita conectarse desde `profile_screen.dart`

**Descargar datos - Necesita implementación:**
- Exportar vehículos a JSON
- Exportar fotos en ZIP
- Compartir archivo

---

## 🛠️ ACCIONES INMEDIATAS

### PASO 1: Limpiar datos del emulador
```bash
# Opción manual (más simple):
# 1. Configuración > Apps > AutoGestión Max > Almacenamiento > Borrar datos

# Opción por comandos:
adb shell pm clear com.mahondev.autogestionmax
```

### PASO 2: Agregar paquete de permisos
```bash
flutter pub add permission_handler
flutter pub get
```

### PASO 3: Actualizar AndroidManifest.xml
Ya tiene los permisos necesarios ✅:
- ✅ CAMERA
- ✅ READ_MEDIA_IMAGES (Android 13+)
- ✅ READ_EXTERNAL_STORAGE
- ✅ WRITE_EXTERNAL_STORAGE

### PASO 4: Implementar solicitud de permisos

Archivos a modificar:
1. `lib/screens/vehicle_form_screen.dart`
2. `lib/widgets/document_section_tab.dart`
3. `lib/widgets/driver_section_tab.dart`
4. `lib/widgets/maintenance_section_tab.dart`

### PASO 5: Conectar funciones del perfil

Modificar `lib/screens/profile_screen.dart`:
- Conectar "Cambiar contraseña" con función existente
- Implementar "Descargar datos"

---

## 📋 CHECKLIST DE CORRECCIONES

### Críticas (Hacer YA):
- [ ] Limpiar datos del emulador
- [ ] Agregar `permission_handler`
- [ ] Implementar solicitud de permisos en `vehicle_form_screen.dart`
- [ ] Probar registro de vehículo con foto

### Alta prioridad:
- [ ] Implementar permisos en pestañas internas
- [ ] Conectar "Cambiar contraseña" en perfil
- [ ] Agregar manejo de errores visible al usuario

### Media prioridad:
- [ ] Implementar "Descargar datos"
- [ ] Mejorar mensajes de error
- [ ] Agregar diálogos explicativos de permisos

---

## 🧪 PRUEBAS DESPUÉS DE CORRECCIONES

### Test 1: Registro de vehículo
1. Limpiar datos de la app
2. Iniciar sesión
3. Agregar vehículo con foto
4. Verificar que solicita permiso de cámara
5. Verificar que la foto se guarda
6. Verificar que el vehículo aparece en la lista

### Test 2: Carga de documentos
1. Abrir un vehículo
2. Ir a pestaña "Seguro"
3. Intentar agregar foto
4. Verificar permiso
5. Verificar que se guarda

### Test 3: Funciones de perfil
1. Abrir perfil
2. Probar "Cambiar contraseña"
3. Verificar que funciona
4. Probar "Descargar datos"
5. Verificar exportación

---

## 📞 NOTAS IMPORTANTES

### Sobre userId de vehículos:
Los vehículos guardados ANTES de las correcciones no tienen userId correcto.
**Solución:** Borrar datos y empezar fresco.

### Sobre permisos en Android 13+:
Android 13+ requiere permisos granulares:
- `READ_MEDIA_IMAGES` para fotos
- `READ_MEDIA_VIDEO` para videos
- `CAMERA` para tomar fotos

Ya están declarados en AndroidManifest.xml ✅

### Sobre testing:
Después de cada corrección, probar en:
1. Emulador (Android 13+)
2. Dispositivo real (si es posible)
3. Con datos limpios (fresh install)

---

## 🚀 SIGUIENTE PASO

**AHORA MISMO:**
1. Limpia los datos del emulador
2. Agrega `permission_handler`
3. Implementa solicitud de permisos
4. Prueba todo el flujo

¿Listo para empezar?
