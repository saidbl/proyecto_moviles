import 'package:flutter/material.dart';
import '../../models/my_registration_model.dart';
import '../../services/event_service.dart';
import 'my_attendance_qr_screen.dart';

class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = EventService();

    return StreamBuilder<List<MyRegistration>>(
      stream: service.streamMyRegistrations(),
      initialData: const [],
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error cargando tus registros:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final regs = snap.data ?? const [];

        if (snap.connectionState == ConnectionState.waiting && regs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (regs.isEmpty) {
          return const Center(child: Text('Aún no estás registrado en ningún evento.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: regs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = regs[i];

            final start = r.eventStartAt == null ? '' : _fmt(r.eventStartAt!);
            final subtitle = [
              if ((r.eventLocation ?? '').isNotEmpty) r.eventLocation!,
              if (start.isNotEmpty) start,
            ].join(' • ');

            return Card(
              child: ListTile(
                title: Text(r.eventTitle ?? 'Evento (${r.eventId})'),
                subtitle: Text(subtitle.isEmpty ? 'ID: ${r.eventId}' : subtitle),
                trailing: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    // 🔳 QR DEL ALUMNO
    TextButton.icon(
      icon: const Icon(Icons.qr_code),
      label: const Text('Mi QR'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyAttendanceQrScreen(
              eventId: r.eventId,
            ),
          ),
        );
      },
    ),

    // ❌ CANCELAR REGISTRO (LO QUE YA TENÍAS)
    TextButton.icon(
      onPressed: () async {
        try {
          await service.unregisterFromEvent(r.eventId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro cancelado')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.close),
      label: const Text('Cancelar'),
    ),
  ],
),

              ),
            );
          },
        );
      },
    );
  }

  static String _fmt(DateTime d) {
    final two = (int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
