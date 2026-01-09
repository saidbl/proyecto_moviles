import 'package:flutter/material.dart';
import 'admin_create_organizer_screen.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Registrar organizador'),
            subtitle: const Text('Crear cuentas para organizadores'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCreateOrganizerScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
