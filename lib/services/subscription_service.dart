import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;

/// Servicio para gestionar suscripciones con Google Play Billing
class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── IDs de productos de Google Play Console ──
  // IMPORTANTE: Estos IDs deben coincidir con los configurados en Play Console

  // Mensuales normales (existentes)
  static const String starter2Id = 'startermonthly2'; // 2-3 vehículos
  static const String starter5Id = 'startermonthly5'; // 4-5 vehículos
  static const String small8Id = 'smallmonthly8'; // 6-8 vehículos
  static const String small12Id = 'smallmonthly12'; // 9-12 vehículos
  static const String medium17Id = 'mediummonthly17'; // 13-17 vehículos
  static const String medium23Id = 'mediummonthly23'; // 18-23 vehículos
  static const String large30Id = 'largemonthly30'; // 24-30 vehículos
  static const String large40Id = 'largemonthly40'; // 31-40 vehículos
  static const String enterprise50Id = 'enterprisemonthly50'; // 41-50 vehículos

  // Mensuales con 50% de descuento (retención)
  static const String starterDiscount2Id = 'starterdiscount2';
  static const String starterDiscount5Id = 'starterdiscount5';
  static const String smallDiscount8Id = 'smalldiscount8';
  static const String smallDiscount12Id = 'smalldiscount12';
  static const String mediumDiscount17Id = 'mediumdiscount17';
  static const String mediumDiscount23Id = 'mediumdiscount23';
  static const String largeDiscount30Id = 'largediscount30';
  static const String largeDiscount40Id = 'largediscount40';
  static const String enterpriseDiscount50Id = 'enterprisediscount50';

  // Anuales normales (25% dto vs mensual×12)
  static const String starterAnnual2Id = 'starterannual2v2';
  static const String starterAnnual5Id = 'starterannual5';
  static const String smallAnnual8Id = 'smallannual8';
  static const String smallAnnual12Id = 'smallannual12';
  static const String mediumAnnual17Id = 'mediumannual17';
  static const String mediumAnnual23Id = 'mediumannual23';
  static const String largeAnnual30Id = 'largeannual30';
  static const String largeAnnual40Id = 'largeannual40';
  static const String enterpriseAnnual50Id = 'enterpriseannual50';

  // Anuales con 50% de descuento (retención)
  static const String starterAnnualDiscount2Id = 'starterannualdiscount2';
  static const String starterAnnualDiscount5Id = 'starterannualdiscount5';
  static const String smallAnnualDiscount8Id = 'smallannualdiscount8';
  static const String smallAnnualDiscount12Id = 'smallannualdiscount12';
  static const String mediumAnnualDiscount17Id = 'mediumannualdiscount17';
  static const String mediumAnnualDiscount23Id = 'mediumannualdiscount23';
  static const String largeAnnualDiscount30Id = 'largeannualdiscount30';
  static const String largeAnnualDiscount40Id = 'largeannualdiscount40';
  static const String enterpriseAnnualDiscount50Id =
      'enterpriseannualdiscount50';

  // Lista de TODOS los IDs de suscripciones
  static const Set<String> _subscriptionIds = {
    // Mensuales normales
    starter2Id, starter5Id, small8Id, small12Id,
    medium17Id, medium23Id, large30Id, large40Id, enterprise50Id,
    // Mensuales con descuento
    starterDiscount2Id, starterDiscount5Id, smallDiscount8Id, smallDiscount12Id,
    mediumDiscount17Id,
    mediumDiscount23Id,
    largeDiscount30Id,
    largeDiscount40Id,
    enterpriseDiscount50Id,
    // Anuales normales
    starterAnnual2Id, starterAnnual5Id, smallAnnual8Id, smallAnnual12Id,
    mediumAnnual17Id,
    mediumAnnual23Id,
    largeAnnual30Id,
    largeAnnual40Id,
    enterpriseAnnual50Id,
    // Anuales con descuento
    starterAnnualDiscount2Id,
    starterAnnualDiscount5Id,
    smallAnnualDiscount8Id,
    smallAnnualDiscount12Id,
    mediumAnnualDiscount17Id,
    mediumAnnualDiscount23Id,
    largeAnnualDiscount30Id,
    largeAnnualDiscount40Id,
    enterpriseAnnualDiscount50Id,
  };

  /// Mapeo de tier → todos los product IDs asociados (mensual, anual, descuentos)
  static Map<String, String> getTierProductIds(String tier) {
    switch (tier) {
      case 'starter2':
        return {
          'monthly': starter2Id,
          'annual': starterAnnual2Id,
          'monthlyDiscount': starterDiscount2Id,
          'annualDiscount': starterAnnualDiscount2Id,
        };
      case 'starter5':
        return {
          'monthly': starter5Id,
          'annual': starterAnnual5Id,
          'monthlyDiscount': starterDiscount5Id,
          'annualDiscount': starterAnnualDiscount5Id,
        };
      case 'small8':
        return {
          'monthly': small8Id,
          'annual': smallAnnual8Id,
          'monthlyDiscount': smallDiscount8Id,
          'annualDiscount': smallAnnualDiscount8Id,
        };
      case 'small12':
        return {
          'monthly': small12Id,
          'annual': smallAnnual12Id,
          'monthlyDiscount': smallDiscount12Id,
          'annualDiscount': smallAnnualDiscount12Id,
        };
      case 'medium17':
        return {
          'monthly': medium17Id,
          'annual': mediumAnnual17Id,
          'monthlyDiscount': mediumDiscount17Id,
          'annualDiscount': mediumAnnualDiscount17Id,
        };
      case 'medium23':
        return {
          'monthly': medium23Id,
          'annual': mediumAnnual23Id,
          'monthlyDiscount': mediumDiscount23Id,
          'annualDiscount': mediumAnnualDiscount23Id,
        };
      case 'large30':
        return {
          'monthly': large30Id,
          'annual': largeAnnual30Id,
          'monthlyDiscount': largeDiscount30Id,
          'annualDiscount': largeAnnualDiscount30Id,
        };
      case 'large40':
        return {
          'monthly': large40Id,
          'annual': largeAnnual40Id,
          'monthlyDiscount': largeDiscount40Id,
          'annualDiscount': largeAnnualDiscount40Id,
        };
      case 'enterprise50':
        return {
          'monthly': enterprise50Id,
          'annual': enterpriseAnnual50Id,
          'monthlyDiscount': enterpriseDiscount50Id,
          'annualDiscount': enterpriseAnnualDiscount50Id,
        };
      default:
        return {};
    }
  }

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isDisposed = false;

  /// Liberar recursos del servicio
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _subscription?.cancel();
      _subscription = null;
    }
  }

  /// Inicializar el servicio
  Future<bool> initialize() async {
    if (_isDisposed) return false;
    try {
      // Verificar disponibilidad de la plataforma
      final available = await _iap.isAvailable();
      if (!available) {
        return false;
      }

      // Escuchar cambios en las compras
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onDone: _onPurchasesDone,
        onError: _onPurchasesError,
      );

      // Cargar productos disponibles
      await loadProducts();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cargar productos disponibles desde Google Play
  Future<void> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_subscriptionIds);

      if (response.error != null) {
        return;
      }

      _products = response.productDetails;
    } catch (e) {
      // Error silencioso
    }
  }

  /// Obtener lista de productos disponibles
  List<ProductDetails> get products => _products;

  /// Obtener producto específico por ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Obtener información de la suscripción activa desde Firestore
  Future<Map<String, dynamic>?> getCurrentSubscriptionInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final isActive = data['isSubscriptionActive'] ?? false;
      final tier = data['subscriptionTier'] ?? 'free';

      if (!isActive || tier == 'free') return null;

      return {
        'tier': tier,
        'productId': _getProductIdFromTier(tier),
        'purchaseToken': data['purchaseToken'],
        'expiresAt': data['subscriptionExpiresAt'],
      };
    } catch (e) {
      debugPrint('Error obteniendo info de suscripción: $e');
      return null;
    }
  }

  /// Convertir tier a productId (mensual normal)
  String? _getProductIdFromTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'starter2':
        return starter2Id;
      case 'starter5':
        return starter5Id;
      case 'small8':
        return small8Id;
      case 'small12':
        return small12Id;
      case 'medium17':
        return medium17Id;
      case 'medium23':
        return medium23Id;
      case 'large30':
        return large30Id;
      case 'large40':
        return large40Id;
      case 'enterprise50':
        return enterprise50Id;
      default:
        return null;
    }
  }

  /// Obtener tier y maxVehicles de cualquier productId (mensual, anual, descuento)
  static Map<String, String> _getTierFromProductId(String productId) {
    // Mapeo: cualquier variante de producto → tier + maxVehicles
    const mapping = <String, List<String>>{
      // [tier, maxVehicles]
      'startermonthly2': ['starter2', '3'],
      'starterdiscount2': ['starter2', '3'],
      'starterannual2v2': ['starter2', '3'],
      'starterannualdiscount2': ['starter2', '3'],
      'startermonthly5': ['starter5', '5'],
      'starterdiscount5': ['starter5', '5'],
      'starterannual5': ['starter5', '5'],
      'starterannualdiscount5': ['starter5', '5'],
      'smallmonthly8': ['small8', '8'],
      'smalldiscount8': ['small8', '8'],
      'smallannual8': ['small8', '8'],
      'smallannualdiscount8': ['small8', '8'],
      'smallmonthly12': ['small12', '12'],
      'smalldiscount12': ['small12', '12'],
      'smallannual12': ['small12', '12'],
      'smallannualdiscount12': ['small12', '12'],
      'mediummonthly17': ['medium17', '17'],
      'mediumdiscount17': ['medium17', '17'],
      'mediumannual17': ['medium17', '17'],
      'mediumannualdiscount17': ['medium17', '17'],
      'mediummonthly23': ['medium23', '23'],
      'mediumdiscount23': ['medium23', '23'],
      'mediumannual23': ['medium23', '23'],
      'mediumannualdiscount23': ['medium23', '23'],
      'largemonthly30': ['large30', '30'],
      'largediscount30': ['large30', '30'],
      'largeannual30': ['large30', '30'],
      'largeannualdiscount30': ['large30', '30'],
      'largemonthly40': ['large40', '40'],
      'largediscount40': ['large40', '40'],
      'largeannual40': ['large40', '40'],
      'largeannualdiscount40': ['large40', '40'],
      'enterprisemonthly50': ['enterprise50', '50'],
      'enterprisediscount50': ['enterprise50', '50'],
      'enterpriseannual50': ['enterprise50', '50'],
      'enterpriseannualdiscount50': ['enterprise50', '50'],
    };

    final info = mapping[productId];
    if (info != null) {
      return {'tier': info[0], 'maxVehicles': info[1]};
    }
    return {'tier': 'free', 'maxVehicles': '1'};
  }

  /// Comparar planes para determinar si es upgrade o downgrade
  int comparePlans(String currentProductId, String newProductId) {
    final planOrder = [
      starter2Id,
      starter5Id,
      small8Id,
      small12Id,
      medium17Id,
      medium23Id,
      large30Id,
      large40Id,
      enterprise50Id,
    ];

    final currentIndex = planOrder.indexOf(currentProductId);
    final newIndex = planOrder.indexOf(newProductId);

    if (currentIndex == -1 || newIndex == -1) return 0;

    return newIndex.compareTo(currentIndex); // > 0 = upgrade, < 0 = downgrade
  }

  /// Comprar o cambiar suscripción
  Future<bool> purchaseSubscription(
    String productId, {
    bool isChanging = false,
  }) async {
    try {
      final product = getProduct(productId);
      if (product == null) {
        debugPrint('Producto no encontrado: $productId');
        return false;
      }

      // Verificar si hay suscripción activa
      final currentSubInfo = await getCurrentSubscriptionInfo();
      final hasActiveSub = currentSubInfo != null;

      if (hasActiveSub && Platform.isAndroid) {
        // Cambio de suscripción en Android
        final currentProductId = currentSubInfo['productId'] as String?;

        if (currentProductId == null) {
          debugPrint('No se pudo obtener el productId actual');
          return false;
        }

        // Determinar si es upgrade o downgrade
        final comparison = comparePlans(currentProductId, productId);

        debugPrint('Cambiando suscripción: $currentProductId -> $productId');
        debugPrint('Tipo: ${comparison > 0 ? "Upgrade" : "Downgrade"}');

        // NOTA: Para cambiar suscripciones en Android necesitamos los detalles
        // de la compra anterior. Por ahora, hacemos una compra nueva y el usuario
        // debe cancelar la anterior manualmente en Play Store.
        // TODO: Implementar almacenamiento de GooglePlayPurchaseDetails completo

        debugPrint('Iniciando nueva compra (cambio manual requerido)');
        final purchaseParam = PurchaseParam(productDetails: product);
        final success = await _iap.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        return success;
      } else {
        // Nueva suscripción (sin suscripción activa)
        final purchaseParam = PurchaseParam(productDetails: product);
        final success = await _iap.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        return success;
      }
    } catch (e) {
      debugPrint('Error al comprar/cambiar suscripción: $e');
      return false;
    }
  }

  /// Restaurar compras anteriores
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      // Error silencioso
    }
  }

  /// Manejar actualizaciones de compras
  Future<void> _onPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Compra pendiente - mostrar indicador de carga
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Error en la compra
        await _handlePurchaseError(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Compra exitosa o restaurada
        await _verifyAndDeliverProduct(purchaseDetails);
      }

      // Completar la compra
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verificar y entregar producto
  Future<void> _verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      // VALIDACIÓN: Solo procesar si la compra está confirmada por Google
      if (purchaseDetails.status != PurchaseStatus.purchased &&
          purchaseDetails.status != PurchaseStatus.restored) {
        return;
      }

      // Determinar el tier basado en el producto
      final tierInfo = _getTierFromProductId(purchaseDetails.productID);
      final String tier = tierInfo['tier']!;
      final int maxVehicles = int.parse(tierInfo['maxVehicles']!);

      // Actualizar usuario en Firestore (perfil/auth)
      // VALIDADO: Solo llegamos aquí si Google Play confirmó la compra
      final subscriptionData = {
        'subscriptionTier': tier,
        'maxVehicles': maxVehicles,
        'isSubscriptionActive': true,
        'subscriptionStatus': 'active',
        'purchaseToken':
            purchaseDetails.verificationData.serverVerificationData,
        'subscriptionExpiresAt': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'lastSubscriptionUpdate': DateTime.now().toIso8601String(),
      };
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(subscriptionData);

      // CRÍTICO: Sincronizar límites en la ruta que usa VehicleService para
      // verificar cuántos vehículos puede agregar el usuario.
      try {
        await _firestore
            .collection('autogestion_max')
            .doc('data')
            .collection('users')
            .doc(user.uid)
            .set({
              'subscriptionTier': tier,
              'maxVehicles': maxVehicles,
              'isSubscriptionActive': true,
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Aviso: no se pudo sincronizar límites de vehículos: $e');
      }

      // Guardar registro de la compra
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscriptions')
          .add({
            'productId': purchaseDetails.productID,
            'purchaseId': purchaseDetails.purchaseID,
            'transactionDate': DateTime.now().toIso8601String(),
            'status': purchaseDetails.status.toString(),
            'tier': tier,
            'maxVehicles': maxVehicles,
          });

      debugPrint('Suscripción activada: $tier');
    } catch (e) {
      debugPrint('Error verificando compra: $e');
    }
  }

  /// Manejar errores de compra
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Registrar el error
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchase_errors')
          .add({
            'productId': purchaseDetails.productID,
            'error': purchaseDetails.error?.message ?? 'Error desconocido',
            'errorCode': purchaseDetails.error?.code ?? 'unknown',
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('Error registrando error de compra: $e');
    }
  }

  /// Callback cuando el stream se completa
  void _onPurchasesDone() {
    debugPrint('Stream de compras completado');
    _subscription?.cancel();
  }

  /// Callback para errores en el stream
  void _onPurchasesError(dynamic error) {
    debugPrint('Error en el stream de compras: $error');
  }

  /// Verificar si el usuario tiene una suscripción activa
  Future<bool> hasActiveSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final isActive = data['isSubscriptionActive'] ?? false;
      final tier = data['subscriptionTier'] ?? 'free';

      if (tier == 'free') return false;
      if (!isActive) return false;

      // Verificar fecha de expiración
      final expiresAt = data['subscriptionExpiresAt'];
      if (expiresAt != null) {
        final expirationDate = DateTime.parse(expiresAt);
        if (expirationDate.isBefore(DateTime.now())) {
          // Suscripción expirada - actualizar estado
          await _firestore.collection('users').doc(user.uid).update({
            'isSubscriptionActive': false,
          });
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error verificando suscripción: $e');
      return false;
    }
  }

  /// Restaurar compras y validar con Google Play
  /// Esto consulta directamente a Google para verificar el estado real
  Future<bool> restoreAndValidatePurchases() async {
    try {
      debugPrint('Consultando compras con Google Play...');

      // Consultar compras pasadas directamente con Google
      await _iap.restorePurchases();

      // El stream _onPurchaseUpdated se encargará de validar
      // y activar las suscripciones confirmadas

      return true;
    } catch (e) {
      debugPrint('Error restaurando compras: $e');
      return false;
    }
  }

  /// Cancelar suscripción (redirigir a Play Store)
  /// Nota: Las suscripciones se cancelan desde la configuración de Google Play
  void cancelSubscription() {
    debugPrint(
      'Para cancelar tu suscripción, ve a Google Play Store > Suscripciones',
    );
    // En una app real, aquí se abriría el link de suscripciones de Play Store
  }

  /// Obtener información de precios
  Map<String, String> getPricing() {
    final pricing = <String, String>{};

    for (var product in _products) {
      pricing[product.id] = product.price;
    }

    return pricing;
  }

  /// Método de prueba para simular compra (solo para desarrollo)
  Future<void> simulatePurchase(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String tier;
      int maxVehicles;

      switch (productId) {
        case starter2Id:
        case starter5Id:
          tier = 'starter';
          maxVehicles = 5;
          break;
        case small8Id:
        case small12Id:
          tier = 'small';
          maxVehicles = 12;
          break;
        case medium17Id:
        case medium23Id:
          tier = 'medium';
          maxVehicles = 23;
          break;
        case large30Id:
        case large40Id:
          tier = 'large';
          maxVehicles = 40;
          break;
        case enterprise50Id:
          tier = 'enterprise';
          maxVehicles = 50;
          break;
        default:
          tier = 'free';
          maxVehicles = 1;
      }

      final simData = {
        'subscriptionTier': tier,
        'maxVehicles': maxVehicles,
        'isSubscriptionActive': true,
        'subscriptionExpiresAt': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'lastSubscriptionUpdate': DateTime.now().toIso8601String(),
      };
      await _firestore.collection('users').doc(user.uid).update(simData);

      // CRÍTICO: Sincronizar límites en la ruta que usa VehicleService
      try {
        await _firestore
            .collection('autogestion_max')
            .doc('data')
            .collection('users')
            .doc(user.uid)
            .set({
              'subscriptionTier': tier,
              'maxVehicles': maxVehicles,
              'isSubscriptionActive': true,
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Aviso: no se pudo sincronizar límites de vehículos: $e');
      }

      debugPrint('Compra simulada: $tier');
    } catch (e) {
      debugPrint('Error simulando compra: $e');
    }
  }
}
