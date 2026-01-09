import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminCreateOrganizerScreen extends StatefulWidget {
  const AdminCreateOrganizerScreen({super.key});

  @override
  State<AdminCreateOrganizerScreen> createState() =>
      _AdminCreateOrganizerScreenState();
}

class _AdminCreateOrganizerScreenState
    extends State<AdminCreateOrganizerScreen> {
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool loading = false;
  String? error;

  final adminService = AdminService();

  @override
  void dispose() {
    emailCtrl.dispose();
    nameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await adminService.createOrganizer(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        name: nameCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizador creado correctamente')),
      );

      emailCtrl.clear();
      nameCtrl.clear();
      passwordCtrl.clear();
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar organizador')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                icon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Correo',
                icon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                icon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: loading ? null : _create,
              icon: const Icon(Icons.person_add),
              label: loading
                  ? const CircularProgressIndicator()
                  : const Text('Crear organizador'),
            ),
          ],
        ),
      ),
    );
  }
}
