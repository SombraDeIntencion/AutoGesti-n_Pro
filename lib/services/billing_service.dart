import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/expense.dart';

class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtener el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  // Referencia a la colección de gastos (ruta correcta anidada por usuario)
  CollectionReference get _expensesCollection {
    final userId = currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');
    return _firestore
        .collection('autogestion_max')
        .doc('data')
        .collection('users')
        .doc(userId)
        .collection('expenses');
  }

  // Crear nuevo gasto
  Future<void> addExpense(Expense expense) async {
    try {
      await _expensesCollection.doc(expense.id).set(expense.toJson());
    } catch (e) {
      throw Exception('Error al agregar gasto: $e');
    }
  }

  // Actualizar gasto existente
  Future<void> updateExpense(Expense expense) async {
    try {
      final updatedExpense = expense.copyWith(updatedAt: DateTime.now());
      await _expensesCollection.doc(expense.id).update(updatedExpense.toJson());
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  // Eliminar gasto
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expensesCollection.doc(expenseId).delete();
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  // Obtener todos los gastos del usuario (Stream)
  Stream<List<Expense>> getExpenses() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final expenses = <Expense>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              if (data['id'] == null || data['id'] == '') {
                data['id'] = doc.id;
              }
              expenses.add(Expense.fromJson(data));
            } catch (e) {
              print('Error parsing expense ${doc.id}: $e');
            }
          }
          return expenses;
        });
  }

  // Obtener gastos de un vehículo específico
  Stream<List<Expense>> getExpensesByVehicle(String vehicleId) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _expensesCollection
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final expenses = <Expense>[];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              if (data['id'] == null || data['id'] == '') {
                data['id'] = doc.id;
              }
              expenses.add(Expense.fromJson(data));
            } catch (e) {
              print('Error parsing expense ${doc.id}: $e');
            }
          }
          return expenses;
        });
  }

  // Obtener gastos por período
  Stream<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _expensesCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Expense.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  // Obtener total de gastos por categoría en un período
  Future<Map<ExpenseCategory, double>> getExpensesByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (currentUserId == null) {
      return {};
    }

    try {
      final snapshot = await _expensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<ExpenseCategory, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        final expense = Expense.fromJson(doc.data() as Map<String, dynamic>);
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      return categoryTotals;
    } catch (e) {
      throw Exception('Error al obtener gastos por categoría: $e');
    }
  }

  // Obtener total de gastos por vehículo en un período
  Future<Map<String, double>> getExpensesByVehicleInPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (currentUserId == null) {
      return {};
    }

    try {
      final snapshot = await _expensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Map<String, double> vehicleTotals = {};

      for (var doc in snapshot.docs) {
        final expense = Expense.fromJson(doc.data() as Map<String, dynamic>);
        vehicleTotals[expense.vehicleName] =
            (vehicleTotals[expense.vehicleName] ?? 0) + expense.amount;
      }

      return vehicleTotals;
    } catch (e) {
      throw Exception('Error al obtener gastos por vehículo: $e');
    }
  }

  // Obtener total de gastos en un período
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    if (currentUserId == null) {
      return 0.0;
    }

    try {
      final snapshot = await _expensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final expense = Expense.fromJson(doc.data() as Map<String, dynamic>);
        total += expense.amount;
      }

      return total;
    } catch (e) {
      throw Exception('Error al obtener total de gastos: $e');
    }
  }

  // Obtener cantidad de vehículos activos (con gastos en el período)
  Future<int> getActiveVehiclesCount(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      final snapshot = await _expensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Set<String> uniqueVehicles = {};
      for (var doc in snapshot.docs) {
        final expense = Expense.fromJson(doc.data() as Map<String, dynamic>);
        uniqueVehicles.add(expense.vehicleId);
      }

      return uniqueVehicles.length;
    } catch (e) {
      throw Exception('Error al obtener vehículos activos: $e');
    }
  }

  // Obtener cantidad de categorías utilizadas en el período
  Future<int> getUsedCategoriesCount(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (currentUserId == null) {
      return 0;
    }

    try {
      final snapshot = await _expensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final Set<String> uniqueCategories = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        uniqueCategories.add(data['category'] ?? '');
      }

      return uniqueCategories.length;
    } catch (e) {
      throw Exception('Error al obtener categorías utilizadas: $e');
    }
  }

  // Obtener lista de gastos en un período específico
  Future<List<Expense>> getExpensesInPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final snapshot = await _expensesCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos del período: $e');
    }
  }

  // Verificar si el usuario tiene algún gasto registrado
  Future<bool> hasAnyExpenses() async {
    if (currentUserId == null) {
      return false;
    }

    try {
      final snapshot = await _expensesCollection.limit(1).get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========== FIREBASE STORAGE METHODS ==========

  /// Sube una foto del odómetro a Firebase Storage
  /// Retorna la URL de descarga del archivo
  Future<String> uploadMileagePhoto(
    File file,
    String userId,
    String expenseId,
  ) async {
    try {
      final String fileName =
          'mileage_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'expenses/$userId/$expenseId/$fileName';

      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'type': 'mileage'},
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir foto de odómetro: $e');
    }
  }

  /// Sube un recibo (foto, PDF o datos QR) a Firebase Storage
  /// Retorna la URL de descarga del archivo
  /// [receiptType] puede ser: 'photo', 'pdf', 'qr'
  Future<String> uploadReceipt(
    File file,
    String userId,
    String expenseId,
    String receiptType,
  ) async {
    try {
      // Determinar extensión y contentType según el tipo
      String extension;
      String contentType;

      switch (receiptType) {
        case 'photo':
        case 'qr':
          extension = 'jpg';
          contentType = 'image/jpeg';
          break;
        case 'pdf':
          extension = 'pdf';
          contentType = 'application/pdf';
          break;
        default:
          extension = 'jpg';
          contentType = 'image/jpeg';
      }

      final String fileName =
          'receipt_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String path =
          'autogestion_max/users/$userId/expenses/$expenseId/$fileName';

      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {'type': 'receipt', 'receiptType': receiptType},
        ),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error al subir recibo: $e');
    }
  }

  /// Elimina un archivo de Firebase Storage usando su URL
  Future<void> deleteFileByUrl(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // No lanzar error si el archivo no existe
      // print('Error al eliminar archivo: $e');
    }
  }

  /// Elimina todos los archivos asociados a un gasto
  Future<void> deleteExpenseFiles(String userId, String expenseId) async {
    try {
      final String path = 'expenses/$userId/$expenseId';
      final Reference ref = _storage.ref().child(path);

      // Listar todos los archivos en la carpeta del gasto
      final ListResult result = await ref.listAll();

      // Eliminar cada archivo
      for (final Reference fileRef in result.items) {
        await fileRef.delete();
      }
    } catch (e) {
      // print('Error al eliminar archivos del gasto: $e');
    }
  }
}
