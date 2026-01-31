# Guía para Crear el Icono de AutoGestión Pro

## Opción 1: Herramienta Online (Más Fácil)

### Usando AppIcon.co
1. Ve a https://appicon.co/
2. Sube una imagen de 1024x1024 píxeles
3. Selecciona "Android"
4. Descarga el paquete generado
5. Extrae los archivos en `android/app/src/main/res/`

### Usando Icon Kitchen (Recomendado)
1. Ve a https://icon.kitchen/
2. Sube tu logo o diseño
3. Ajusta colores y forma
4. Descarga para Android
5. Extrae en `android/app/src/main/res/`

## Opción 2: Diseñar con Figma/Canva

### Especificaciones del Icono

**Diseño Sugerido para AutoGestión Pro:**
- 🚗 Icono de vehículo estilizado
- 📋 Clipboard o checklist
- 🔧 Herramienta de mantenimiento
- Colores: Azul (#1E40AF) y Cyan (#06B6D4)

### Tamaños Requeridos

Crear las siguientes versiones:

| Carpeta | Tamaño | Archivo |
|---------|--------|---------|
| mipmap-mdpi | 48x48 | ic_launcher.png |
| mipmap-hdpi | 72x72 | ic_launcher.png |
| mipmap-xhdpi | 96x96 | ic_launcher.png |
| mipmap-xxhdpi | 144x144 | ic_launcher.png |
| mipmap-xxxhdpi | 192x192 | ic_launcher.png |

**Adicional para Play Store:**
- 512x512 píxeles (PNG, 32-bit)
- Máximo 1 MB
- Sin transparencia para Play Store

## Opción 3: Usar Flutter Launcher Icons (Automático)

### 1. Agregar dependencia

En `pubspec.yaml`, agrega:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### 2. Configurar en pubspec.yaml

Agrega al final del archivo:
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#1E40AF"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
```

### 3. Crear tu icono

1. Crea la carpeta: `assets/icon/`
2. Coloca tu icono de 1024x1024 como `icon.png`
3. (Opcional) Crea `icon_foreground.png` para adaptive icon

### 4. Generar iconos

Ejecuta en terminal:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

Esto generará automáticamente todos los tamaños.

## Opción 4: Placeholder Temporal

Si necesitas publicar rápido, puedes usar un icono temporal:

### Crear Icono Simple con Python (PIL)

```python
from PIL import Image, ImageDraw, ImageFont

def create_icon(size, filename):
    # Crear imagen con fondo azul
    img = Image.new('RGB', (size, size), '#1E40AF')
    draw = ImageDraw.Draw(img)
    
    # Dibujar círculo cyan
    margin = size // 4
    draw.ellipse([margin, margin, size-margin, size-margin], 
                 fill='#06B6D4')
    
    # Guardar
    img.save(filename, 'PNG')

# Generar todos los tamaños
sizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192
}

for dpi, size in sizes.items():
    create_icon(size, f'ic_launcher_{dpi}.png')

# Icono para Play Store
create_icon(512, 'ic_launcher_playstore.png')
```

## Diseño Recomendado

### Concepto: AutoGestión Pro

**Elementos visuales:**
```
┌─────────────────┐
│                 │
│    🚗          │  ← Vehículo (icono principal)
│   ┌──┐         │
│   │✓ │         │  ← Checklist (gestión)
│   └──┘         │
│                 │
└─────────────────┘
```

**Paleta de colores:**
- Fondo: `#1E40AF` (Azul oscuro)
- Acento: `#06B6D4` (Cyan)
- Icono: Blanco o gradient

### Plantilla SVG Simple

```svg
<svg width="512" height="512" xmlns="http://www.w3.org/2000/svg">
  <!-- Fondo -->
  <rect width="512" height="512" rx="128" fill="#1E40AF"/>
  
  <!-- Círculo cyan -->
  <circle cx="256" cy="256" r="180" fill="#06B6D4"/>
  
  <!-- Aquí añadir tu diseño -->
  <text x="256" y="280" font-size="160" text-anchor="middle" 
        fill="white" font-family="Arial">🚗</text>
</svg>
```

## Herramientas Útiles

- **Canva**: https://canva.com (templates de iconos)
- **Figma**: https://figma.com (diseño profesional)
- **GIMP**: Software gratuito de edición
- **Inkscape**: Vector graphics gratuito
- **Android Asset Studio**: https://romannurik.github.io/AndroidAssetStudio/

## Checklist Final

Antes de usar el icono:
- [ ] Tamaño correcto (ver tabla arriba)
- [ ] Formato PNG (32-bit para Play Store)
- [ ] Sin transparencia en versión Play Store
- [ ] Colores coherentes con la marca
- [ ] Reconocible a tamaños pequeños
- [ ] Probado en diferentes fondos

## Instalación Manual

Si ya tienes los iconos generados:

1. Coloca cada archivo en su carpeta correspondiente:
```
android/app/src/main/res/
  ├── mipmap-mdpi/ic_launcher.png
  ├── mipmap-hdpi/ic_launcher.png
  ├── mipmap-xhdpi/ic_launcher.png
  ├── mipmap-xxhdpi/ic_launcher.png
  └── mipmap-xxxhdpi/ic_launcher.png
```

2. El icono de 512x512 se sube directamente a Play Console

3. Verifica que `AndroidManifest.xml` tenga:
```xml
android:icon="@mipmap/ic_launcher"
```

## Próximo Paso

Una vez tengas los iconos:
1. Colócalos en las carpetas mipmap correspondientes
2. Limpia el proyecto: `flutter clean`
3. Compila para verificar: `flutter build apk --debug`
4. Verifica que el icono aparezca correctamente

---

**Nota:** Por ahora, los iconos por defecto de Flutter funcionarán. Puedes actualizarlos después de la primera publicación.
