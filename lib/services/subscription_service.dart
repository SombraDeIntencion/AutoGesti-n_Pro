import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para gestionar suscripciones con Google Play Billing
class SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // IDs de productos de Google Play Console
  // IMPORTANTE: Estos IDs deben coincidir con los configurados en Play Console
  static const String starterMonthlyId = 'starter_monthly'; // 2-5 vehículos
  static const String smallMonthlyId = 'small_monthly'; // 6-10 vehículos
  static const String mediumMonthlyId = 'medium_monthly'; // 11-20 vehículos
  static const String largeMonthlyId = 'large_monthly'; // 21-35 vehículos
  static const String enterpriseMonthlyId =
      'enterprise_monthly'; // 36-50 vehículos

  // Lista de IDs de suscripciones
  static const Set<String> _subscriptionIds = {
    starterMonthlyId,
    smallMonthlyId,
    mediumMonthlyId,
    largeMonthlyId,
    enterpriseMonthlyId,
  };

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  /// Inicializar el servicio
  Future<bool> initialize() async {
    try {
      // Verificar disponibilidad de la plataforma
      final available = await _iap.isAvailable();
      if (!available) {
        print('La tienda no está disponible en este dispositivo');
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
      print('Error inicializando subscription service: $e');
      return false;
    }
  }

  /// Cargar productos disponibles desde Google Play
  Future<void> loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_subscriptionIds);

      if (response.error != null) {
        print('Error cargando productos: ${response.error}');
        return;
      }

      _products = response.productDetails;
      print('Productos cargados: ${_products.length}');

      for (var product in _products) {
        print('Producto: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      print('Error en loadProducts: $e');
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

  /// Comprar una suscripción
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final product = getProduct(productId);
      if (product == null) {
        print('Producto no encontrado: $productId');
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      return success;
    } catch (e) {
      print('Error al comprar suscripción: $e');
      return false;
    }
  }

  /// Restaurar compras anteriores
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      print('Compras restauradas');
    } catch (e) {
      print('Error restaurando compras: $e');
    }
  }

  /// Manejar actualizaciones de compras
  Future<void> _onPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      print(
        'Compra actualizada: ${purchaseDetails.productID} - ${purchaseDetails.status}',
      );

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Compra pendiente - mostrar indicador de carga
        print('Compra pendiente...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Error en la compra
        print('Error en la compra: ${purchaseDetails.error}');
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
        print('Usuario no autenticado');
        return;
      }

      // Determinar el tier basado en el producto
      String tier;
      int maxVehicles;

      switch (purchaseDetails.productID) {
        case starterMonthlyId:
          tier = 'starter';
          maxVehicles = 5;
          break;
        case smallMonthlyId:
          tier = 'small';
          maxVehicles = 10;
          break;
        case mediumMonthlyId:
          tier = 'medium';
          maxVehicles = 20;
          break;
        case largeMonthlyId:
          tier = 'large';
          maxVehicles = 35;
          break;
        case enterpriseMonthlyId:
          tier = 'enterprise';
          maxVehicles = 50;
          break;
        default:
          tier = 'free';
          maxVehicles = 1;
      }

      // Actualizar usuario en Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': tier,
        'maxVehicles': maxVehicles,
        'isSubscriptionActive': true,
        'subscriptionExpiresAt': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'lastSubscriptionUpdate': DateTime.now().toIso8601String(),
      });

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

      print('Suscripción activada: $tier');
    } catch (e) {
      print('Error verificando compra: $e');
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
      print('Error registrando error de compra: $e');
    }
  }

  /// Callback cuando el stream se completa
  void _onPurchasesDone() {
    print('Stream de compras completado');
    _subscription?.cancel();
  }

  /// Callback para errores en el stream
  void _onPurchasesError(dynamic error) {
    print('Error en el stream de compras: $error');
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
      print('Error verificando suscripción: $e');
      return false;
    }
  }

  /// Cancelar suscripción (redirigir a Play Store)
  /// Nota: Las suscripciones se cancelan desde la configuración de Google Play
  void cancelSubscription() {
    print(
      'Para cancelar tu suscripción, ve a Google Play Store > Suscripciones',
    );
    // En una app real, aquí se abriría el link de suscripciones de Play Store
  }

  /// Limpiar recursos
  void dispose() {
    _subscription?.cancel();
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
        case starterMonthlyId:
          tier = 'starter';
          maxVehicles = 5;
          break;
        case smallMonthlyId:
          tier = 'small';
          maxVehicles = 10;
          break;
        case mediumMonthlyId:
          tier = 'medium';
          maxVehicles = 20;
          break;
        case largeMonthlyId:
          tier = 'large';
          maxVehicles = 35;
          break;
        case enterpriseMonthlyId:
          tier = 'enterprise';
          maxVehicles = 50;
          break;
        default:
          tier = 'free';
          maxVehicles = 1;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': tier,
        'maxVehicles': maxVehicles,
        'isSubscriptionActive': true,
        'subscriptionExpiresAt': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'lastSubscriptionUpdate': DateTime.now().toIso8601String(),
      });

      print('Compra simulada: $tier');
    } catch (e) {
      print('Error simulando compra: $e');
    }
  }
}
