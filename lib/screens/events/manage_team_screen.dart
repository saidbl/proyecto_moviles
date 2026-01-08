import 'package:flutter/material.dart';
import '../../services/event_service.dart';

class ManageTeamScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String currentUid; // Para saber que no puedo borrarme a mí mismo si soy el dueño

  const ManageTeamScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.currentUid,
  });

  @override
  State<ManageTeamScreen> createState() => _ManageTeamScreenState();
}

class _ManageTeamScreenState extends State<ManageTeamScreen> {
  final service = EventService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Equipo del Evento', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        label: const Text('Invitar'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gestionando: ${widget.eventTitle}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: service.streamEventTeam(widget.eventId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final team = snapshot.data ?? [];

                if (team.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_off_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Aún no hay equipo asignado'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: team.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = team[index];
                    final email = member['email'] ?? 'Sin correo';
                    final role = member['role'] ?? 'staff';
                    final uid = member['uid'];

                    // Mapeo visual de roles
                    final isCoOrganizer = role == 'co_organizer';
                    final roleLabel = isCoOrganizer ? 'Co-Organizador' : 'Staff (Escaner)';
                    final roleColor = isCoOrganizer ? Colors.purple : Colors.blueGrey;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: roleColor.withOpacity(0.1),
                        child: Icon(
                          isCoOrganizer ? Icons.edit_note : Icons.qr_code_scanner,
                          color: roleColor,
                        ),
                      ),
                      title: Text(email, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmRemoveMember(uid, email),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 1. DIÁLOGO DE INVITACIÓN
  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    String selectedRole = 'staff'; // Valor por defecto

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Invitar Colaborador'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ingresa el correo del usuario. Debe estar registrado en la App.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol y Permisos',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'staff',
                      child: Text('Staff (Solo Escanear)'),
                    ),
                    DropdownMenuItem(
                      value: 'co_organizer',
                      child: Text('Co-Organizador (Editar + Escanear)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => selectedRole = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (emailCtrl.text.trim().isEmpty) return;
                  
                  final email = emailCtrl.text.trim();
                  Navigator.pop(ctx); // Cerrar diálogo primero

                  _inviteUser(email, selectedRole);
                },
                child: const Text('Invitar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. LÓGICA DE INVITAR (Llamada al servicio)
  Future<void> _inviteUser(String email, String role) async {
    // Mostrar loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    try {
      await service.inviteUserToEvent(
        eventId: widget.eventId, 
        email: email, 
        role: role
      );
      
      if (mounted) {
        Navigator.pop(context); // Quitar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitación enviada a $email'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Quitar loading
        // Mostramos el error (ej: Usuario no encontrado)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. LÓGICA DE ELIMINAR
  void _confirmRemoveMember(String memberUid, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Seguro que deseas eliminar a $email del equipo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await service.removeMemberFromEvent(widget.eventId, memberUid);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Miembro eliminado')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}