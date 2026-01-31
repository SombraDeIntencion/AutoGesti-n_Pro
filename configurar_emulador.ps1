# Script para reconfigurar el emulador Android con valores óptimos
# Este script ayuda a prevenir el fallo catastrófico por falta de memoria

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Configurador de Emulador Android - AutoGestión Pro      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar memoria total del sistema
Write-Host "📊 Verificando memoria del sistema..." -ForegroundColor Yellow
$totalRAM = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
$totalRAMGB = [math]::Round($totalRAM / 1GB, 2)
Write-Host "   RAM Total: $totalRAMGB GB" -ForegroundColor Green

# Recomendaciones basadas en RAM
if ($totalRAMGB -lt 8) {
    Write-Host "   ⚠️  ADVERTENCIA: RAM insuficiente para emulador" -ForegroundColor Red
    Write-Host "   Se recomienda usar un dispositivo físico Android" -ForegroundColor Red
    $recommendedRAM = 2
} elseif ($totalRAMGB -lt 12) {
    Write-Host "   ⚠️  RAM justa: Se recomienda configuración mínima" -ForegroundColor Yellow
    $recommendedRAM = 3
} elseif ($totalRAMGB -lt 16) {
    Write-Host "   ✅ RAM adecuada: Configuración estándar recomendada" -ForegroundColor Green
    $recommendedRAM = 4
} else {
    Write-Host "   ✅ RAM excelente: Configuración óptima disponible" -ForegroundColor Green
    $recommendedRAM = 6
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Buscar emuladores existentes
$avdPath = "$env:USERPROFILE\.android\avd"
Write-Host "🔍 Buscando emuladores en: $avdPath" -ForegroundColor Yellow
Write-Host ""

if (Test-Path $avdPath) {
    $avdFolders = Get-ChildItem -Path $avdPath -Directory -Filter "*.avd"
    
    if ($avdFolders.Count -eq 0) {
        Write-Host "   ❌ No se encontraron emuladores." -ForegroundColor Red
        Write-Host "   Por favor, crea uno usando Android Studio o:" -ForegroundColor Yellow
        Write-Host "   flutter emulators --create --name autogestion_emulator" -ForegroundColor Cyan
        exit
    }
    
    Write-Host "   Emuladores encontrados:" -ForegroundColor Green
    for ($i = 0; $i -lt $avdFolders.Count; $i++) {
        $name = $avdFolders[$i].Name -replace "\.avd$", ""
        Write-Host "   [$i] $name" -ForegroundColor White
    }
    Write-Host ""
    
    # Seleccionar emulador
    if ($avdFolders.Count -eq 1) {
        $selectedIndex = 0
        Write-Host "   ✅ Usando: $($avdFolders[$selectedIndex].Name)" -ForegroundColor Green
    } else {
        $selectedIndex = Read-Host "   Selecciona el número del emulador a configurar"
        if ($selectedIndex -lt 0 -or $selectedIndex -ge $avdFolders.Count) {
            Write-Host "   ❌ Selección inválida" -ForegroundColor Red
            exit
        }
    }
    
    $selectedAVD = $avdFolders[$selectedIndex]
    $configFile = Join-Path $selectedAVD.FullName "config.ini"
    
    if (-not (Test-Path $configFile)) {
        Write-Host "   ❌ No se encontró config.ini en $($selectedAVD.Name)" -ForegroundColor Red
        exit
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    # Leer configuración actual
    Write-Host "📖 Configuración actual:" -ForegroundColor Yellow
    $config = Get-Content $configFile
    $currentRAM = ($config | Select-String "hw.ramSize" | Select-Object -First 1) -replace ".*= ", ""
    $currentGPU = ($config | Select-String "hw.gpu.enabled" | Select-Object -First 1) -replace ".*= ", ""
    $currentHeap = ($config | Select-String "vm.heapSize" | Select-Object -First 1) -replace ".*= ", ""
    
    Write-Host "   RAM: $currentRAM" -ForegroundColor $(if ($currentRAM -like "*2G*" -or $currentRAM -like "*2048*") { "Red" } else { "Green" })
    Write-Host "   GPU: $currentGPU" -ForegroundColor $(if ($currentGPU -eq "no") { "Red" } else { "Green" })
    Write-Host "   Heap: $currentHeap" -ForegroundColor $(if ([int]($currentHeap -replace "[^0-9]") -lt 500) { "Red" } else { "Green" })
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    
    # Preguntar si desea aplicar cambios
    Write-Host "🔧 Configuración recomendada:" -ForegroundColor Yellow
    Write-Host "   RAM: $($recommendedRAM)GB" -ForegroundColor Green
    Write-Host "   GPU: Habilitada (host)" -ForegroundColor Green
    Write-Host "   Heap: 768MB" -ForegroundColor Green
    Write-Host ""
    
    $confirm = Read-Host "¿Deseas aplicar esta configuración? (S/N)"
    
    if ($confirm -ne "S" -and $confirm -ne "s") {
        Write-Host "   ℹ️  Operación cancelada" -ForegroundColor Yellow
        exit
    }
    
    # Detener emulador si está corriendo
    Write-Host ""
    Write-Host "🛑 Deteniendo emuladores..." -ForegroundColor Yellow
    try {
        adb kill-server 2>$null
        Start-Sleep -Seconds 2
        Write-Host "   ✅ Emuladores detenidos" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️  No había emuladores corriendo" -ForegroundColor Yellow
    }
    
    # Hacer backup
    $backupFile = "$configFile.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $configFile $backupFile
    Write-Host "   💾 Backup creado: $(Split-Path $backupFile -Leaf)" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✏️  Aplicando cambios..." -ForegroundColor Yellow
    
    # Aplicar cambios
    $newConfig = $config | ForEach-Object {
        if ($_ -match "^hw.ramSize") {
            "hw.ramSize = $($recommendedRAM)G"
        } elseif ($_ -match "^hw.gpu.enabled") {
            "hw.gpu.enabled = yes"
        } elseif ($_ -match "^hw.gpu.mode") {
            "hw.gpu.mode = host"
        } elseif ($_ -match "^vm.heapSize") {
            "vm.heapSize = 768M"
        } else {
            $_
        }
    }
    
    # Guardar cambios
    $newConfig | Set-Content $configFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ ¡Configuración aplicada correctamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Cambios realizados:" -ForegroundColor Yellow
    Write-Host "   • RAM aumentada a $($recommendedRAM)GB" -ForegroundColor Green
    Write-Host "   • GPU habilitada" -ForegroundColor Green
    Write-Host "   • VM Heap aumentado a 768MB" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Próximos pasos:" -ForegroundColor Yellow
    Write-Host "   1. Ejecuta: flutter emulators" -ForegroundColor Cyan
    Write-Host "   2. Ejecuta: flutter emulators --launch $($selectedAVD.Name -replace '\.avd$', '')" -ForegroundColor Cyan
    Write-Host "   3. Ejecuta: flutter run" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "   • Cierra Chrome y apps pesadas antes de usar el emulador" -ForegroundColor White
    Write-Host "   • Monitorea la app durante 15-20 minutos para verificar estabilidad" -ForegroundColor White
    Write-Host "   • Si persiste el problema, considera usar un dispositivo físico" -ForegroundColor White
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    
} else {
    Write-Host "   ❌ No se encontró la carpeta de AVD: $avdPath" -ForegroundColor Red
    Write-Host "   Asegúrate de tener Android SDK instalado" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
