import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'create_edit_event_screen.dart';
import 'event_detail_screen.dart';
import 'scan_attendance_screen.dart';
import 'event_attendees_screen.dart';

class MyEventsScreen extends StatelessWidget {
  final String currentUid;
  const MyEventsScreen({super.key, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final service = EventService();

    return StreamBuilder<List<EventModel>>(
      stream: service.streamMyEvents(),
      initialData: const [],
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error cargando tus eventos:\n${snap.error}\n\n'
                'Si dice "requires an index", crea el índice en Firebase Console.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final events = snap.data ?? const [];

        if (snap.connectionState == ConnectionState.waiting && events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (events.isEmpty) {
          return const Center(child: Text('Aún no has creado eventos.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final e = events[i];

            return Card(
              child: ListTile(
                title: Text(e.title),
                subtitle: Text(
                  '${e.category} • ${e.subcategory}\n${e.location}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'detail') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(
                            event: e,
                            canEdit: true,
                          ),
                        ),
                      );
                    } 
                    else if (v == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateEditEventScreen(initial: e),
                        ),
                      );
                    } 
                    else if (v == 'scan') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanAttendanceScreen(
                            eventId: e.id,
                          ),
                        ),
                      );
                    }else if (v == 'attendees') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EventAttendeesScreen(
        eventId: e.id,
        eventTitle: e.title,
      ),
    ),
  );
}

                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'detail',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Ver detalle'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'scan',
                      child: ListTile(
                        leading: Icon(Icons.qr_code_scanner),
                        title: Text('Escanear asistencia'),
                      ),
                    ),
                    PopupMenuItem(
  value: 'attendees',
  child: ListTile(
    leading: Icon(Icons.people),
    title: Text('Ver asistentes'),
  ),
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
}
