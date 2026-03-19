import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

/// Servicio para gestionar empleados que trabajan en la misma cuenta
class EmployeeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _currentEmployeeIdKey = 'current_employee_id';
  static const String _currentEmployeeNameKey = 'current_employee_name';
  static const String _roleSelectedKey =
      'role_selected'; // Indica si ya seleccionó rol (gerente o empleado)

  /// Obtener el usuario (gerente) actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Colección de empleados del usuario
  CollectionReference? _employeesCollection(String userId) {
    return _firestore
        .collection('autogestion_max')
        .doc('data')
        .collection('users')
        .doc(userId)
        .collection('employees');
  }

  /// Obtener todos los empleados
  Stream<List<Employee>> getEmployees() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _employeesCollection(userId)!.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Employee.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Agregar nuevo empleado
  Future<bool> addEmployee(String employeeId, String name) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      // Verificar que el ID no exista
      final existing = await _employeesCollection(
        userId,
      )!.doc(employeeId).get();
      if (existing.exists) {
        throw Exception('El número de empleado ya existe');
      }

      final employee = Employee(
        id: employeeId,
        name: name,
        createdAt: DateTime.now(),
      );

      await _employeesCollection(
        userId,
      )!.doc(employeeId).set(employee.toJson());
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar si un empleado existe y está activo
  Future<Employee?> getEmployee(String employeeId) async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _employeesCollection(userId)!.doc(employeeId).get();
      if (!doc.exists) return null;

      final employee = Employee.fromJson(doc.data() as Map<String, dynamic>);
      return employee.isActive ? employee : null;
    } catch (e) {
      return null;
    }
  }

  /// Desactivar empleado
  Future<void> deactivateEmployee(String employeeId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _employeesCollection(
      userId,
    )!.doc(employeeId).update({'isActive': false});
  }

  /// Activar empleado
  Future<void> activateEmployee(String employeeId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _employeesCollection(
      userId,
    )!.doc(employeeId).update({'isActive': true});
  }

  /// Eliminar empleado permanentemente
  Future<void> deleteEmployee(String employeeId) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Si el empleado que se está eliminando es el actual, limpiar sesión
    final currentEmployee = await getCurrentEmployee();
    if (currentEmployee?.id == employeeId) {
      await clearCurrentEmployee();
    }

    await _employeesCollection(userId)!.doc(employeeId).delete();
  }

  /// Guardar empleado actual en sesión local
  Future<void> setCurrentEmployee(Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentEmployeeIdKey, employee.id);
    await prefs.setString(_currentEmployeeNameKey, employee.name);
    await prefs.setBool(
      _roleSelectedKey,
      true,
    ); // Indicar que ya seleccionó rol
  }

  /// Obtener empleado actual de la sesión local
  Future<Employee?> getCurrentEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentEmployeeIdKey);
    final name = prefs.getString(_currentEmployeeNameKey);

    if (id == null || name == null) return null;

    // Verificar que el empleado siga activo
    final employee = await getEmployee(id);
    if (employee == null) {
      // Empleado desactivado o eliminado - limpiar sesión
      await clearCurrentEmployee();
      return null;
    }

    return employee;
  }

  /// Limpiar empleado actual (cuando el gerente decide continuar como gerente)
  Future<void> clearCurrentEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentEmployeeIdKey);
    await prefs.remove(_currentEmployeeNameKey);
    await prefs.setBool(
      _roleSelectedKey,
      true,
    ); // Indicar que eligió continuar como gerente
  }

  /// Verificar si hay un empleado seleccionado
  Future<bool> hasCurrentEmployee() async {
    final employee = await getCurrentEmployee();
    return employee != null;
  }

  /// Verificar si ya ha seleccionado un rol (gerente o empleado)
  /// Retorna true si ya hizo la selección, false si es la primera vez
  Future<bool> hasSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_roleSelectedKey) ?? false;
  }

  /// Limpiar toda la sesión (para cerrar sesión completamente)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentEmployeeIdKey);
    await prefs.remove(_currentEmployeeNameKey);
    await prefs.remove(_roleSelectedKey);
  }
}
