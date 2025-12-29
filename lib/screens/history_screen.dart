import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../models/my_registration_model.dart';
import '../models/user_model.dart';
import 'certificates/certificate_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de eventos'),
      ),
      body: StreamBuilder<List<MyRegistration>>(
        stream: eventService.streamMyRegistrations(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 Filtrar solo eventos TERMINADOS
          final history = snap.data!
              .where(
                (r) => r.eventEndAt != null && r.eventEndAt!.isBefore(now),
              )
              .toList();

          if (history.isEmpty) {
            return const Center(
              child: Text('Aún no tienes eventos en tu historial'),
            );
          }

          // 🔹 Necesitamos datos del alumno para la constancia
          return StreamBuilder<AppUser>(
            stream: UserService().streamMe(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final u = userSnap.data!;

              return ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, i) {
                  final r = history[i];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(
                        r.eventTitle ?? 'Evento sin título',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Finalizó el ${_fmt(r.eventEndAt!)}',
                      ),
                      trailing: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      onTap: () {
                        // 📄 ABRIR CONSTANCIA
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(
                              reg: r,
                              studentName: u.name,
                              studentEmail: u.email,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
