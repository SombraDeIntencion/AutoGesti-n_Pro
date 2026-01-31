# Configurar Ícono del Launcher

## Pasos para configurar el ícono:

### 1. Guardar la imagen
1. Guarda la imagen del ícono que te proporcioné como `icon.png`
2. Colócala en la carpeta: `assets/images/icon.png`
3. Asegúrate de que sea un archivo PNG de alta resolución (mínimo 1024x1024 px, idealmente)

### 2. Instalar dependencias
```powershell
flutter pub get
```

### 3. Generar los íconos
```powershell
flutter pub run flutter_launcher_icons
```

Este comando generará automáticamente todos los tamaños necesarios del ícono para:
- Android (mipmap-hdpi, mipmap-mdpi, mipmap-xhdpi, mipmap-xxhdpi, mipmap-xxxhdpi)
- iOS (si tienes configurado)

### 4. Verificar
Los íconos se generarán en:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

### 5. Reconstruir la app
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

## Configuración aplicada en pubspec.yaml

```yaml
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/images/icon.png"
  min_sdk_android: 24
  remove_alpha_ios: true
```

## Alternativa manual (si no funciona el paquete)

Si prefieres hacerlo manualmente, necesitas crear estos tamaños:
- mipmap-mdpi: 48x48 px
- mipmap-hdpi: 72x72 px
- mipmap-xhdpi: 96x96 px
- mipmap-xxhdpi: 144x144 px
- mipmap-xxxhdpi: 192x192 px

Y colocar cada tamaño en su respectiva carpeta en:
`android/app/src/main/res/mipmap-[densidad]/ic_launcher.png`
