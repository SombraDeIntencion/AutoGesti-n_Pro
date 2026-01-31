import 'package:flutter/material.dart';

/// Widget que muestra el límite de vehículos del usuario
class VehicleLimitIndicator extends StatelessWidget {
  final int currentVehicles;
  final int maxVehicles;
  final String subscriptionTier;

  const VehicleLimitIndicator({
    super.key,
    required this.currentVehicles,
    required this.maxVehicles,
    required this.subscriptionTier,
  });

  @override
  Widget build(BuildContext context) {
    final isAtLimit = currentVehicles >= maxVehicles;
    final percentage = maxVehicles > 0 ? currentVehicles / maxVehicles : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado con ícono y texto
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vehículos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildTierBadge(),
            ],
          ),
          const SizedBox(height: 8),
          
          // Contador
          Row(
            children: [
              Text(
                '$currentVehicles',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / $maxVehicles',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAtLimit
                    ? Colors.orange
                    : Colors.greenAccent,
              ),
              minHeight: 6,
            ),
          ),
          
          // Mensaje de límite alcanzado
          if (isAtLimit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade300,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Límite alcanzado',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTierBadge() {
    Color badgeColor;
    String tierText;
    
    switch (subscriptionTier.toLowerCase()) {
      case 'free':
        badgeColor = Colors.grey;
        tierText = 'FREE';
        break;
      case 'basic':
        badgeColor = Colors.blue;
        tierText = 'BASIC';
        break;
      case 'pro':
        badgeColor = Colors.purple;
        tierText = 'PRO';
        break;
      case 'enterprise':
        badgeColor = Colors.amber;
        tierText = 'ENTERPRISE';
        break;
      default:
        badgeColor = Colors.grey;
        tierText = subscriptionTier.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tierText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
