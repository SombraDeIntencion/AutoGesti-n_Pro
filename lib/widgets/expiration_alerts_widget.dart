import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../l10n/app_localizations.dart';

class ExpirationAlertsWidget extends StatelessWidget {
  final List<Vehicle> vehicles;

  const ExpirationAlertsWidget({super.key, required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final vehicleAlerts = _getGroupedAlerts(context);

    if (vehicleAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
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
            color: Colors.red.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).expirationAlerts,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Badges compactos en Wrap para evitar overflow
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vehicleAlerts.entries
                .map(
                  (entry) =>
                      _buildVehicleBadge(context, entry.key, entry.value),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleBadge(
    BuildContext context,
    String vehicleName,
    VehicleAlertGroup alertGroup,
  ) {
    final hasExpired = alertGroup.expiredCount > 0;
    final totalAlerts = alertGroup.alerts.length;

    return InkWell(
      onTap: () => _showAlertDetails(context, vehicleName, alertGroup),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasExpired ? Colors.red.shade100 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasExpired ? Colors.red.shade300 : Colors.orange.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasExpired ? Icons.error : Icons.warning,
              color: hasExpired ? Colors.red.shade700 : Colors.orange.shade700,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                vehicleName,
                style: TextStyle(
                  color: hasExpired
                      ? Colors.red.shade900
                      : Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasExpired
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalAlerts',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(
    BuildContext context,
    String vehicleName,
    VehicleAlertGroup alertGroup,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: alertGroup.expiredCount > 0
                    ? Colors.red.shade100
                    : Colors.orange.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: alertGroup.expiredCount > 0
                        ? Colors.red.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vehicleName,
                      style: TextStyle(
                        color: alertGroup.expiredCount > 0
                            ? Colors.red.shade900
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Lista de alertas
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: alertGroup.alerts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final alert = alertGroup.alerts[index];
                  return ListTile(
                    leading: Icon(
                      alert.isExpired ? Icons.error : Icons.warning,
                      color: alert.isExpired ? Colors.red : Colors.orange,
                    ),
                    title: Text(
                      alert.documentType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(alert.message),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, VehicleAlertGroup> _getGroupedAlerts(BuildContext context) {
    final Map<String, VehicleAlertGroup> groupedAlerts = {};
    final loc = AppLocalizations.of(context);

    for (final vehicle in vehicles) {
      final List<ExpirationAlert> vehicleAlerts = [];
      int expiredCount = 0;

      // Verificar seguro
      if (vehicle.insurance.expirationDate != null) {
        if (vehicle.insurance.isExpired) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.insurance,
              message: loc.insuranceExpiredDays(
                vehicle.insurance.daysUntilExpiration.abs(),
              ),
              isExpired: true,
            ),
          );
          expiredCount++;
        } else if (vehicle.insurance.isExpiringSoon) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.insurance,
              message: loc.insuranceExpiresInDays(
                vehicle.insurance.daysUntilExpiration,
              ),
              isExpired: false,
            ),
          );
        }
      }

      // Verificar tarjeta de circulación
      if (vehicle.circulationCard.expirationDate != null) {
        if (vehicle.circulationCard.isExpired) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.circulationCard,
              message: loc.circulationCardExpiredDays(
                vehicle.circulationCard.daysUntilExpiration.abs(),
              ),
              isExpired: true,
            ),
          );
          expiredCount++;
        } else if (vehicle.circulationCard.isExpiringSoon) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.circulationCard,
              message: loc.circulationCardExpiresInDays(
                vehicle.circulationCard.daysUntilExpiration,
              ),
              isExpired: false,
            ),
          );
        }
      }

      // Verificar otros documentos
      if (vehicle.otherDocuments.expirationDate != null) {
        if (vehicle.otherDocuments.isExpired) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.otherDocuments,
              message: loc.otherDocumentsExpiredDays(
                vehicle.otherDocuments.daysUntilExpiration.abs(),
              ),
              isExpired: true,
            ),
          );
          expiredCount++;
        } else if (vehicle.otherDocuments.isExpiringSoon) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.otherDocuments,
              message: loc.otherDocumentsExpiresInDays(
                vehicle.otherDocuments.daysUntilExpiration,
              ),
              isExpired: false,
            ),
          );
        }
      }

      // Verificar engomado ecológico
      if (vehicle.ecologicalSticker.expirationDate != null) {
        if (vehicle.ecologicalSticker.isExpired) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.ecologicalSticker,
              message: loc.ecologicalStickerExpiredDays(
                vehicle.ecologicalSticker.daysUntilExpiration.abs(),
              ),
              isExpired: true,
            ),
          );
          expiredCount++;
        } else if (vehicle.ecologicalSticker.isExpiringSoon) {
          vehicleAlerts.add(
            ExpirationAlert(
              vehicleName: vehicle.name,
              documentType: loc.ecologicalSticker,
              message: loc.ecologicalStickerExpiresInDays(
                vehicle.ecologicalSticker.daysUntilExpiration,
              ),
              isExpired: false,
            ),
          );
        }
      }

      // Si hay alertas para este vehículo, agregarlo al mapa
      if (vehicleAlerts.isNotEmpty) {
        groupedAlerts[vehicle.name] = VehicleAlertGroup(
          alerts: vehicleAlerts,
          expiredCount: expiredCount,
        );
      }
    }

    return groupedAlerts;
  }
}

class VehicleAlertGroup {
  final List<ExpirationAlert> alerts;
  final int expiredCount;

  VehicleAlertGroup({required this.alerts, required this.expiredCount});
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
