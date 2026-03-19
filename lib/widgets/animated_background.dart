import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget de fondo animado sutil para pantallas principales
/// Similar al efecto de Copilot con movimiento suave
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF17A2B8), // Turquesa
      Color(0xFF0088CC), // Azul
    ],
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo base con degradado
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
            ),
          ),
        ),
        
        // Capa de animación sutil
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _BackgroundPainter(
                animation: _controller.value,
                colors: widget.colors,
              ),
              size: Size.infinite,
            );
          },
        ),
        
        // Contenido principal
        widget.child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  _BackgroundPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0;

    // Crear formas orgánicas que se mueven sutilmente
    final path1 = Path();
    final path2 = Path();
    
    // Primera forma (arriba izquierda)
    final offset1 = math.sin(animation * 2 * math.pi) * 50;
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(
      size.width * 0.25 + offset1,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.25 + offset1,
    );
    path1.quadraticBezierTo(
      size.width * 0.75 - offset1,
      size.height * 0.3,
      size.width,
      size.height * 0.2,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    paint.color = colors[0].withValues(alpha: 0.1);
    canvas.drawPath(path1, paint);

    // Segunda forma (abajo derecha)
    final offset2 = math.cos(animation * 2 * math.pi) * 50;
    path2.moveTo(size.width, size.height * 0.7);
    path2.quadraticBezierTo(
      size.width * 0.75 + offset2,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.75 + offset2,
    );
    path2.quadraticBezierTo(
      size.width * 0.25 - offset2,
      size.height * 0.7,
      0,
      size.height * 0.8,
    );
    path2.lineTo(0, size.height);
    path2.lineTo(size.width, size.height);
    path2.close();

    paint.color = colors[1].withValues(alpha: 0.1);
    canvas.drawPath(path2, paint);

    // Añadir puntos sutiles flotantes
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (animation + i / 8) * 2 * math.pi;
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.3;
      final y = size.height * 0.5 + math.sin(angle) * size.height * 0.3;
      final radius = 3.0 + math.sin(animation * 4 * math.pi + i) * 2;
      
      paint.color = Colors.white.withValues(alpha: 0.05);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Widget de fondo simple con silueta de auto sutil
class CarSilhouetteBackground extends StatelessWidget {
  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;

  const CarSilhouetteBackground({
    super.key,
    required this.child,
    this.primaryColor = const Color(0xFF17A2B8),
    this.secondaryColor = const Color(0xFF0088CC),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo con degradado
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
        ),
        
        // Siluetas de autos sutiles
        Positioned(
          right: -50,
          top: 100,
          child: Opacity(
            opacity: 0.05,
            child: Icon(
              Icons.directions_car,
              size: 200,
              color: Colors.white,
            ),
          ),
        ),
        
        Positioned(
          left: -50,
          bottom: 100,
          child: Opacity(
            opacity: 0.05,
            child: Icon(
              Icons.local_shipping,
              size: 180,
              color: Colors.white,
            ),
          ),
        ),
        
        // Contenido
        child,
      ],
    );
  }
}

/// Extension para aplicar el fondo animado fácilmente
extension AnimatedBackgroundExtension on Widget {
  /// Envuelve el widget en un fondo animado
  Widget withAnimatedBackground({
    List<Color>? colors,
    Duration? duration,
  }) {
    return AnimatedBackground(
      colors: colors ?? const [Color(0xFF17A2B8), Color(0xFF0088CC)],
      duration: duration ?? const Duration(seconds: 10),
      child: this,
    );
  }

  /// Envuelve el widget en un fondo con silueta de auto
  Widget withCarSilhouette({
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    return CarSilhouetteBackground(
      primaryColor: primaryColor ?? const Color(0xFF17A2B8),
      secondaryColor: secondaryColor ?? const Color(0xFF0088CC),
      child: this,
    );
  }
}
