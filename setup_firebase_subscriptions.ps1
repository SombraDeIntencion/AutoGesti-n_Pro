# Script de Inicialización para Firebase y Suscripciones
# AutoGestión Pro

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AutoGestión Pro - Setup" -ForegroundColor Cyan
Write-Host "  Firebase & Suscripciones" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Paso 1: Verificar Flutter
Write-Host "1. Verificando Flutter..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter no está instalado o no está en el PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Flutter OK" -ForegroundColor Green
Write-Host ""

# Paso 2: Limpiar proyecto
Write-Host "2. Limpiando proyecto..." -ForegroundColor Yellow
flutter clean
Write-Host "✓ Limpieza completada" -ForegroundColor Green
Write-Host ""

# Paso 3: Obtener dependencias
Write-Host "3. Instalando dependencias..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: No se pudieron instalar las dependencias" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencias instaladas" -ForegroundColor Green
Write-Host ""

# Paso 4: Verificar archivo google-services.json
Write-Host "4. Verificando configuración de Firebase..." -ForegroundColor Yellow
$googleServicesPath = "android\app\google-services.json"
if (Test-Path $googleServicesPath) {
    Write-Host "✓ google-services.json encontrado" -ForegroundColor Green
} else {
    Write-Host "⚠ ADVERTENCIA: google-services.json NO encontrado" -ForegroundColor Yellow
    Write-Host "  Descárgalo desde Firebase Console y colócalo en:" -ForegroundColor Yellow
    Write-Host "  $googleServicesPath" -ForegroundColor Yellow
}
Write-Host ""

# Paso 5: Verificar archivo firebase_options.dart
Write-Host "5. Verificando firebase_options.dart..." -ForegroundColor Yellow
$firebaseOptionsPath = "lib\firebase_options.dart"
if (Test-Path $firebaseOptionsPath) {
    Write-Host "✓ firebase_options.dart encontrado" -ForegroundColor Green
} else {
    Write-Host "✗ ERROR: firebase_options.dart NO encontrado" -ForegroundColor Red
    Write-Host "  Ejecuta: flutterfire configure" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Paso 6: Verificar archivos de reglas
Write-Host "6. Verificando reglas de seguridad..." -ForegroundColor Yellow
$firestoreRulesPath = "firestore.rules"
$storageRulesPath = "storage.rules"

if (Test-Path $firestoreRulesPath) {
    Write-Host "✓ firestore.rules encontrado" -ForegroundColor Green
} else {
    Write-Host "✗ ERROR: firestore.rules NO encontrado" -ForegroundColor Red
}

if (Test-Path $storageRulesPath) {
    Write-Host "✓ storage.rules encontrado" -ForegroundColor Green
} else {
    Write-Host "✗ ERROR: storage.rules NO encontrado" -ForegroundColor Red
}
Write-Host ""

# Paso 7: Información de Firebase CLI (opcional)
Write-Host "7. Verificando Firebase CLI (opcional)..." -ForegroundColor Yellow
$firebaseCli = Get-Command firebase -ErrorAction SilentlyContinue
if ($firebaseCli) {
    Write-Host "✓ Firebase CLI instalado" -ForegroundColor Green
    Write-Host "  Para desplegar reglas:" -ForegroundColor Cyan
    Write-Host "  firebase deploy --only firestore:rules,storage:rules" -ForegroundColor Cyan
} else {
    Write-Host "⚠ Firebase CLI no instalado" -ForegroundColor Yellow
    Write-Host "  Para instalarlo:" -ForegroundColor Cyan
    Write-Host "  npm install -g firebase-tools" -ForegroundColor Cyan
}
Write-Host ""

# Paso 8: Resumen de dependencias agregadas
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Dependencias Instaladas:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ firebase_core: ^3.8.1" -ForegroundColor Green
Write-Host "✓ firebase_storage: ^12.3.8" -ForegroundColor Green
Write-Host "✓ cloud_firestore: ^5.5.2" -ForegroundColor Green
Write-Host "✓ firebase_auth: ^5.3.4" -ForegroundColor Green
Write-Host "✓ in_app_purchase: ^3.2.0" -ForegroundColor Green
Write-Host ""

# Paso 9: Próximos pasos
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Próximos Pasos:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Configura Firebase Console:" -ForegroundColor White
Write-Host "   - Habilita Authentication (Email/Password)" -ForegroundColor Gray
Write-Host "   - Habilita Firestore Database" -ForegroundColor Gray
Write-Host "   - Habilita Storage" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Despliega reglas de seguridad:" -ForegroundColor White
Write-Host "   firebase deploy --only firestore:rules,storage:rules" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Configura suscripciones en Google Play Console:" -ForegroundColor White
Write-Host "   - Crea productos: basic_monthly, pro_monthly, enterprise_monthly" -ForegroundColor Gray
Write-Host "   - Configura precios: `$9.99, `$24.99, `$99.99" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Consulta la guía completa:" -ForegroundColor White
Write-Host "   CONFIGURACION_COMPLETA_FIREBASE_PLAY.md" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✓ Setup Completado" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Preguntar si desea ejecutar la app
$runApp = Read-Host "¿Deseas ejecutar la app ahora? (s/n)"
if ($runApp -eq "s" -or $runApp -eq "S") {
    Write-Host ""
    Write-Host "Ejecutando app..." -ForegroundColor Cyan
    flutter run
}
