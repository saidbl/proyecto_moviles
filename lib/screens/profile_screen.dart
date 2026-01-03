import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    interestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(AppUser u) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(u.uid)
          .child('profile.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await userService.updateMe(photoUrl: url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (_) {
      setState(() => error = 'Error al subir la imagen');
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
        interests: isStudent ? _parseInterests(interestsCtrl.text) : null,
        notificationPrefs: isStudent
            ? {
                'reminders': reminders,
                'organizerAlerts': organizerAlerts,
              }
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<AppUser>(
      stream: userService.streamMe(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final u = snap.data!;
        final isStudent = u.role == 'estudiante';

        if (_lastUid != u.uid) {
          _lastUid = u.uid;
          _loadedOnce = false;
          error = null;
        }

        if (!_loadedOnce) {
          nameCtrl.text = u.name;
          interestsCtrl.text = u.interests.join(', ');
          reminders = (u.notificationPrefs['reminders'] ?? true) == true;
          organizerAlerts =
              (u.notificationPrefs['organizerAlerts'] ?? true) == true;
          _loadedOnce = true;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      /// 👤 HEADER PERFIL
                      _ProfileHeader(
                        user: u,
                        loading: loading,
                        onChangePhoto: () => _pickAndUploadPhoto(u),
                      ),

                      const SizedBox(height: 28),

                      /// 📄 INFO PERSONAL
                      _SectionCard(
                        title: 'Información personal',
                        children: [
                          _InfoLine('Correo', u.email),
                          _InfoLine('Rol', u.role),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Nombre',
                            controller: nameCtrl,
                            icon: Icons.person_outline,
                          ),
                        ],
                      ),

                      if (isStudent) ...[
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: 'Preferencias',
                          children: [
                            CustomTextField(
                              label:
                                  'Intereses (separados por comas)',
                              controller: interestsCtrl,
                              icon: Icons.interests_outlined,
                            ),
                            const SizedBox(height: 12),
                            _SwitchTile(
                              title: 'Recordatorios',
                              value: reminders,
                              onChanged: (v) =>
                                  setState(() => reminders = v),
                            ),
                            _SwitchTile(
                              title: 'Avisos del organizador',
                              value: organizerAlerts,
                              onChanged: (v) =>
                                  setState(
                                      () => organizerAlerts = v),
                            ),
                          ],
                        ),
                      ],

                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          style: TextStyle(
                              color: Colors.red.shade700),
                        ),
                      ],

                      const SizedBox(height: 28),

                      PrimaryButton(
                        text: 'Guardar cambios',
                        loading: loading,
                        onPressed: () => _save(u),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
class _ProfileHeader extends StatelessWidget {
  final AppUser user;
  final bool loading;
  final VoidCallback onChangePhoto;

  const _ProfileHeader({
    required this.user,
    required this.loading,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.indigo.shade200,
              backgroundImage:
                  (user.photoUrl != null &&
                          user.photoUrl!.isNotEmpty)
                      ? NetworkImage(user.photoUrl!)
                      : null,
              child: (user.photoUrl == null ||
                      user.photoUrl!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            Material(
              shape: const CircleBorder(),
              color: Colors.indigo,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: loading ? null : onChangePhoto,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
