# Ajustar Tamaño del Ícono

## Problema
El auto y engranaje dentro del círculo blanco se ven pequeños.

## Solución Aplicada
He configurado iconos adaptativos en Android que automáticamente ajustarán el tamaño.

## Para ajustar manualmente (si es necesario):

### Opción A - Editor de Imágenes Simple (Paint 3D, Paint.NET)
1. Abre `assets/images/icon.png`
2. Selecciona el contenido del auto y engranaje blanco (sin el fondo azul)
3. Escálalo a 120-130% de su tamaño actual
4. Asegúrate de que quede centrado
5. Guarda como PNG con transparencia

### Opción B - Editor Profesional (Photoshop, GIMP, Figma)
1. Abre `assets/images/icon.png`
2. Crea una nueva capa con el auto y engranaje
3. Usa Transform (Ctrl+T) para escalarlo:
   - Mantén Shift presionado para proporciones
   - Escala al 125-130%
4. Centra el elemento
5. Exporta como PNG 1024x1024

### Opción C - Recrear desde cero
Si tienes el diseño original en formato vectorial (SVG, AI):
1. Abre el archivo fuente
2. Aumenta el tamaño del auto y engranaje en un 25-30%
3. Exporta como PNG 1024x1024 o superior

## Regenerar Íconos

Después de editar la imagen:

```powershell
flutter pub run flutter_launcher_icons
```

## Resultado Esperado
- El auto y engranaje deben ocupar aproximadamente el 70-80% del espacio del círculo blanco
- El círculo azul permanece igual
- El ícono debe verse equilibrado y profesional
