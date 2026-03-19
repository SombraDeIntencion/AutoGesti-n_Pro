import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Widget que muestra el límite de vehículos del usuario
class VehicleLimitIndicator extends StatelessWidget {
  final int currentVehicles;
  final int maxVehicles;
  final String subscriptionTier;
  final VoidCallback? onUpgradeTap;

  const VehicleLimitIndicator({
    super.key,
    required this.currentVehicles,
    required this.maxVehicles,
    required this.subscriptionTier,
    this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAtLimit = currentVehicles >= maxVehicles;
    final isFree = subscriptionTier.toLowerCase() == 'free';
    final percentage = maxVehicles > 0 ? currentVehicles / maxVehicles : 0.0;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: isFree
            ? const LinearGradient(
                colors: [
                  Color(0xFFFF9500), // Naranja
                  Color(0xFFFF6B00), // Naranja oscuro
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFree ? null : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: isFree
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        boxShadow: isFree
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isFree && onUpgradeTap != null ? onUpgradeTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ícono y contador
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Encabezado
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.vehicles,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTierBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Contador compacto
                      Row(
                        children: [
                          Text(
                            '$currentVehicles',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / $maxVehicles',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFree
                                ? Colors.white
                                : (isAtLimit
                                      ? Colors.orange
                                      : Colors.greenAccent),
                          ),
                          minHeight: 4,
                        ),
                      ),

                      // Mensaje
                      if (isFree) ...[
                        const SizedBox(height: 6),
                        Text(
                          isAtLimit
                              ? l10n.limitReached
                              : l10n.manageMoreVehiclesUnlimited,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (isAtLimit) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade300,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                l10n.limitReached,
                                style: TextStyle(
                                  color: Colors.orange.shade300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Botón de upgrade (solo para free)
                if (isFree && onUpgradeTap != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
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
