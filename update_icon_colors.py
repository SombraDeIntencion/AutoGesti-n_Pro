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
    
    # Colores nuevos - AutoGestión Max
    PRIMARY_BLUE = hex_to_rgb('#0088CC')    # Azul brillante distintivo
    SECONDARY_CYAN = hex_to_rgb('#00BFA5')  # Turquesa vibrante
    ACCENT_ORANGE = hex_to_rgb('#FF9500')   # Naranja distintivo
    WHITE = (255, 255, 255)
    DARK = (30, 30, 30)
    
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
        # Si no existe el original, crear uno desde cero - DISEÑO MAX
        print("Creando ícono distintivo de AutoGestión MAX desde cero...")
        # Fondo con degradado vibrante
        new_icon = create_gradient_background(size, PRIMARY_BLUE, SECONDARY_CYAN)
        new_icon = new_icon.convert('RGBA')
        draw = ImageDraw.Draw(new_icon)
        
        # Diseño distintivo para MAX: Auto moderno con énfasis en "MAX"
        center_x, center_y = 512, 450
        car_width, car_height = 450, 280
        
        # Sombra del auto
        shadow_offset = 15
        draw.rounded_rectangle(
            [center_x - car_width//2 + shadow_offset, center_y - car_height//2 + shadow_offset,
             center_x + car_width//2 + shadow_offset, center_y + car_height//2 + shadow_offset],
            radius=50, fill=(0, 0, 0, 60)
        )
        
        # Carrocería principal - blanco brillante
        car_rect = [
            center_x - car_width//2, center_y - car_height//2,
            center_x + car_width//2, center_y + car_height//2
        ]
        draw.rounded_rectangle(car_rect, radius=50, fill=WHITE, outline=None)
        
        # Parabrisas grande
        window_height = 100
        window_y = center_y - car_height//2 + 50
        draw.rounded_rectangle(
            [center_x - 180, window_y, center_x + 180, window_y + window_height],
            radius=20, fill=PRIMARY_BLUE
        )
        
        # Franja inferior naranja distintiva (marca MAX)
        draw.rectangle(
            [center_x - car_width//2 + 40, center_y + car_height//2 - 70,
             center_x + car_width//2 - 40, center_y + car_height//2 - 35],
            fill=ACCENT_ORANGE
        )
        
        # Ruedas modernas
        wheel_radius = 50
        wheel_y = center_y + car_height//2 - 15
        # Rueda izquierda
        draw.ellipse(
            [center_x - 150 - wheel_radius, wheel_y - wheel_radius,
             center_x - 150 + wheel_radius, wheel_y + wheel_radius],
            fill=DARK, outline=WHITE, width=6
        )
        # Llanta interior
        draw.ellipse(
            [center_x - 150 - 25, wheel_y - 25,
             center_x - 150 + 25, wheel_y + 25],
            fill=(80, 80, 80)
        )
        
        # Rueda derecha
        draw.ellipse(
            [center_x + 150 - wheel_radius, wheel_y - wheel_radius,
             center_x + 150 + wheel_radius, wheel_y + wheel_radius],
            fill=DARK, outline=WHITE, width=6
        )
        # Llanta interior
        draw.ellipse(
            [center_x + 150 - 25, wheel_y - 25,
             center_x + 150 + 25, wheel_y + 25],
            fill=(80, 80, 80)
        )
        
        # Texto "MAX" grande y visible
        try:
            # Usar fuente más grande para MAX
            font_max = ImageFont.truetype("arial.ttf", 140)
            text = "MAX"
            bbox = draw.textbbox((0, 0), text, font=font_max)
            text_width = bbox[2] - bbox[0]
            text_x = (size[0] - text_width) // 2
            text_y = center_y + car_height//2 + 100
            
            # Sombra del texto
            draw.text((text_x + 4, text_y + 4), text, fill=(0, 0, 0, 100), font=font_max)
            # Texto principal
            draw.text((text_x, text_y), text, fill=WHITE, font=font_max)
        except:
            # Si falla la fuente, dibujar rectángulo con "MAX"
            max_rect = [350, 750, 674, 850]
            draw.rounded_rectangle(max_rect, radius=20, fill=WHITE)
            # Texto simple sin fuente
            pass
    
    # Guardar el nuevo ícono
    new_icon.save('assets/images/app_icon.png')
    print("✅ Ícono actualizado guardado como: assets/images/app_icon.png")
    print(f"   Tamaño: {size[0]}x{size[1]}px")
    print(f"   Colores: Primario {PRIMARY_BLUE}, Secundario {SECONDARY_CYAN}, Acento {ACCENT_ORANGE}")

if __name__ == '__main__':
    recolor_icon()
