# Script para configurar Firebase automáticamente
# Responde automáticamente a las preguntas de flutterfire configure

Write-Host "`n🔥 Configurando Firebase para AutoGestión Max..." -ForegroundColor Cyan
Write-Host "Usando proyecto existente: autogestion-pro`n" -ForegroundColor Yellow

# Navegar al proyecto
Set-Location "c:\Dev\FlutterProjects\autogestion_max"

# Crear script de respuestas automáticas
$answers = @"
n
1
y
y
n
y
n
"@

# Ejecutar flutterfire configure con respuestas automáticas
$answers | dart pub global run flutterfire_cli:flutterfire configure

Write-Host "`n✅ Configuración completada!" -ForegroundColor Green
Write-Host "`nVerificando archivos generados..." -ForegroundColor Cyan

# Verificar que se crearon los archivos
$files = @(
    "lib\firebase_options.dart",
    "android\app\google-services.json",
    "ios\Runner\GoogleService-Info.plist"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (NO ENCONTRADO)" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Firebase configurado exitosamente!" -ForegroundColor Green
Write-Host "Siguiente paso: Actualizar main.dart para usar AuthGate`n" -ForegroundColor Yellow
