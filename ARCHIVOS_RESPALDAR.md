# 📦 ARCHIVOS CRÍTICOS PARA RESPALDAR
## AutoGestión Pro - Keystore Backup

## 🔐 ARCHIVOS OBLIGATORIOS (CRÍTICOS)

### 1. Keystore Principal
**Ubicación:** `c:\Dev\upload-keystore.jks`
- **Tamaño:** ~2 KB
- **Descripción:** Archivo de firma para la aplicación
- **Criticidad:** 🚨 MÁXIMA - Sin este archivo NO podrás actualizar la app en Play Store

### 2. Configuración de Firma
**Ubicación:** `c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro\android\key.properties`
- **Contenido:** Contraseñas y ruta del keystore
- **Criticidad:** 🔴 ALTA - Contiene las credenciales

### 3. Documentación del Keystore
**Ubicación:** `c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro\KEYSTORE_INFO.md`
- **Contenido:** Información completa del keystore
- **Criticidad:** 🟡 MEDIA - Útil para recuperación

---

## 📋 CREDENCIALES (Copia esta información)

```
Store Password: autogestion2026
Key Password:   autogestion2026
Key Alias:      upload
Store File:     C:/Dev/upload-keystore.jks
```

**Información del Certificado:**
```
CN=AutoGestion Pro
OU=Development
O=AutoGestion
L=Ciudad
ST=Estado
C=MX
```

**Validez:** 10,000 días (hasta enero de 2053)
**Fecha de creación:** 28 de enero de 2026

---

## 🎯 CÓMO RESPALDAR (Paso a Paso)

### Método 1: ZIP Encriptado (RECOMENDADO)

1. **Crear carpeta temporal:**
   ```
   Crear: c:\Temp\keystore_backup\
   ```

2. **Copiar los 3 archivos:**
   - `c:\Dev\upload-keystore.jks`
   - `c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro\android\key.properties`
   - `c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro\KEYSTORE_INFO.md`

3. **Crear ZIP con contraseña:**
   - Usar 7-Zip: Click derecho > 7-Zip > Agregar al archivo
   - Formato: ZIP
   - Encriptación: AES-256
   - Contraseña: [Elige una contraseña fuerte]
   - Nombre: `autogestion_keystore_backup_2026-01-28.zip`

4. **Guardar en 3 ubicaciones:**
   - [ ] USB/Disco externo
   - [ ] Google Drive/OneDrive (en carpeta privada)
   - [ ] Gestor de contraseñas (adjuntar archivo)

### Método 2: PowerShell Script (Automático)

Ejecuta este script en PowerShell:

```powershell
# Crear carpeta de backup
$backupDate = Get-Date -Format "yyyy-MM-dd"
$backupPath = "c:\Backups\AutoGestion_Keystore_$backupDate"
New-Item -ItemType Directory -Force -Path $backupPath

# Copiar archivos
Copy-Item "c:\Dev\upload-keystore.jks" -Destination $backupPath
Copy-Item "c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro\android\key.properties" -Destination $backupPath
Copy-Item "c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro\KEYSTORE_INFO.md" -Destination $backupPath

# Crear archivo de credenciales
$credentials = @"
AUTOGESTION PRO - KEYSTORE CREDENTIALS
======================================
Store Password: autogestion2026
Key Password:   autogestion2026
Key Alias:      upload
Store File:     C:/Dev/upload-keystore.jks
Date: $backupDate
"@
$credentials | Out-File -FilePath "$backupPath\CREDENTIALS.txt"

Write-Host "✓ Backup creado en: $backupPath" -ForegroundColor Green
Write-Host "⚠ AHORA copia esta carpeta a USB y nube" -ForegroundColor Yellow
```

---

## 📍 UBICACIONES RECOMENDADAS

### Ubicación 1: USB/Disco Externo
```
E:\Backups\AutoGestion\keystore_2026-01-28\
  ├── upload-keystore.jks
  ├── key.properties
  ├── KEYSTORE_INFO.md
  └── CREDENTIALS.txt
```

### Ubicación 2: Nube Encriptada
```
Google Drive/OneDrive:
  /Privado/Backups/AutoGestion/
    └── autogestion_keystore_backup_2026-01-28.zip (con contraseña)
```

### Ubicación 3: Gestor de Contraseñas
- **1Password:** Documento seguro con archivos adjuntos
- **Bitwarden:** Nota segura con attachments
- **LastPass:** Secure note con archivos

---

## ✅ CHECKLIST DE VERIFICACIÓN

Después de hacer el backup, verifica:

- [ ] Los 3 archivos principales están copiados
- [ ] El archivo CREDENTIALS.txt fue creado
- [ ] El ZIP (si lo creaste) tiene contraseña
- [ ] Puedes abrir/descomprimir el ZIP correctamente
- [ ] El archivo .jks no está corrupto (verificar tamaño ~2 KB)
- [ ] Las 3 copias están en ubicaciones DIFERENTES
- [ ] Al menos una copia está OFFLINE (USB)
- [ ] Guardaste la contraseña del ZIP en lugar seguro
- [ ] Alguien más sabe dónde están los backups (opcional)

---

## 🔍 VERIFICAR INTEGRIDAD DEL KEYSTORE

Para asegurarte que el backup está OK:

```bash
# En la ubicación del backup
keytool -list -v -keystore upload-keystore.jks -storepass autogestion2026
```

Deberías ver:
- ✓ Alias: upload
- ✓ Creation date: Jan 28, 2026
- ✓ Entry type: PrivateKeyEntry
- ✓ Certificate fingerprints

---

## 🆘 RECUPERACIÓN DE EMERGENCIA

Si necesitas restaurar el keystore:

1. **Desde USB:**
   - Copia `upload-keystore.jks` a `c:\Dev\`
   - Copia `key.properties` a `android\` del proyecto

2. **Desde ZIP encriptado:**
   - Descomprime con la contraseña
   - Restaura los archivos en sus ubicaciones originales

3. **Verificar que funciona:**
   ```bash
   flutter clean
   flutter build appbundle --release
   ```

---

## 📊 RESUMEN RÁPIDO

| Archivo | Ubicación | Tamaño | Criticidad |
|---------|-----------|--------|------------|
| upload-keystore.jks | c:\Dev\ | ~2 KB | 🚨 CRÍTICO |
| key.properties | android\ | <1 KB | 🔴 ALTA |
| KEYSTORE_INFO.md | raíz proyecto | ~5 KB | 🟡 MEDIA |

**ACCIÓN REQUERIDA:** Hacer 3 copias en ubicaciones diferentes AHORA.

---

## 🔗 Enlaces Útiles

- Gestor de contraseñas: https://bitwarden.com / https://1password.com
- 7-Zip para encriptar: https://www.7-zip.org/
- Documentación de keystore: KEYSTORE_INFO.md

---

**Fecha de este documento:** 28 de enero de 2026
**Próxima revisión de backup:** [Anota fecha en 3 meses]
**Backups verificados:** [ ] Marcar cuando completes
