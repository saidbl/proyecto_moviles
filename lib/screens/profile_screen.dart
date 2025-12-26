import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final userService = UserService();

  final nameCtrl = TextEditingController();
  final photoCtrl = TextEditingController();
  final interestsCtrl = TextEditingController();

  bool reminders = true;
  bool organizerAlerts = true;

  bool loading = false;
  String? error;

  bool _loadedOnce = false;
  String? _lastUid;

  List<String> _parseInterests(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    photoCtrl.dispose();
    interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser u) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final isStudent = u.role == 'estudiante';

      await userService.updateMe(
        name: nameCtrl.text,
        photoUrl: photoCtrl.text,
        // ✅ Solo alumno guarda intereses y prefs
        interests: isStudent ? _parseInterests(interestsCtrl.text) : null,
        notificationPrefs: isStudent
            ? {
                'reminders': reminders,
                'organizerAlerts': organizerAlerts,
              }
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser>(
      stream: userService.streamMe(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final u = snap.data!;
        final isStudent = u.role == 'estudiante';

        // ✅ BUGFIX: si cambió el usuario, recarga el form
        if (_lastUid != u.uid) {
          _lastUid = u.uid;
          _loadedOnce = false;
          error = null;
          loading = false;
        }

        // Cargar datos SOLO una vez por usuario
        if (!_loadedOnce) {
          nameCtrl.text = u.name;
          photoCtrl.text = u.photoUrl ?? '';
          interestsCtrl.text = u.interests.join(', ');
          reminders = (u.notificationPrefs['reminders'] ?? true) == true;
          organizerAlerts = (u.notificationPrefs['organizerAlerts'] ?? true) == true;
          _loadedOnce = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correo: ${u.email}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text('Rol: ${u.role}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Nombre',
                controller: nameCtrl,
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Foto (URL)',
                controller: photoCtrl,
                icon: Icons.image,
              ),
              const SizedBox(height: 16),

              // ✅ SOLO ALUMNO
              if (isStudent) ...[
                CustomTextField(
                  label: 'Intereses (separados por comas)',
                  controller: interestsCtrl,
                  icon: Icons.interests,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Preferencias de notificación',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorios'),
                  value: reminders,
                  onChanged: (v) => setState(() => reminders = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Avisos al organizador'),
                  value: organizerAlerts,
                  onChanged: (v) => setState(() => organizerAlerts = v),
                ),
              ],

              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 16),
              PrimaryButton(
                text: 'Guardar cambios',
                onPressed: () => _save(u),
                loading: loading,
              ),
            ],
          ),
        );
      },
    );
  }
}
