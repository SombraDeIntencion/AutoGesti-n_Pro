import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../utils/app_theme.dart';

/// Ejemplo de cómo usar el fondo animado en una pantalla
/// Esta pantalla puede servir como splash screen o pantalla de bienvenida
class AnimatedBackgroundExample extends StatelessWidget {
  const AnimatedBackgroundExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        colors: const [
          AppTheme.backgroundLight,
          AppTheme.backgroundDark,
        ],
        duration: const Duration(seconds: 12),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o ícono de la app
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 60,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Título
                const Text(
                  'AutoGestión Max',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtítulo
                const Text(
                  'Guonxoá de Fartinara Selenassá',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Botón de ejemplo
                ElevatedButton(
                  onPressed: () {
                    // Navegar a la pantalla principal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ejemplo usando el fondo con silueta de auto
class CarSilhouetteExample extends StatelessWidget {
  const CarSilhouetteExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CarSilhouetteBackground(
        primaryColor: AppTheme.backgroundLight,
        secondaryColor: AppTheme.backgroundDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AutoGestión Max',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Guonxoá de Fartinara Selenassá',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Contenido de ejemplo
                Expanded(
                  child: ListView(
                    children: [
                      _buildInfoCard(
                        icon: Icons.directions_car,
                        title: 'Vehículos',
                        subtitle: 'Gestiona tu flotilla',
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.attach_money,
                        title: 'Gastos',
                        subtitle: 'Control financiero',
                        color: AppTheme.secondaryCyan,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.build,
                        title: 'Mantenimiento',
                        subtitle: 'Historial completo',
                        color: AppTheme.accentOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}
