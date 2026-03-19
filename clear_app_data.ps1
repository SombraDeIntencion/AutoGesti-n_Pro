# Script para limpiar datos de la app y reiniciar
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LIMPIAR DATOS DE AUTOGESTION MAX" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si hay dispositivo conectado
$devices = adb devices | Select-String -Pattern "device$"
if ($devices.Count -eq 0) {
    Write-Host "❌ No se encontró ningún dispositivo conectado" -ForegroundColor Red
    Write-Host "   Por favor conecta un dispositivo o inicia el emulador" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Dispositivo detectado" -ForegroundColor Green
Write-Host ""

# Paquete de la aplicación
$package = "com.mahondev.autogestionmax"

Write-Host "Limpiando datos de $package..." -ForegroundColor Yellow
Write-Host ""

# Detener la app si está corriendo
Write-Host "1. Deteniendo la aplicación..." -ForegroundColor Cyan
adb shell am force-stop $package
Start-Sleep -Seconds 1
Write-Host "   ✓ Aplicación detenida" -ForegroundColor Green

# Limpiar datos de la app
Write-Host "2. Limpiando datos de la aplicación..." -ForegroundColor Cyan
$result = adb shell pm clear $package 2>&1
Start-Sleep -Seconds 1

if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Datos limpiados" -ForegroundColor Green
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✓ DATOS LIMPIADOS EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "La aplicación ahora está en estado inicial." -ForegroundColor White
    Write-Host "Todos los datos locales han sido eliminados." -ForegroundColor White
    Write-Host ""
    Write-Host "Puedes iniciar la app nuevamente con:" -ForegroundColor Yellow
    Write-Host "  flutter run" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Error al limpiar datos: $result" -ForegroundColor Red
    exit 1
}
