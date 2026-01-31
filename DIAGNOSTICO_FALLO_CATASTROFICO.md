# 🚨 DIAGNÓSTICO: FALLO CATASTRÓFICO QUE REINICIA LA COMPUTADORA

## PROBLEMA IDENTIFICADO

**Síntoma:** La aplicación causa un reinicio completo del sistema después de ~10 minutos de ejecución.

**Causa Principal:** ⚠️ **RAM INSUFICIENTE EN EL EMULADOR** ⚠️

### Configuración Actual del Emulador
```
hw.ramSize = 2G          ❌ MUY BAJO
hw.cpu.ncore = 4         ✅ Aceptable
hw.gpu.enabled = no      ❌ GPU DESHABILITADA
hw.gpu.mode = auto       ⚠️ Inconsistente
vm.heapSize = 228M       ❌ MUY BAJO
disk.dataPartition.size = 6GB  ✅ Suficiente
```

## 🔴 PROBLEMAS CRÍTICOS DETECTADOS

### 1. RAM Insuficiente (2GB)
- **Android 13 (API 31)** requiere **mínimo 4GB** de RAM
- **Apps con imágenes** necesitan **6-8GB** recomendado
- Tu configuración: **2GB** = Fuga de memoria inevitable

### 2. GPU Deshabilitada
```
hw.gpu.enabled = no
```
- Sin aceleración de gráficos
- Sobrecarga la CPU
- Causa sobrecalentamiento y crashes

### 3. Heap Size Muy Bajo (228MB)
- Para apps con imágenes: **mínimo 512MB**
- Recomendado: **768MB - 1GB**

### 4. Posible Fuga de Memoria en el Código
Aunque el código tiene `dispose()` implementado correctamente, hay un punto crítico:

**`LocalStorageService`** mantiene un StreamController que nunca se cierra automáticamente:
```dart
final StreamController<List<Vehicle>> _vehiclesController =
    StreamController<List<Vehicle>>.broadcast();

// ⚠️ dispose() existe pero NUNCA es llamado
void dispose() {
  _vehiclesController.close();
}
```

## ✅ SOLUCIONES

### SOLUCIÓN 1: Reconfigurar el Emulador (CRÍTICO)

#### Opción A: Editar Configuración Manual
```powershell
# 1. Detener todos los emuladores
adb kill-server

# 2. Editar el archivo de configuración
notepad "$env:USERPROFILE\.android\avd\flutter_emulator.avd\config.ini"
```

**Cambiar estas líneas:**
```ini
# ANTES
hw.ramSize = 2G
hw.gpu.enabled = no
vm.heapSize = 228M

# DESPUÉS
hw.ramSize = 6G
hw.gpu.enabled = yes
hw.gpu.mode = host
vm.heapSize = 768M
```

#### Opción B: Crear Nuevo Emulador (RECOMENDADO)
```powershell
# 1. Ver emuladores actuales
flutter emulators

# 2. Crear nuevo emulador con configuración correcta
flutter emulators --create --name autogestion_emulator

# O desde Android Studio:
# Tools > Device Manager > Create Device
# - Device: Pixel 5 o superior
# - System Image: Android 13 (API 33) o 14 (API 34)
# - RAM: 6GB (mínimo 4GB)
# - VM Heap: 768MB
# - Graphics: Hardware - GLES 2.0
```

### SOLUCIÓN 2: Arreglar Fuga de Memoria en LocalStorageService

El `StreamController` nunca se cierra porque el servicio se instancia y nunca se dispone.

**Implementación correcta:**

```dart
// Opción 1: Singleton con dispose manual
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._internal();
    return _instance!;
  }
  
  LocalStorageService._internal() {
    _loadVehicles();
  }
  
  static void disposeInstance() {
    _instance?.dispose();
    _instance = null;
  }
  
  // ... resto del código
}

// Llamar en main() al cerrar la app
@override
void dispose() {
  LocalStorageService.disposeInstance();
  super.dispose();
}
```

**O Opción 2: Cerrar automáticamente después de emitir**
```dart
Stream<List<Vehicle>> getVehicles() async* {
  if (!_isInitialized) {
    await _loadVehicles();
  }
  yield List.unmodifiable(_vehicles);
  yield* _vehiclesController.stream;
  // Cerrar después de 30 minutos de inactividad
  // Timer(Duration(minutes: 30), () => dispose());
}
```

### SOLUCIÓN 3: Optimizar Manejo de Imágenes

Aunque ya tienes compresión (85%), agregar cache cleanup:

```dart
// En MediaService, agregar límite de caché
import 'package:flutter/painting.dart';

class MediaService {
  // Limpiar caché de imágenes periódicamente
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
  
  // Llamar cada X minutos
  static void setupPeriodicCacheCleanup() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      clearImageCache();
      print('Caché de imágenes limpiado');
    });
  }
}
```

### SOLUCIÓN 4: Monitoreo de Memoria

Agregar en `main.dart`:

```dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Monitorear uso de memoria
  if (kDebugMode) {
    Timer.periodic(Duration(minutes: 1), (timer) {
      final vmStats = developer.Service.getVmStats();
      print('📊 VM Stats: $vmStats');
    });
  }

  // ... resto del código
}
```

## 🎯 PLAN DE ACCIÓN INMEDIATO

### Paso 1: Verificar RAM del Sistema
```powershell
systeminfo | findstr /C:"Total Physical Memory"
```

**Requerimientos:**
- **Computadora:** Mínimo 16GB RAM (12GB disponibles)
- **Emulador:** Asignar 6GB
- **Sistema + VS Code:** ~6GB
- **Margen:** ~2-4GB

Si tienes menos de 16GB de RAM total, considera:
- ⚠️ **Opción 1:** Usar dispositivo físico Android (recomendado)
- ⚠️ **Opción 2:** Cerrar todos los programas excepto VS Code
- ⚠️ **Opción 3:** Emulador con 3-4GB (mínimo absoluto)

### Paso 2: Reconfigurar Emulador
```powershell
# 1. Detener emulador actual
adb -s emulator-5554 emu kill

# 2. Abrir Android Device Manager
# Desde VS Code: Ctrl+Shift+P > "Flutter: Launch Emulator"
# O: Android Studio > Tools > Device Manager

# 3. Editar "flutter_emulator":
#    - RAM: 6144 MB (6GB)
#    - VM Heap: 768 MB
#    - Graphics: Hardware - GLES 2.0
#    - Internal Storage: 8GB (mínimo)
```

### Paso 3: Probar con Perfil de Memoria
```powershell
# Ejecutar en modo profile para monitorear memoria
flutter run --profile

# O con DevTools
flutter run
# En DevTools: Memory > Track Memory Usage
```

### Paso 4: Si Persiste, Usar Dispositivo Real
```powershell
# Conectar teléfono Android por USB
# Habilitar "Depuración USB" en opciones de desarrollador

# Verificar dispositivo
adb devices

# Ejecutar en dispositivo
flutter run -d <device-id>
```

## 📊 VALORES RECOMENDADOS POR NIVEL

### Configuración MÍNIMA (para pruebas básicas)
```ini
hw.ramSize = 3G
hw.cpu.ncore = 4
hw.gpu.enabled = yes
hw.gpu.mode = host
vm.heapSize = 512M
```

### Configuración RECOMENDADA (desarrollo normal)
```ini
hw.ramSize = 6G
hw.cpu.ncore = 4
hw.gpu.enabled = yes
hw.gpu.mode = host
vm.heapSize = 768M
```

### Configuración ÓPTIMA (pruebas intensivas)
```ini
hw.ramSize = 8G
hw.cpu.ncore = 6
hw.gpu.enabled = yes
hw.gpu.mode = host
vm.heapSize = 1024M
```

## ⚠️ ADVERTENCIAS

### NO Hacer:
- ❌ No usar más de 50% de RAM total del sistema
- ❌ No habilitar Hyper-V y HAXM simultáneamente
- ❌ No ejecutar múltiples emuladores a la vez
- ❌ No usar emulador con antivirus en tiempo real activo

### SÍ Hacer:
- ✅ Cerrar Chrome y otras apps pesadas al usar emulador
- ✅ Usar modo Release para pruebas finales (`flutter run --release`)
- ✅ Limpiar caché regularmente (`flutter clean`)
- ✅ Actualizar Android Studio y emulator regularmente

## 🔍 COMANDOS DE DIAGNÓSTICO

### Ver Uso de Memoria en Tiempo Real
```powershell
# Mientras la app está corriendo
adb shell dumpsys meminfo com.example.autogestion_pro

# Ver procesos
adb shell top -m 10
```

### Ver Logs del Emulador
```powershell
# Logs completos
flutter run --verbose

# Solo errores críticos
adb logcat *:E
```

### Verificar GPU
```powershell
# Info del emulador
$env:USERPROFILE\.android\avd\flutter_emulator.avd\config.ini | Select-String -Pattern "gpu"
```

## 📌 RESUMEN EJECUTIVO

**Causa:** RAM insuficiente (2GB) + GPU deshabilitada  
**Impacto:** Fuga de memoria → Crash del sistema  
**Solución:** Aumentar RAM a 6GB + Habilitar GPU  
**Tiempo:** 10-15 minutos de reconfiguración  
**Alternativa:** Usar dispositivo Android físico  

---

## 🆘 SI NADA FUNCIONA

### Última Opción: Dispositivo Físico
```powershell
# Ventajas:
✅ Rendimiento real
✅ Sin consumo de RAM de PC
✅ Pruebas más confiables
✅ Sin crashes del sistema

# Desventajas:
❌ Requiere cable USB
❌ Depuración puede ser más lenta
```

### O Reducir Uso de Imágenes Temporalmente
```dart
// En development, limitar número de fotos
const int MAX_PHOTOS_DEV = 5;

if (kDebugMode && photos.length >= MAX_PHOTOS_DEV) {
  print('Límite de fotos alcanzado en modo debug');
  return;
}
```

---

**Prioridad de Soluciones:**
1. 🔴 **CRÍTICO:** Aumentar RAM del emulador (de 2GB → 6GB)
2. 🔴 **CRÍTICO:** Habilitar GPU (hw.gpu.enabled = yes)
3. 🟡 **IMPORTANTE:** Arreglar dispose() de LocalStorageService
4. 🟢 **OPCIONAL:** Optimizaciones adicionales de memoria

**Después de aplicar las soluciones 1 y 2, el problema debería desaparecer en 90% de los casos.**
