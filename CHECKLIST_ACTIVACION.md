# ☑️ CHECKLIST DE ACTIVACIÓN
## Firebase y Google Play - AutoGestión Pro

---

## 📋 INSTRUCCIONES

Copia este archivo y marca cada paso conforme lo completes cambiando `[ ]` por `[x]`.

---

## ⚙️ FASE 1: PREPARACIÓN (Ya Completada ✅)

- [x] Código de suscripciones implementado
- [x] Servicio de autenticación implementado
- [x] Reglas de seguridad creadas
- [x] Dependencias agregadas (firebase_auth, in_app_purchase)
- [x] `flutter pub get` ejecutado
- [x] Sin errores de compilación

---

## 🔥 FASE 2: CONFIGURACIÓN FIREBASE (15-20 minutos)

### A. Firebase Console

- [ ] 1. Ir a [Firebase Console](https://console.firebase.google.com/)
- [ ] 2. Abrir proyecto "autogestion-pro"

### B. Authentication

- [ ] 3. Ir a **Authentication** > **Sign-in method**
- [ ] 4. Clic en **Email/Password**
- [ ] 5. **Activar** ambos switches
- [ ] 6. Guardar

### C. Firestore Database

- [ ] 7. Ir a **Firestore Database**
- [ ] 8. Clic en "Crear base de datos"
- [ ] 9. Seleccionar modo: **Producción**
- [ ] 10. Ubicación: **us-central** (o tu preferencia)
- [ ] 11. Clic en "Habilitar"
- [ ] 12. Esperar a que se cree (1-2 minutos)

### D. Storage

- [ ] 13. Ir a **Storage**
- [ ] 14. Clic en "Comenzar"
- [ ] 15. Seleccionar modo: **Producción**
- [ ] 16. Ubicación: **igual que Firestore**
- [ ] 17. Clic en "Listo"

### E. Desplegar Reglas de Seguridad

**Opción A: Desde Firebase Console** (Manual)

- [ ] 18a. En Firestore > Reglas, copiar contenido de `firestore.rules`
- [ ] 19a. Pegar y publicar
- [ ] 20a. En Storage > Reglas, copiar contenido de `storage.rules`
- [ ] 21a. Pegar y publicar

**Opción B: Desde Terminal** (Recomendado)

```powershell
# Si no tienes Firebase CLI:
npm install -g firebase-tools

# Iniciar sesión
firebase login

# En el directorio del proyecto:
cd c:\Dev\FlutterProjects\autogestion_max

# Inicializar (solo primera vez)
firebase init
# Selecciona: Firestore y Storage
# Usa archivos: firestore.rules y storage.rules

# Desplegar reglas
firebase deploy --only firestore:rules,storage:rules
```

- [ ] 18b. Instalar Firebase CLI
- [ ] 19b. `firebase login`
- [ ] 20b. `firebase init` (Firestore + Storage)
- [ ] 21b. `firebase deploy --only firestore:rules,storage:rules`
- [ ] 22b. Verificar que dice "Deploy complete!"

### F. Verificación Firebase

- [ ] 23. En Firestore > Reglas, ver que las reglas están actualizadas
- [ ] 24. En Storage > Reglas, ver que las reglas están actualizadas
- [ ] 25. En Authentication, ver que Email/Password está habilitado

---

## 🎮 FASE 3: CONFIGURACIÓN GOOGLE PLAY (10-15 minutos)

### A. Acceso a Play Console

- [ ] 26. Ir a [Google Play Console](https://play.google.com/console)
- [ ] 27. Seleccionar/Crear app "AutoGestión Pro"

### B. Crear Suscripción: Basic

- [ ] 28. Ir a **Monetización** > **Productos** > **Suscripciones**
- [ ] 29. Clic en "Crear suscripción"

**Datos de Basic:**
```
ID del producto: basic_monthly
Nombre: Plan Basic Mensual
Descripción: Gestiona hasta 5 vehículos con sincronización en la nube
```

- [ ] 30. Ingresar ID: `basic_monthly`
- [ ] 31. Ingresar nombre y descripción
- [ ] 32. Precio base: **USD $9.99**
- [ ] 33. Período de renovación: **1 mes**
- [ ] 34. Período de prueba: **7 días** (opcional)
- [ ] 35. Guardar y activar

### C. Crear Suscripción: Pro

**Datos de Pro:**
```
ID del producto: pro_monthly
Nombre: Plan Pro Mensual
Descripción: Gestiona hasta 20 vehículos con reportes avanzados
```

- [ ] 36. Repetir pasos 29-35
- [ ] 37. ID: `pro_monthly`
- [ ] 38. Precio: **USD $24.99**
- [ ] 39. Período: **1 mes**
- [ ] 40. Guardar y activar

### D. Crear Suscripción: Enterprise

**Datos de Enterprise:**
```
ID del producto: enterprise_monthly
Nombre: Plan Enterprise Mensual
Descripción: Vehículos ilimitados con soporte dedicado
```

- [ ] 41. Repetir pasos 29-35
- [ ] 42. ID: `enterprise_monthly`
- [ ] 43. Precio: **USD $99.99**
- [ ] 44. Período: **1 mes**
- [ ] 45. Guardar y activar

### E. Configurar Testing

- [ ] 46. Ir a **Configuración** > **Licencia**
- [ ] 47. En "Cuentas de prueba de licencia", agregar emails:
  ```
  tu-email@gmail.com
  otro-tester@gmail.com
  ```
- [ ] 48. Guardar

### F. Verificar Precios

- [ ] 49. Revisar que las 3 suscripciones tengan estado **Activo**
- [ ] 50. Verificar que los IDs sean exactamente:
  - `basic_monthly`
  - `pro_monthly`
  - `enterprise_monthly`

---

## 🧪 FASE 4: TESTING (10-15 minutos)

### A. Compilar App

```powershell
cd c:\Dev\FlutterProjects\autogestion_max

# Para testing en emulador (sin pagos reales)
flutter run

# Para testing en dispositivo real (con pagos)
flutter build apk --release
```

- [ ] 51. Compilar app sin errores
- [ ] 52. Instalar en dispositivo

### B. Test: Autenticación

- [ ] 53. Abrir app
- [ ] 54. Crear cuenta nueva con email/contraseña
- [ ] 55. Verificar en Firebase Console > Authentication que aparece el usuario
- [ ] 56. Cerrar sesión
- [ ] 57. Iniciar sesión con la misma cuenta

### C. Test: Firestore

- [ ] 58. Agregar un vehículo en la app
- [ ] 59. Ir a Firebase Console > Firestore Database
- [ ] 60. Verificar que existe: `users/{tu-userId}/vehicles/{vehicleId}`
- [ ] 61. Ver que los datos del vehículo están correctos

### D. Test: Storage

- [ ] 62. En la app, agregar foto a un vehículo
- [ ] 63. Ir a Firebase Console > Storage
- [ ] 64. Verificar que existe: `users/{userId}/vehicles/{vehicleId}/...`
- [ ] 65. Ver que la imagen se subió correctamente

### E. Test: Suscripciones (Solo con dispositivo real)

- [ ] 66. En la app, ir a "Planes y Precios"
- [ ] 67. Seleccionar plan "Basic"
- [ ] 68. Confirmar compra
- [ ] 69. Completar pago en Play Store (sin cargo si eres tester)
- [ ] 70. Verificar mensaje de "Suscripción Activada"
- [ ] 71. En Firebase > Firestore, verificar que `subscriptionTier` = "basic"
- [ ] 72. Verificar que `maxVehicles` = 5

### F. Test: Límite de Vehículos

- [ ] 73. Intentar agregar un 2do vehículo (si estás en Free)
- [ ] 74. Verificar que muestra "Límite alcanzado" o banner de upgrade
- [ ] 75. Después de suscripción, poder agregar más vehículos

---

## 📊 FASE 5: VERIFICACIÓN FINAL

### A. Dashboard Firebase

- [ ] 76. En Firestore, ver que hay documentos de usuarios
- [ ] 77. En Storage, ver que hay archivos subidos
- [ ] 78. En Authentication, ver usuarios registrados

### B. Dashboard Play Console

- [ ] 79. Ver que las 3 suscripciones están activas
- [ ] 80. (Opcional) Ver si hay compras de prueba registradas

### C. Funcionalidad Completa

- [ ] 81. ✅ Usuarios pueden registrarse
- [ ] 82. ✅ Usuarios pueden iniciar sesión
- [ ] 83. ✅ Vehículos se guardan en Firestore
- [ ] 84. ✅ Imágenes se suben a Storage
- [ ] 85. ✅ Planes y precios se muestran correctamente
- [ ] 86. ✅ Compra de suscripción funciona
- [ ] 87. ✅ Límites de vehículos se respetan

---

## 🎉 FASE 6: PRODUCCIÓN

### A. Preparar para Lanzamiento

- [ ] 88. Actualizar textos de marketing si es necesario
- [ ] 89. Crear capturas de pantalla para Play Store
- [ ] 90. Preparar descripción de la app
- [ ] 91. Configurar política de privacidad

### B. Compilar Release Final

```powershell
# Generar app bundle para Play Store
flutter build appbundle --release
```

- [ ] 92. Ejecutar comando de compilación
- [ ] 93. Archivo generado en: `build/app/outputs/bundle/release/app-release.aab`

### C. Subir a Play Console

- [ ] 94. Ir a Play Console > **Prueba** > **Prueba cerrada**
- [ ] 95. Crear nueva versión
- [ ] 96. Subir `app-release.aab`
- [ ] 97. Completar formulario de lanzamiento
- [ ] 98. Enviar para revisión

---

## ✅ COMPLETADO

Una vez que todos los checkboxes estén marcados:

- ✅ Firebase configurado y funcionando
- ✅ Google Play con suscripciones activas
- ✅ App probada y validada
- ✅ Lista para generar ingresos

### Próximos Pasos

- [ ] 99. Promocionar la app
- [ ] 100. Monitorear métricas en Firebase Analytics
- [ ] 101. Responder feedback de usuarios
- [ ] 102. Iterar y mejorar

---

## 📞 SI NECESITAS AYUDA

### Problemas Comunes

**"Permission denied" en Firestore**
→ Verifica que desplegaste las reglas correctamente

**"Product not found"**
→ Espera 2-4 horas después de crear productos en Play Console

**"No se sincronizan los datos"**
→ Verifica conexión a internet y que el usuario esté autenticado

### Recursos

- Documentación completa: `CONFIGURACION_COMPLETA_FIREBASE_PLAY.md`
- Inicio rápido: `INICIO_RAPIDO_FIREBASE.md`
- Resumen: `IMPLEMENTACION_COMPLETADA.md`

---

## 🎯 RESUMEN DE PROGRESO

### Total de Pasos: 102

- Fase 1 (Preparación): 6/6 ✅
- Fase 2 (Firebase): 0/25
- Fase 3 (Google Play): 0/25
- Fase 4 (Testing): 0/20
- Fase 5 (Verificación): 0/12
- Fase 6 (Producción): 0/14

### Tiempo Estimado Total: 50-70 minutos

---

**¡Mucho éxito con tu lanzamiento! 🚀**
