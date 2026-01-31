# AutoGestión Max - Generación de Ícono

## Colores de la marca:
- **Primario**: #0088CC (Azul vibrante)
- **Secundario**: #17A2B8 (Turquesa/Cyan)
- **Acento**: #FF9500 (Naranja)

## Pasos para crear el ícono:

### Opción 1: Usar Canva (Recomendado - Fácil)
1. Ve a [Canva](https://www.canva.com/)
2. Crea un diseño personalizado de **1024 x 1024 px**
3. Diseño sugerido:
   - Fondo: Degradado de #17A2B8 (arriba izquierda) a #0088CC (abajo derecha)
   - Añadir ícono de auto (blanco) centrado
   - Borde o línea de acento en #FF9500
   - Texto "MAX" opcional en la parte inferior (blanco, opacidad 30%)
4. Exportar como PNG
5. Guardar en: `assets/images/app_icon.png`

### Opción 2: Usar Figma (Profesional)
1. Crear artboard 1024x1024
2. Aplicar gradiente lineal (#17A2B8 → #0088CC)
3. Añadir ícono vectorial de vehículo
4. Exportar como PNG @1x

### Opción 3: Usar Generador Online
1. [Icon Kitchen](https://icon.kitchen/)
   - Subir imagen o diseñar
   - Configurar colores de marca
   - Generar y descargar

2. [AppIcon.co](https://www.appicon.co/)
   - Subir imagen 1024x1024
   - Generar todos los tamaños automáticamente

### Opción 4: Modificar el ícono actual
Usa el archivo `app_icon.svg` incluido y conviértelo a PNG:
- Online: [Convertio](https://convertio.co/svg-png/)
- Desktop: Inkscape, Adobe Illustrator
- Asegurar resolución: 1024x1024px

## Después de crear el ícono:

```bash
# 1. Instalar el paquete
flutter pub add dev:flutter_launcher_icons

# 2. Generar los iconos
flutter pub run flutter_launcher_icons

# 3. Verificar
# Los iconos se generarán en:
# - android/app/src/main/res/mipmap-*/
# - ios/Runner/Assets.xcassets/AppIcon.appiconset/
# - web/icons/
# - windows/runner/resources/
```

## Diseño recomendado:

```
┌─────────────────────────┐
│                         │
│    [Degradado Azul]     │
│   #17A2B8 → #0088CC     │
│                         │
│       ┌─────┐           │
│       │ 🚗  │ (blanco)  │
│       └─────┘           │
│                         │
│      ─────────          │ ← Línea naranja #FF9500
│         MAX             │
│                         │
└─────────────────────────┘
```

## Especificaciones técnicas:
- **Tamaño**: 1024x1024px
- **Formato**: PNG
- **Fondo**: Opaco (no transparente para Android)
- **Bordes redondeados**: NO (se añaden automáticamente por plataforma)
- **Zona segura**: Dejar 10% de margen en los bordes

## Colores en diferentes formatos:
```
Primario #0088CC = RGB(0, 136, 204) = HSL(199, 100%, 40%)
Secundario #17A2B8 = RGB(23, 162, 184) = HSL(188, 78%, 41%)
Acento #FF9500 = RGB(255, 149, 0) = HSL(35, 100%, 50%)
```
