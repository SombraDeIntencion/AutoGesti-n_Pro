# 🔐 INFORMACIÓN CRÍTICA DEL KEYSTORE
## AutoGestión Pro - Android App Signing

### ⚠️ GUARDAR EN LUGAR SEGURO - CONFIDENCIAL

---

## Datos del Keystore

**Archivo:** `c:\Dev\upload-keystore.jks`
**Tipo:** JKS (Java KeyStore)
**Algoritmo:** RSA 2048 bits
**Validez:** 10,000 días (hasta enero de 2053)
**Fecha de creación:** 28 de enero de 2026

### Credenciales

```
Store Password: autogestion2026
Key Password:   autogestion2026
Key Alias:      upload
Store File:     C:/Dev/upload-keystore.jks
```

### Información del Certificado

```
CN=AutoGestion Pro
OU=Development
O=AutoGestion
L=Ciudad
ST=Estado
C=MX
```

---

## ⚠️ ADVERTENCIAS CRÍTICAS

### 🚨 SI PIERDES ESTE KEYSTORE:
- ❌ No podrás actualizar la aplicación en Play Store
- ❌ Tendrás que publicar una nueva app con diferente package name
- ❌ Perderás todos los usuarios y descargas existentes
- ❌ Tendrás que crear una nueva entrada en Play Store

### 🔒 SEGURIDAD:
- ✅ **NUNCA** subas este archivo a Git o repositorios públicos
- ✅ **NUNCA** compartas las contraseñas públicamente
- ✅ Guarda copias en al menos 3 lugares seguros
- ✅ Usa encriptación para almacenar las copias
- ✅ Considera usar un gestor de contraseñas

---

## 📦 Ubicaciones de Respaldo Recomendadas

### Opción 1: Almacenamiento en la Nube Encriptado
- [ ] Google Drive (carpeta privada, archivo ZIP encriptado)
- [ ] OneDrive (con cifrado adicional)
- [ ] Dropbox (con contraseña)

### Opción 2: Almacenamiento Físico
- [ ] USB encriptado (guardado en lugar seguro)
- [ ] Disco duro externo
- [ ] DVD/Blu-ray (para archivo a largo plazo)

### Opción 3: Servicios Especializados
- [ ] Gestor de contraseñas (1Password, LastPass, Bitwarden)
- [ ] Bóveda digital empresarial
- [ ] Servicio de backup automático

---

## 📋 Checklist de Respaldo

Asegúrate de tener copias en:
- [ ] Ubicación 1: _________________________
- [ ] Ubicación 2: _________________________
- [ ] Ubicación 3: _________________________
- [ ] Gestor de contraseñas con las credenciales
- [ ] Documento físico impreso (en caja fuerte)

---

## 🔄 Migración a PKCS12 (Recomendado)

El formato JKS es obsoleto. Para migrar a PKCS12:

```bash
keytool -importkeystore -srckeystore upload-keystore.jks -destkeystore upload-keystore.jks -deststoretype pkcs12
```

Después de migrar, actualiza `key.properties` si es necesario.

---

## 📝 Uso del Keystore

### Para compilar Release Build:
```bash
flutter build appbundle --release
```

### Para verificar la firma:
```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### Para ver información del keystore:
```bash
keytool -list -v -keystore c:\Dev\upload-keystore.jks -alias upload
```

---

## 🆘 En Caso de Emergencia

Si necesitas recuperar el keystore:

1. **Busca en tus respaldos** (listados arriba)
2. **Contacta a quien tenga acceso** a los respaldos
3. **NO intentes crear uno nuevo** con el mismo alias
4. **Si realmente se perdió:**
   - Contacta a Google Play Support
   - Considera usar App Signing by Google Play (para futuros lanzamientos)
   - Prepárate para crear una nueva aplicación

---

## 📧 Contactos con Acceso

| Persona | Rol | Tiene Copia | Contacto |
|---------|-----|-------------|----------|
| [Nombre 1] | Desarrollador Principal | ☑️ | [email/tel] |
| [Nombre 2] | Backup | ☐ | [email/tel] |
| [Nombre 3] | Administrador | ☐ | [email/tel] |

---

## 🔍 Verificación del Keystore

Para verificar que tu keystore está OK:

```bash
keytool -list -v -keystore c:\Dev\upload-keystore.jks -storepass autogestion2026
```

Deberías ver:
- Alias name: upload
- Creation date: Jan 28, 2026
- Entry type: PrivateKeyEntry
- Certificate fingerprints (SHA256, SHA1, MD5)

---

## 📅 Recordatorios

- [ ] Respaldar keystore: INMEDIATAMENTE
- [ ] Verificar respaldos: Cada 3 meses
- [ ] Revisar accesos: Cada 6 meses
- [ ] Renovar si es necesario: Antes de 2053

---

## 🔐 Huella Digital del Certificado

Después de crear el keystore, ejecuta:

```bash
keytool -list -v -keystore c:\Dev\upload-keystore.jks -alias upload -storepass autogestion2026
```

Guarda aquí las huellas digitales:

```
SHA256: [ejecutar comando para obtener]
SHA1:   [ejecutar comando para obtener]
MD5:    [ejecutar comando para obtener]
```

Estas huellas son necesarias para:
- Configurar Firebase
- OAuth y APIs de Google
- Servicios de terceros
- Verificación de integridad

---

## 📱 Play App Signing (Recomendación)

Para mayor seguridad, considera usar **Play App Signing** de Google:

**Ventajas:**
- ✅ Google gestiona la clave de producción
- ✅ Puedes recuperar acceso si pierdes tu upload key
- ✅ Mayor seguridad
- ✅ Actualizaciones más simples

**Cómo activarlo:**
1. Play Console > Tu App > Configuración > Integridad de la app
2. Activar Play App Signing
3. Subir tu keystore actual o crear uno nuevo

---

## ⚖️ Notas Legales

Este keystore es propiedad de [Tu Empresa/Nombre]
Uso exclusivo para la aplicación: AutoGestión Pro
Package: com.example.autogestion_pro

**Fecha de este documento:** 28 de enero de 2026
**Última actualización:** _______________
**Próxima revisión:** _______________

---

## 🎯 Acción Inmediata Requerida

**ANTES DE CONTINUAR CON LA PUBLICACIÓN:**

1. [ ] Hacer 3 copias del archivo `upload-keystore.jks`
2. [ ] Guardar este documento en lugar seguro
3. [ ] Anotar las contraseñas en gestor de contraseñas
4. [ ] Verificar que las copias funcionan
5. [ ] Imprimir este documento y guardarlo físicamente

**NO CONTINÚES** hasta completar todos los pasos anteriores.

---

**Creado el:** 28 de enero de 2026
**Por:** GitHub Copilot
**Para:** AutoGestión Pro v1.0.0
