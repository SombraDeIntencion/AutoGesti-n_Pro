import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class ExpirationAlertsWidget extends StatelessWidget {
  final List<Vehicle> vehicles;

  const ExpirationAlertsWidget({super.key, required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final alerts = _getExpirationAlerts();

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.orange.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ Alertas de Vencimiento',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Limitar altura máxima y hacer scrollable
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children: alerts
                    .map((alert) => _buildAlertItem(alert))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(ExpirationAlert alert) {
    IconData icon;
    Color color;

    if (alert.isExpired) {
      icon = Icons.error;
      color = Colors.red;
    } else {
      icon = Icons.warning;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.vehicleName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ExpirationAlert> _getExpirationAlerts() {
    final List<ExpirationAlert> alerts = [];

    for (final vehicle in vehicles) {
      // Verificar seguro
      if (vehicle.insurance.expirationDate != null) {
        if (vehicle.insurance.isExpired) {
          alerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: 'Seguro',
              message:
                  'El seguro está VENCIDO desde hace ${vehicle.insurance.daysUntilExpiration.abs()} días',
              isExpired: true,
            ),
          );
        } else if (vehicle.insurance.isExpiringSoon) {
          alerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: 'Seguro',
              message:
                  'El seguro vence en ${vehicle.insurance.daysUntilExpiration} días',
              isExpired: false,
            ),
          );
        }
      }

      // Verificar tarjeta de circulación
      if (vehicle.circulationCard.expirationDate != null) {
        if (vehicle.circulationCard.isExpired) {
          alerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: 'Tarjeta de Circulación',
              message:
                  'La tarjeta de circulación está VENCIDA desde hace ${vehicle.circulationCard.daysUntilExpiration.abs()} días',
              isExpired: true,
            ),
          );
        } else if (vehicle.circulationCard.isExpiringSoon) {
          alerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: 'Tarjeta de Circulación',
              message:
                  'La tarjeta de circulación vence en ${vehicle.circulationCard.daysUntilExpiration} días',
              isExpired: false,
            ),
          );
        }
      }
    }

    // Ordenar: vencidos primero, luego por días restantes
    alerts.sort((a, b) {
      if (a.isExpired && !b.isExpired) return -1;
      if (!a.isExpired && b.isExpired) return 1;
      return 0;
    });

    return alerts;
  }
}

class ExpirationAlert {
  final String vehicleName;
  final String documentType;
  final String message;
  final bool isExpired;

  ExpirationAlert({
    required this.vehicleName,
    required this.documentType,
    required this.message,
    required this.isExpired,
  });
}
