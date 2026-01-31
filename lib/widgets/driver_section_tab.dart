import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/driver_section.dart';
import 'document_section_tab.dart';

class DriverSectionTab extends StatefulWidget {
  final DriverSection driver;
  final String vehicleId;
  final Function(DriverSection) onUpdate;

  const DriverSectionTab({
    super.key,
    required this.driver,
    required this.vehicleId,
    required this.onUpdate,
  });

  @override
  State<DriverSectionTab> createState() => _DriverSectionTabState();
}

class _DriverSectionTabState extends State<DriverSectionTab> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _phoneController = TextEditingController(text: widget.driver.phone);
    _emailController = TextEditingController(text: widget.driver.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del Conductor
          _buildSection(
            title: 'Información del Conductor',
            icon: Icons.person,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nombre Completo',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildPhoneField(
                  controller: _phoneController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveDriverInfo,
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text(
                      'Guardar Información',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shadowColor: const Color(0xFF06B6D4).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          // Sección de documentos (fotos, PDFs, notas compartidas)
          _DocumentsSection(
            driver: widget.driver,
            vehicleId: widget.vehicleId,
            onUpdate: widget.onUpdate,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF1E40AF)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E40AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: widget.driver.phone.isNotEmpty
            ? InkWell(
                onTap: () => _makePhoneCall(controller.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: const Color(0xFF25D366)),
                ),
              )
            : Icon(icon, color: const Color(0xFF1E40AF)),
        suffixIcon: widget.driver.phone.isNotEmpty
            ? Tooltip(
                message: 'Llamar',
                child: IconButton(
                  icon: const Icon(
                    Icons.phone_in_talk,
                    color: Color(0xFF25D366),
                  ),
                  onPressed: () => _makePhoneCall(controller.text),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E40AF), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay número de teléfono guardado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Limpiar el número de caracteres no numéricos excepto +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede realizar la llamada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al intentar llamar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveDriverInfo() {
    final updatedDriver = widget.driver.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    widget.onUpdate(updatedDriver);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Widget interno para manejar la sección de documentos
class _DocumentsSection extends StatelessWidget {
  final DriverSection driver;
  final String vehicleId;
  final Function(DriverSection) onUpdate;

  const _DocumentsSection({
    required this.driver,
    required this.vehicleId,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Convertimos DriverSection a DocumentSection temporalmente para usar el widget existente
    return DocumentSectionTab(
      title: 'Fotos (Licencia, Identificación)',
      section: driver,
      vehicleId: vehicleId,
      sectionName: 'conductor',
      onUpdate: (updatedSection) {
        // Actualizamos el DriverSection manteniendo la información del conductor
        final updatedDriver = DriverSection(
          name: driver.name,
          phone: driver.phone,
          email: driver.email,
          photos: updatedSection.photos,
          pdfs: updatedSection.pdfs,
          notes: updatedSection.notes,
        );
        onUpdate(updatedDriver);
      },
    );
  }
}
