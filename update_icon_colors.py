"""
Script para actualizar los colores del ícono de AutoGestión Pro a AutoGestión Max
Cambia los colores azul antiguo por los nuevos colores de marca
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

def hex_to_rgb(hex_color):
    """Convierte color hex a RGB"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_gradient_background(size, color1, color2):
    """Crea un fondo con degradado"""
    base = Image.new('RGB', size, color1)
    top = Image.new('RGB', size, color2)
    mask = Image.new('L', size)
    mask_data = []
    for y in range(size[1]):
        for x in range(size[0]):
            # Degradado diagonal
            distance = ((x / size[0]) + (y / size[1])) / 2
            mask_data.append(int(255 * distance))
    mask.putdata(mask_data)
    base.paste(top, (0, 0), mask)
    return base

def recolor_icon():
    """Recolorea el ícono con los nuevos colores de AutoGestión Max"""
    
    # Colores nuevos
    PRIMARY_BLUE = hex_to_rgb('#0088CC')
    SECONDARY_CYAN = hex_to_rgb('#17A2B8')
    ACCENT_ORANGE = hex_to_rgb('#FF9500')
    WHITE = (255, 255, 255)
    
    # Colores antiguos que queremos reemplazar (aproximados)
    OLD_BLUE = hex_to_rgb('#1E40AF')  # Azul antiguo
    OLD_CYAN = hex_to_rgb('#06B6D4')  # Cyan antiguo
    
    size = (1024, 1024)
    
    try:
        # Intentar cargar el ícono original
        original = Image.open('assets/images/app_icon_original.png')
        original = original.convert('RGBA')
        original = original.resize(size, Image.Resampling.LANCZOS)
        
        # Crear nuevo ícono con degradado de fondo
        new_icon = create_gradient_background(size, SECONDARY_CYAN, PRIMARY_BLUE)
        new_icon = new_icon.convert('RGBA')
        
        # Analizar y recolorear el ícono original
        pixels = original.load()
        new_pixels = new_icon.load()
        
        for y in range(original.size[1]):
            for x in range(original.size[0]):
                r, g, b, a = pixels[x, y]
                
                # Si tiene transparencia alta, mantener el fondo
                if a < 50:
                    continue
                
                # Si es azul oscuro, cambiar a blanco (para el auto)
                if b > 150 and r < 100 and g < 100:
                    new_pixels[x, y] = (*WHITE, a)
                # Si es azul claro o cyan, mantener pero ajustar
                elif b > r and b > g:
                    # Hacer el auto más brillante
                    new_pixels[x, y] = (*WHITE, a)
                else:
                    # Otros colores, mantener o ajustar
                    new_pixels[x, y] = (r, g, b, a)
        
        # Pegar el ícono recoloreado sobre el degradado
        new_icon.paste(original, (0, 0), original)
        
    except FileNotFoundError:
        # Si no existe el original, crear uno desde cero
        print("Creando ícono desde cero...")
        new_icon = create_gradient_background(size, SECONDARY_CYAN, PRIMARY_BLUE)
        new_icon = new_icon.convert('RGBA')
        draw = ImageDraw.Draw(new_icon)
        
        # Dibujar un auto simple
        center_x, center_y = 512, 512
        car_width, car_height = 400, 240
        
        # Carrocería
        car_rect = [
            center_x - car_width//2, center_y - car_height//2,
            center_x + car_width//2, center_y + car_height//2
        ]
        draw.rounded_rectangle(car_rect, radius=40, fill=WHITE, outline=PRIMARY_BLUE, width=8)
        
        # Ventanas
        window_height = 80
        window_y = center_y - car_height//2 + 40
        # Ventana izquierda
        draw.rounded_rectangle(
            [center_x - 150, window_y, center_x - 30, window_y + window_height],
            radius=15, fill=PRIMARY_BLUE + (100,)
        )
        # Ventana derecha
        draw.rounded_rectangle(
            [center_x + 30, window_y, center_x + 150, window_y + window_height],
            radius=15, fill=PRIMARY_BLUE + (100,)
        )
        
        # Ruedas
        wheel_radius = 45
        wheel_y = center_y + car_height//2 - 20
        # Rueda izquierda
        draw.ellipse(
            [center_x - 130 - wheel_radius, wheel_y - wheel_radius,
             center_x - 130 + wheel_radius, wheel_y + wheel_radius],
            fill=(50, 50, 50), outline=(30, 30, 30), width=4
        )
        # Rueda derecha
        draw.ellipse(
            [center_x + 130 - wheel_radius, wheel_y - wheel_radius,
             center_x + 130 + wheel_radius, wheel_y + wheel_radius],
            fill=(50, 50, 50), outline=(30, 30, 30), width=4
        )
        
        # Barra naranja de acento
        draw.rectangle(
            [center_x - car_width//2 + 20, center_y + car_height//2 - 60,
             center_x + car_width//2 - 20, center_y + car_height//2 - 45],
            fill=ACCENT_ORANGE
        )
        
        # Texto "MAX" sutil
        try:
            # Intentar usar una fuente, si no está disponible, omitir
            font = ImageFont.truetype("arial.ttf", 48)
            text = "MAX"
            # Calcular posición centrada
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_x = (size[0] - text_width) // 2
            text_y = size[1] - 120
            draw.text((text_x, text_y), text, fill=WHITE + (80,), font=font)
        except:
            pass
    
    # Guardar el nuevo ícono
    new_icon.save('assets/images/app_icon.png')
    print("✅ Ícono actualizado guardado como: assets/images/app_icon.png")
    print(f"   Tamaño: {size[0]}x{size[1]}px")
    print(f"   Colores: Primario {PRIMARY_BLUE}, Secundario {SECONDARY_CYAN}, Acento {ACCENT_ORANGE}")

if __name__ == '__main__':
    recolor_icon()
