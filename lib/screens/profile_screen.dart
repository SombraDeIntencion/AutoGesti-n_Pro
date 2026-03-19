import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/vehicle_service.dart';
import '../services/employee_service.dart';
import '../services/biometric_service.dart';
import '../models/employee.dart';
import '../utils/app_theme.dart';
import '../models/checklist_item.dart';
import '../l10n/app_localizations.dart';
import 'privacy_policy_screen.dart';
import 'employee_management_screen.dart';
import 'employee_selection_screen.dart';
import 'export_reports_screen.dart';
import 'language/language_selection_screen.dart';
import 'auth/login_screen.dart';
import '../services/locale_service.dart';

/// Pantalla de perfil y configuración del usuario
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final VehicleService _vehicleService = VehicleService();
  final EmployeeService _employeeService = EmployeeService();
  final BiometricService _biometricService = BiometricService();
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _profilePhotoUrl;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _appVersion = '';

  // Cache para evitar llamadas repetitivas a getCurrentEmployee
  Future<Employee?>? _currentEmployeeFuture;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmployee();
    _loadProfilePhoto();
    _checkBiometric();
    _loadAppVersion();
  }

  void _loadCurrentEmployee() {
    if (mounted) {
      setState(() {
        _currentEmployeeFuture = _employeeService.getCurrentEmployee();
      });
    }
  }

  /// Verificar disponibilidad y estado de biometría
  Future<void> _checkBiometric() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricEnabled(userId);

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  /// Cargar versión de la app desde el paquete
  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version}+${info.buildNumber}';
      });
    }
  }

  /// Activar/Desactivar autenticación biométrica
  Future<void> _toggleBiometric(bool enable) async {
    final l10n = AppLocalizations.of(context);
    final userId = _authService.currentUser?.uid;
    final userEmail = _authService.currentUser?.email;
    if (userId == null || userEmail == null) return;

    if (enable) {
      // Verificar que hay biométricos enrollados
      final hasEnrolled = await _biometricService.hasEnrolledBiometrics();
      if (!hasEnrolled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.biometricNotEnrolled),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 🔒 SEGURIDAD: Ya no pedimos contraseña - Firebase Auth maneja tokens
      // Solicitar autenticación biométrica para habilitar
      final result = await _biometricService.enableBiometric(
        userId,
        userEmail,
        l10n.authenticateToEnable,
      );

      if (mounted) {
        setState(() {
          _biometricEnabled = result.success;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? l10n.biometricEnabled
                  : '${l10n.biometricError}: ${result.errorMessage ?? "Error desconocido"}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      // Deshabilitar biometría
      await _biometricService.disableBiometric();

      if (mounted) {
        setState(() {
          _biometricEnabled = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.biometricDisabled),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  /// Cargar foto de perfil del gerente desde Firestore
  Future<void> _loadProfilePhoto() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _profilePhotoUrl = doc.data()?['photoUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  /// Seleccionar y subir foto de perfil
  Future<void> _updateProfilePhoto() async {
    final l10n = AppLocalizations.of(context);

    // Mostrar opciones: cámara o galería
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profilePhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  l10n.deletePhoto,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, null),
              ),
          ],
        ),
      ),
    );

    if (source == null && _profilePhotoUrl != null) {
      // Eliminar foto
      await _deleteProfilePhoto();
      return;
    }

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      // Subir a Firebase Storage
      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception(l10n.userNotAuthenticated);

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      // Guardar URL en Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'photoUrl': downloadUrl,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _profilePhotoUrl = downloadUrl;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorUpdatingPhoto}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Eliminar foto de perfil
  Future<void> _deleteProfilePhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      setState(() => _isUploadingPhoto = true);

      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception(l10n.userNotAuthenticated);

      // Eliminar de Storage
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$userId.jpg');
        await ref.delete();
      } catch (e) {
        debugPrint('Error deleting from storage: $e');
      }

      // Eliminar URL de Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoUrl': FieldValue.delete(),
      });

      if (!mounted) return;

      setState(() {
        _profilePhotoUrl = null;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Verificar contraseña del gerente antes de cambiar de empleado a gerente
  Future<void> _verifyManagerPassword() async {
    if (!mounted) return;

    final controller = TextEditingController();
    String? password;

    // Esperar al siguiente frame para evitar problemas con el context
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.managerVerification),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.enterPasswordToContinueAsManager,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) =>
                    Navigator.pop(dialogContext, controller.text),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(l10n.verify),
            ),
          ],
        );
      },
    );

    // Esperar a que el diálogo se cierre completamente antes de disponer el controller
    await Future.delayed(const Duration(milliseconds: 100));
    controller.dispose();

    if (password == null || password.isEmpty) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Reautenticar al usuario con su contraseña
      final user = _authService.currentUser;
      if (user?.email == null) {
        throw Exception('No se pudo verificar el usuario');
      }

      await user!.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );

      // Contraseña correcta - limpiar empleado y continuar
      await _employeeService.clearCurrentEmployee();
      _loadCurrentEmployee();

      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.nowWorkingAsManager),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _isLoading = false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'wrong-password'
                ? l10n.incorrectPassword
                : l10n.verificationError,
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Mostrar diálogo de confirmación para eliminar cuenta
  Future<void> _showDeleteAccountDialog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountWarning),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.thisWillDelete,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(l10n.yourUserAccount),
            Text(l10n.allYourVehicles),
            Text(l10n.allPhotosAndDocuments),
            Text(l10n.allMaintenanceHistory),
            const SizedBox(height: 16),
            Text(
              l10n.areYouSure,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.yesDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _showPasswordDialog();
    }
  }

  /// Mostrar diálogo para ingresar contraseña
  Future<void> _showPasswordDialog() async {
    _passwordController.clear();

    final l10n = AppLocalizations.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmIdentity),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.forSecurityEnterPassword),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.password,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _passwordController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (password != null && password.isNotEmpty && mounted) {
      _deleteAccount(password);
    }
  }

  /// Eliminar cuenta
  Future<void> _deleteAccount(String password) async {
    setState(() => _isLoading = true);

    try {
      final l10n = AppLocalizations.of(context);
      await _authService.deleteAccount(password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        // El AuthGate detectará que no hay usuario y mostrará LoginScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Descargar datos del usuario
  Future<void> _downloadUserData() async {
    setState(() => _isLoading = true);

    // Capturar l10n y messenger ANTES de cualquier async
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Mostrar indicador de progreso
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Recopilando y descargando todos tus archivos...'),
            ],
          ),
          duration: const Duration(minutes: 5),
          backgroundColor: const Color(0xFF17A2B8),
        ),
      );
    }

    try {
      final user = _authService.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Obtener vehículos del usuario
      final vehiclesStream = _vehicleService.getVehicles();
      final vehicles = await vehiclesStream.first;

      // Crear un reporte completo en texto legible
      final StringBuffer report = StringBuffer();

      report.writeln('═══════════════════════════════════════════');
      report.writeln('    MIS DATOS - AUTOGESTIÓN MAX');
      report.writeln('═══════════════════════════════════════════');
      report.writeln('');
      report.writeln(
        '📅 Fecha de exportación: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
      report.writeln('');

      // Información del usuario
      report.writeln('👤 INFORMACIÓN DE LA CUENTA');
      report.writeln('───────────────────────────────────────────');
      report.writeln('Email: ${user.email}');
      report.writeln('Email verificado: ${user.emailVerified ? "Sí" : "No"}');
      report.writeln('ID de usuario: ${user.uid}');
      report.writeln('');

      // Información de vehículos
      report.writeln('🚗 MIS VEHÍCULOS (${vehicles.length})');
      report.writeln('───────────────────────────────────────────');

      if (vehicles.isEmpty) {
        report.writeln('No hay vehículos registrados');
      } else {
        for (var i = 0; i < vehicles.length; i++) {
          final v = vehicles[i];
          report.writeln('');
          report.writeln('Vehículo ${i + 1}: ${v.name}');
          report.writeln('  • Marca: ${v.brand}');
          report.writeln('  • Modelo: ${v.model}');
          report.writeln('  • Año: ${v.year}');
          report.writeln('  • Placa: ${v.plate}');
          if (v.photo != null) {
            report.writeln('  • Foto: Disponible');
          }

          // Seguro
          report.writeln('');
          report.writeln('  📋 SEGURO:');
          if (v.insurance.expirationDate != null) {
            report.writeln(
              '    - Vencimiento: ${v.insurance.expirationDate!.day}/${v.insurance.expirationDate!.month}/${v.insurance.expirationDate!.year}',
            );
          }
          if (v.insurance.notes.isNotEmpty) {
            report.writeln('    - Notas: ${v.insurance.notes}');
          }
          if (v.insurance.photos.isNotEmpty) {
            report.writeln(
              '    - Fotos: ${v.insurance.photos.length} archivo(s)',
            );
          }
          if (v.insurance.pdfs.isNotEmpty) {
            report.writeln(
              '    - PDFs: ${v.insurance.pdfs.length} documento(s)',
            );
          }

          // Conductor
          report.writeln('');
          report.writeln('  👨‍💼 CONDUCTOR:');
          if (v.driver.name.isNotEmpty) {
            report.writeln('    - Nombre: ${v.driver.name}');
          }
          if (v.driver.phone.isNotEmpty) {
            report.writeln('    - Teléfono: ${v.driver.phone}');
          }
          if (v.driver.email.isNotEmpty) {
            report.writeln('    - Email: ${v.driver.email}');
          }
          if (v.driver.expirationDate != null) {
            report.writeln(
              '    - Vencimiento licencia: ${v.driver.expirationDate!.day}/${v.driver.expirationDate!.month}/${v.driver.expirationDate!.year}',
            );
          }
          if (v.driver.notes.isNotEmpty) {
            report.writeln('    - Notas: ${v.driver.notes}');
          }
          if (v.driver.photos.isNotEmpty) {
            report.writeln('    - Fotos: ${v.driver.photos.length} archivo(s)');
          }
          if (v.driver.pdfs.isNotEmpty) {
            report.writeln('    - PDFs: ${v.driver.pdfs.length} documento(s)');
          }

          // Contrato
          report.writeln('');
          report.writeln('  📄 CONTRATO:');
          if (v.contract.expirationDate != null) {
            report.writeln(
              '    - Vencimiento: ${v.contract.expirationDate!.day}/${v.contract.expirationDate!.month}/${v.contract.expirationDate!.year}',
            );
          }
          if (v.contract.notes.isNotEmpty) {
            report.writeln('    - Notas: ${v.contract.notes}');
          }
          if (v.contract.photos.isNotEmpty) {
            report.writeln(
              '    - Fotos: ${v.contract.photos.length} archivo(s)',
            );
          }
          if (v.contract.pdfs.isNotEmpty) {
            report.writeln(
              '    - PDFs: ${v.contract.pdfs.length} documento(s)',
            );
          }

          // Tarjeta de circulación
          report.writeln('');
          report.writeln('  🎫 TARJETA DE CIRCULACIÓN:');
          if (v.circulationCard.expirationDate != null) {
            report.writeln(
              '    - Vencimiento: ${v.circulationCard.expirationDate!.day}/${v.circulationCard.expirationDate!.month}/${v.circulationCard.expirationDate!.year}',
            );
          }
          if (v.circulationCard.notes.isNotEmpty) {
            report.writeln('    - Notas: ${v.circulationCard.notes}');
          }
          if (v.circulationCard.photos.isNotEmpty) {
            report.writeln(
              '    - Fotos: ${v.circulationCard.photos.length} archivo(s)',
            );
          }
          if (v.circulationCard.pdfs.isNotEmpty) {
            report.writeln(
              '    - PDFs: ${v.circulationCard.pdfs.length} documento(s)',
            );
          }

          // Mantenimiento - Checklist
          report.writeln('');
          report.writeln('  🔧 MANTENIMIENTO - CHECKLIST:');
          if (v.maintenance.checklist.isNotEmpty) {
            report.writeln(
              '    - Total de items: ${v.maintenance.checklist.length}',
            );
            for (var item in v.maintenance.checklist) {
              final statusIcon = item.status == ChecklistStatus.ok
                  ? '✓'
                  : (item.status == ChecklistStatus.attention ? '⚠' : '⚠️');
              report.writeln('    $statusIcon ${item.name}');
            }
          } else {
            report.writeln('    - No hay checklist configurado');
          }

          // Secciones de mantenimiento
          if (v.maintenance.sections.isNotEmpty) {
            report.writeln('');
            report.writeln('  🛠️ SECCIONES DE MANTENIMIENTO:');
            for (var section in v.maintenance.sections) {
              final itemCount = section.items.length;
              if (itemCount > 0) {
                report.writeln('');
                report.writeln('    📌 ${section.name.toUpperCase()}:');
                report.writeln('      - Total de items: $itemCount');
                for (var item in section.items) {
                  report.writeln(
                    '      • ${item.date.day}/${item.date.month}/${item.date.year}',
                  );
                  if (item.what.isNotEmpty) {
                    report.writeln('        Qué: ${item.what}');
                  }
                  if (item.currentKm > 0) {
                    report.writeln('        Kilometraje: ${item.currentKm} km');
                  }
                  if (item.nextChangeKm > 0) {
                    report.writeln(
                      '        Próximo cambio: ${item.nextChangeKm} km',
                    );
                  }
                  final totalPhotos =
                      item.problemPhotos.length +
                      item.oldPartsPhotos.length +
                      item.newPartsPhotos.length +
                      item.afterPhotos.length;
                  if (totalPhotos > 0) {
                    report.writeln('        Fotos: $totalPhotos archivo(s)');
                  }
                }
              }
            }
          }

          // Fotos de inspección
          if (v.maintenance.inspectionPhotos.isNotEmpty) {
            report.writeln('');
            report.writeln(
              '  📸 FOTOS DE INSPECCIÓN: ${v.maintenance.inspectionPhotos.length} foto(s)',
            );
          }

          // Historial de inspecciones
          if (v.maintenance.inspectionHistory.isNotEmpty) {
            report.writeln('');
            report.writeln(
              '  📋 HISTORIAL DE INSPECCIONES (${v.maintenance.inspectionHistory.length}):',
            );
            for (var inspection in v.maintenance.inspectionHistory) {
              report.writeln(
                '    • ${inspection.date.day}/${inspection.date.month}/${inspection.date.year}',
              );
              if (inspection.notes.isNotEmpty) {
                report.writeln('      Notas: ${inspection.notes}');
              }
              report.writeln(
                '      Items: ${inspection.checklist.length} | Fotos: ${inspection.inspectionPhotos.length}',
              );
            }
          }

          report.writeln('');
          report.writeln('───────────────────────────────────────────');
        }
      }

      report.writeln('');
      report.writeln('═══════════════════════════════════════════');
      report.writeln('   Generado por AutoGestión Max v1.0.0');
      report.writeln('═══════════════════════════════════════════');

      // Ahora descargamos todos los archivos y creamos un ZIP
      final archive = Archive();
      final storage = FirebaseStorage.instance;

      // Agregar el reporte de texto como archivo
      final reportBytes = report.toString().codeUnits;
      archive.addFile(
        ArchiveFile('mis_datos.txt', reportBytes.length, reportBytes),
      );

      // Recopilar todas las URLs de archivos
      final List<String> allFileUrls = [];
      final Map<String, String> fileNames = {}; // URL -> nombre descriptivo

      int fileCounter = 0;

      for (var i = 0; i < vehicles.length; i++) {
        final v = vehicles[i];
        final vehicleName = '${v.name.replaceAll(' ', '_')}_${i + 1}';

        // Foto del vehículo
        if (v.photo != null) {
          allFileUrls.add(v.photo!);
          fileNames[v.photo!] = '$vehicleName/vehiculo_foto.jpg';
        }

        // Seguro
        for (var j = 0; j < v.insurance.photos.length; j++) {
          allFileUrls.add(v.insurance.photos[j]);
          fileNames[v.insurance.photos[j]] =
              '$vehicleName/seguro/foto_${j + 1}.jpg';
        }
        for (var j = 0; j < v.insurance.pdfs.length; j++) {
          allFileUrls.add(v.insurance.pdfs[j]);
          fileNames[v.insurance.pdfs[j]] =
              '$vehicleName/seguro/documento_${j + 1}.pdf';
        }
        // Historial de seguro
        for (var h = 0; h < v.insurance.history.length; h++) {
          final historyItem = v.insurance.history[h];
          for (var j = 0; j < historyItem.photos.length; j++) {
            allFileUrls.add(historyItem.photos[j]);
            fileNames[historyItem.photos[j]] =
                '$vehicleName/seguro/historial_${h + 1}/foto_${j + 1}.jpg';
          }
          for (var j = 0; j < historyItem.pdfs.length; j++) {
            allFileUrls.add(historyItem.pdfs[j]);
            fileNames[historyItem.pdfs[j]] =
                '$vehicleName/seguro/historial_${h + 1}/documento_${j + 1}.pdf';
          }
        }

        // Conductor
        for (var j = 0; j < v.driver.photos.length; j++) {
          allFileUrls.add(v.driver.photos[j]);
          fileNames[v.driver.photos[j]] =
              '$vehicleName/conductor/foto_${j + 1}.jpg';
        }
        for (var j = 0; j < v.driver.pdfs.length; j++) {
          allFileUrls.add(v.driver.pdfs[j]);
          fileNames[v.driver.pdfs[j]] =
              '$vehicleName/conductor/documento_${j + 1}.pdf';
        }
        // Historial de conductor
        for (var h = 0; h < v.driver.history.length; h++) {
          final historyItem = v.driver.history[h];
          for (var j = 0; j < historyItem.photos.length; j++) {
            allFileUrls.add(historyItem.photos[j]);
            fileNames[historyItem.photos[j]] =
                '$vehicleName/conductor/historial_${h + 1}/foto_${j + 1}.jpg';
          }
          for (var j = 0; j < historyItem.pdfs.length; j++) {
            allFileUrls.add(historyItem.pdfs[j]);
            fileNames[historyItem.pdfs[j]] =
                '$vehicleName/conductor/historial_${h + 1}/documento_${j + 1}.pdf';
          }
        }

        // Contrato
        for (var j = 0; j < v.contract.photos.length; j++) {
          allFileUrls.add(v.contract.photos[j]);
          fileNames[v.contract.photos[j]] =
              '$vehicleName/contrato/foto_${j + 1}.jpg';
        }
        for (var j = 0; j < v.contract.pdfs.length; j++) {
          allFileUrls.add(v.contract.pdfs[j]);
          fileNames[v.contract.pdfs[j]] =
              '$vehicleName/contrato/documento_${j + 1}.pdf';
        }
        // Historial de contrato
        for (var h = 0; h < v.contract.history.length; h++) {
          final historyItem = v.contract.history[h];
          for (var j = 0; j < historyItem.photos.length; j++) {
            allFileUrls.add(historyItem.photos[j]);
            fileNames[historyItem.photos[j]] =
                '$vehicleName/contrato/historial_${h + 1}/foto_${j + 1}.jpg';
          }
          for (var j = 0; j < historyItem.pdfs.length; j++) {
            allFileUrls.add(historyItem.pdfs[j]);
            fileNames[historyItem.pdfs[j]] =
                '$vehicleName/contrato/historial_${h + 1}/documento_${j + 1}.pdf';
          }
        }

        // Tarjeta de circulación
        for (var j = 0; j < v.circulationCard.photos.length; j++) {
          allFileUrls.add(v.circulationCard.photos[j]);
          fileNames[v.circulationCard.photos[j]] =
              '$vehicleName/tarjeta_circulacion/foto_${j + 1}.jpg';
        }
        for (var j = 0; j < v.circulationCard.pdfs.length; j++) {
          allFileUrls.add(v.circulationCard.pdfs[j]);
          fileNames[v.circulationCard.pdfs[j]] =
              '$vehicleName/tarjeta_circulacion/documento_${j + 1}.pdf';
        }
        // Historial de tarjeta
        for (var h = 0; h < v.circulationCard.history.length; h++) {
          final historyItem = v.circulationCard.history[h];
          for (var j = 0; j < historyItem.photos.length; j++) {
            allFileUrls.add(historyItem.photos[j]);
            fileNames[historyItem.photos[j]] =
                '$vehicleName/tarjeta_circulacion/historial_${h + 1}/foto_${j + 1}.jpg';
          }
          for (var j = 0; j < historyItem.pdfs.length; j++) {
            allFileUrls.add(historyItem.pdfs[j]);
            fileNames[historyItem.pdfs[j]] =
                '$vehicleName/tarjeta_circulacion/historial_${h + 1}/documento_${j + 1}.pdf';
          }
        }

        // Fotos de mantenimiento (inspección)
        for (var j = 0; j < v.maintenance.inspectionPhotos.length; j++) {
          allFileUrls.add(v.maintenance.inspectionPhotos[j]);
          fileNames[v.maintenance.inspectionPhotos[j]] =
              '$vehicleName/mantenimiento/inspeccion_foto_${j + 1}.jpg';
        }

        // Historial de inspecciones
        for (var h = 0; h < v.maintenance.inspectionHistory.length; h++) {
          final inspection = v.maintenance.inspectionHistory[h];
          for (var j = 0; j < inspection.inspectionPhotos.length; j++) {
            allFileUrls.add(inspection.inspectionPhotos[j]);
            fileNames[inspection.inspectionPhotos[j]] =
                '$vehicleName/mantenimiento/historial_inspeccion_${h + 1}/foto_${j + 1}.jpg';
          }
        }

        // Secciones de mantenimiento (ítems con fotos)
        for (var section in v.maintenance.sections) {
          final sectionName = section.name.replaceAll(' ', '_').toLowerCase();
          for (var itemIdx = 0; itemIdx < section.items.length; itemIdx++) {
            final item = section.items[itemIdx];

            // Fotos de problemas
            for (var j = 0; j < item.problemPhotos.length; j++) {
              allFileUrls.add(item.problemPhotos[j]);
              fileNames[item.problemPhotos[j]] =
                  '$vehicleName/mantenimiento/$sectionName/item_${itemIdx + 1}/problema_${j + 1}.jpg';
            }

            // Fotos de partes viejas
            for (var j = 0; j < item.oldPartsPhotos.length; j++) {
              allFileUrls.add(item.oldPartsPhotos[j]);
              fileNames[item.oldPartsPhotos[j]] =
                  '$vehicleName/mantenimiento/$sectionName/item_${itemIdx + 1}/partes_viejas_${j + 1}.jpg';
            }

            // Fotos de partes nuevas
            for (var j = 0; j < item.newPartsPhotos.length; j++) {
              allFileUrls.add(item.newPartsPhotos[j]);
              fileNames[item.newPartsPhotos[j]] =
                  '$vehicleName/mantenimiento/$sectionName/item_${itemIdx + 1}/partes_nuevas_${j + 1}.jpg';
            }

            // Fotos después
            for (var j = 0; j < item.afterPhotos.length; j++) {
              allFileUrls.add(item.afterPhotos[j]);
              fileNames[item.afterPhotos[j]] =
                  '$vehicleName/mantenimiento/$sectionName/item_${itemIdx + 1}/despues_${j + 1}.jpg';
            }
          }
        }
      }

      // Descargar todos los archivos y agregarlos al ZIP
      int downloadedCount = 0;
      int failedCount = 0;

      for (final url in allFileUrls) {
        try {
          final ref = storage.refFromURL(url);
          final bytes = await ref.getData();

          if (bytes != null) {
            final fileName = fileNames[url] ?? 'archivo_${fileCounter++}';
            archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
            downloadedCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          debugPrint('Error descargando archivo: $url - $e');
        }
      }

      // Comprimir el archivo ZIP
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        throw Exception('No se pudo crear el archivo ZIP');
      }

      // Guardar en directorio temporal primero
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final zipFileName = 'MisDatos_AutoGestion_$timestamp.zip';
      final tempZipFile = File('${tempDir.path}/$zipFileName');
      await tempZipFile.writeAsBytes(zipBytes);

      // Copiar a Downloads público
      if (Platform.isAndroid) {
        final downloadsPath = '/storage/emulated/0/Download/Reportes';
        final downloadsDir = Directory(downloadsPath);

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final finalFile = File('$downloadsPath/$zipFileName');
        await tempZipFile.copy(finalFile.path);

        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '✅ Datos descargados: $downloadedCount archivos\\nGuardado en Download/Reportes/$zipFileName${failedCount > 0 ? '\\n⚠️ $failedCount archivos no pudieron descargarse' : ''}',
              ),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        // Para iOS u otras plataformas, usar directorio de documentos
        final appDocDir = await getApplicationDocumentsDirectory();
        final finalFile = File('${appDocDir.path}/$zipFileName');
        await tempZipFile.copy(finalFile.path);

        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '✅ Datos descargados: $downloadedCount archivos\\nGuardado en: ${finalFile.path}${failedCount > 0 ? '\\n⚠️ $failedCount archivos no pudieron descargarse' : ''}',
              ),
              backgroundColor: const Color(0xFF22C55E),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorExportingData('')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Cerrar sesión
  Future<void> _signOut() async {
    // Capturar l10n y messenger ANTES de cualquier async
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // 🔒 SEGURIDAD: Verificar si tiene biometría habilitada
      final userId = _authService.currentUser?.uid;
      final hasBiometric = userId != null
          ? await _biometricService.isBiometricEnabled(userId)
          : false;

      if (hasBiometric) {
        // Solo cerrar sesión local (mantener Firebase Auth para biometría)
        await _authService.signOutLocal();
        debugPrint('🔒 Sesión local cerrada - Biometría activa');

        // Navegar directamente al LoginScreen para permitir login con huella
        if (mounted) {
          messenger.clearSnackBars();

          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        // Cerrar sesión completa
        await _authService.signOut();
        debugPrint('🔒 Sesión completa cerrada');

        // El AuthGate detectará el cambio y mostrará LoginScreen automáticamente
        if (mounted) {
          navigator.popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorSigningOut('')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Mostrar diálogo para cambiar nombre
  Future<void> _showChangeNameDialog(String currentName) async {
    final nameController = TextEditingController(text: currentName);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changeName),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.newName,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    // Esperar a que la animación del diálogo termine antes de dispose
    await Future.delayed(const Duration(milliseconds: 300));
    nameController.dispose();

    if (newName != null && newName != currentName && mounted) {
      try {
        await _authService.updateProfile(displayName: newName);
        if (mounted) {
          setState(() {}); // Refresh UI with new name
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.nameUpdated),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.errorUpdatingName),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Mostrar diálogo para cambiar contraseña
  Future<void> _showChangePasswordDialog() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.changePasswordTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.passwordMinLength,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.changeButton),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      await _changePassword();
    }
  }

  /// Cambiar contraseña
  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.completeAllFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordMin6Chars),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordsDontMatch),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.passwordChangedSuccessfully}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.errorChangingPassword;
        if (e.toString().contains('wrong-password') ||
            e.toString().contains('contraseña actual incorrecta')) {
          errorMessage = l10n.currentPasswordIncorrect;
        } else if (e.toString().contains('requires-recent-login')) {
          errorMessage = l10n.requiresRecentLoginMessage;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email ?? '';
    final displayName = user?.displayName ?? 'Usuario';
    final emailVerified = user?.emailVerified ?? false;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Banner de sesión actual de empleado
                FutureBuilder<Employee?>(
                  future: _currentEmployeeFuture,
                  builder: (context, snapshot) {
                    final currentEmployee = snapshot.data;

                    return Card(
                      color: currentEmployee != null
                          ? Colors.blue[50]
                          : Colors.green[50],
                      child: ListTile(
                        leading: Icon(
                          currentEmployee != null
                              ? Icons.badge
                              : Icons.admin_panel_settings,
                          color: currentEmployee != null
                              ? Colors.blue[700]
                              : Colors.green[700],
                        ),
                        title: Text(
                          currentEmployee != null
                              ? '${l10n.workingAs}: ${currentEmployee.name}'
                              : l10n.workingAsManager,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentEmployee != null
                                ? Colors.blue[900]
                                : Colors.green[900],
                          ),
                        ),
                        subtitle: Text(
                          currentEmployee != null
                              ? 'ID: ${currentEmployee.id}'
                              : l10n.fullAccess,
                          style: TextStyle(
                            color: currentEmployee != null
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                        trailing: TextButton(
                          onPressed: currentEmployee != null
                              ? _verifyManagerPassword
                              : () async {
                                  // Si es gerente, ofrecer seleccionar empleado
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EmployeeSelectionScreen(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _loadCurrentEmployee(); // Actualizar cache
                                  }
                                },
                          child: Text(
                            currentEmployee != null ? l10n.change : l10n.select,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Encabezado del perfil
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar con foto o inicial
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryBlue,
                              backgroundImage: _profilePhotoUrl != null
                                  ? NetworkImage(_profilePhotoUrl!)
                                  : null,
                              child: _profilePhotoUrl == null
                                  ? Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            // Botón de cámara - Más visible
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: FutureBuilder<Employee?>(
                                future: _currentEmployeeFuture,
                                builder: (context, snapshot) {
                                  // Solo mostrar botón si es gerente
                                  final isEmployee = snapshot.data != null;
                                  if (isEmployee) {
                                    return const SizedBox.shrink();
                                  }

                                  return GestureDetector(
                                    onTap: _isUploadingPhoto
                                        ? null
                                        : _updateProfilePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: _isUploadingPhoto
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.camera_alt,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Nombre editable (solo para gerente)
                        FutureBuilder<Employee?>(
                          future: _currentEmployeeFuture,
                          builder: (context, snapshot) {
                            final isEmployee = snapshot.data != null;
                            return GestureDetector(
                              onTap: isEmployee
                                  ? null
                                  : () => _showChangeNameDialog(displayName),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                  ),
                                  if (!isEmployee) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        // Solo mostrar email si es gerente
                        FutureBuilder<Employee?>(
                          future: _currentEmployeeFuture,
                          builder: (context, snapshot) {
                            final isEmployee = snapshot.data != null;
                            if (isEmployee) {
                              return Text(
                                l10n.employeeMode,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.blue[600]),
                              );
                            }
                            return Text(
                              email,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        if (emailVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.emailVerified,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sección de información
                Text(
                  l10n.profile,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Opciones de perfil
                FutureBuilder<Employee?>(
                  future: _currentEmployeeFuture,
                  builder: (context, snapshot) {
                    final isEmployee = snapshot.data != null;

                    return Card(
                      child: Column(
                        children: [
                          // Email solo visible para gerente
                          if (!isEmployee) ...[
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: Text(l10n.emailLabel),
                              subtitle: Text(email),
                            ),
                            const Divider(height: 1),
                          ],
                          // Cambiar contraseña solo para gerente
                          if (!isEmployee) ...[
                            ListTile(
                              leading: const Icon(Icons.shield),
                              title: Text(l10n.changePasswordTitle),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showChangePasswordDialog,
                            ),
                            const Divider(height: 1),
                          ],
                          // Gestionar empleados solo para gerente
                          if (!isEmployee) ...[
                            ListTile(
                              leading: const Icon(Icons.people),
                              title: Text(l10n.manageEmployees),
                              subtitle: Text(l10n.manageEmployeesSubtitle),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EmployeeManagementScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                          ],
                          ListTile(
                            leading: const Icon(Icons.swap_horiz),
                            title: Text(l10n.changeEmployeeLabel),
                            subtitle: Text(
                              snapshot.data != null
                                  ? '${l10n.currentLabel}: ${snapshot.data!.name}'
                                  : l10n.workingAsManager,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EmployeeSelectionScreen(),
                                ),
                              );
                              if (result == true && mounted) {
                                // Actualizar cache para reflejar el cambio
                                _loadCurrentEmployee();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Sección de configuración
                Text(
                  l10n.languageSettings,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                FutureBuilder<Employee?>(
                  future: _currentEmployeeFuture,
                  builder: (context, snapshot) {
                    final isEmployee = snapshot.data != null;

                    return Card(
                      child: Column(
                        children: [
                          // Solo mostrar idioma si es gerente
                          if (!isEmployee) ...[
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: Text(l10n.languageLabel),
                              subtitle: Consumer<LocaleService>(
                                builder: (context, localeService, child) {
                                  final localeInfo =
                                      localeService.currentLocaleInfo;
                                  return Text(
                                    '${localeInfo.flag} ${localeInfo.nativeName}',
                                  );
                                },
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LanguageSelectionScreen(
                                          isInitialSetup: false,
                                        ),
                                  ),
                                );
                                // No es necesario setState aquí porque Consumer se actualiza automáticamente
                              },
                            ),
                            const Divider(height: 1),
                          ],
                          // Opción de biometría solo para gerente
                          if (!isEmployee && _biometricAvailable) ...[
                            SwitchListTile(
                              secondary: const Icon(Icons.fingerprint),
                              title: Text(l10n.biometricAuth),
                              subtitle: Text(l10n.biometricSubtitle),
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                            ),
                          ],
                          // Mostrar mensaje si no está disponible la biometría
                          if (!isEmployee && !_biometricAvailable) ...[
                            ListTile(
                              leading: const Icon(
                                Icons.fingerprint,
                                color: Colors.grey,
                              ),
                              title: Text(l10n.biometricAuth),
                              subtitle: Text(
                                l10n.biometricNotAvailable,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              enabled: false,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Sección de configuración de seguridad
                FutureBuilder<Employee?>(
                  future: _currentEmployeeFuture,
                  builder: (context, snapshot) {
                    final isEmployee = snapshot.data != null;

                    // Solo mostrar si es gerente y tiene biometría habilitada
                    if (isEmployee || !_biometricAvailable) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.securitySettings,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.fingerprint,
                              color: _biometricEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            title: Text(l10n.authenticateBiometric),
                            subtitle: Text(
                              _biometricEnabled
                                  ? l10n.biometricEnabled
                                  : l10n.biometricDisabled,
                            ),
                            trailing: Icon(
                              _biometricEnabled
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _biometricEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                // Sección de privacidad y datos
                Text(
                  l10n.privacyAndData,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                FutureBuilder<Employee?>(
                  future: _currentEmployeeFuture,
                  builder: (context, snapshot) {
                    final isEmployee = snapshot.data != null;

                    return Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: Text(l10n.privacyPolicy),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          // Solo mostrar exportar reportes si es gerente
                          if (!isEmployee) ...[
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFF0088CC),
                              ),
                              title: Text(l10n.exportReportsPDF),
                              subtitle: Text(l10n.generateVehicleReports),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ExportReportsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                          // Solo mostrar descargar datos si es gerente
                          if (!isEmployee) ...[
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.download),
                              title: Text(l10n.downloadMyData),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _downloadUserData,
                            ),
                          ],
                          // Solo mostrar eliminar cuenta si es gerente
                          if (!isEmployee) ...[
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_forever,
                                color: Colors.red,
                              ),
                              title: Text(
                                l10n.deleteMyAccount,
                                style: const TextStyle(color: Colors.red),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.red,
                              ),
                              onTap: _showDeleteAccountDialog,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Botón cerrar sesión
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),

                // Información de la app
                Center(
                  child: Column(
                    children: [
                      Text(
                        'AutoGestión Max',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v$_appVersion',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
