import 'package:flutter/material.dart';

/// Widget para mostrar información del plan actual del usuario
class CurrentPlanInfo extends StatelessWidget {
  final String subscriptionTier;
  final int currentVehicles;
  final int maxVehicles;
  final VoidCallback onUpgrade;

  const CurrentPlanInfo({
    super.key,
    required this.subscriptionTier,
    required this.currentVehicles,
    required this.maxVehicles,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: _getTierColor(),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan ${_getTierName()}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Estadísticas
            _buildStatRow(
              Icons.directions_car,
              'Vehículos',
              '$currentVehicles / $maxVehicles',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              Icons.storage,
              'Almacenamiento',
              subscriptionTier == 'free' ? 'Local' : 'En la nube',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              Icons.backup,
              'Backup',
              subscriptionTier == 'free' ? 'Manual' : 'Automático',
            ),

            // Barra de progreso
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: maxVehicles > 0 ? currentVehicles / maxVehicles : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentVehicles >= maxVehicles
                      ? Colors.orange
                      : _getTierColor(),
                ),
                minHeight: 10,
              ),
            ),

            // Botón de upgrade (solo para free)
            if (subscriptionTier == 'free') ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Actualizar Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade600,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  String _getTierName() {
    switch (subscriptionTier.toLowerCase()) {
      case 'free':
        return 'Free';
      case 'basic':
        return 'Basic';
      case 'pro':
        return 'Pro';
      case 'enterprise':
        return 'Enterprise';
      default:
        return subscriptionTier;
    }
  }

  String _getSubtitle() {
    switch (subscriptionTier.toLowerCase()) {
      case 'free':
        return 'Ideal para empezar';
      case 'basic':
        return 'Para pequeños negocios';
      case 'pro':
        return 'Para profesionales';
      case 'enterprise':
        return 'Solución completa';
      default:
        return '';
    }
  }

  Color _getTierColor() {
    switch (subscriptionTier.toLowerCase()) {
      case 'free':
        return Colors.grey;
      case 'basic':
        return Colors.blue;
      case 'pro':
        return Colors.purple;
      case 'enterprise':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }
}
