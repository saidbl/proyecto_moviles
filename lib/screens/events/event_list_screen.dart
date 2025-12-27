import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  final bool isAdmin;
  final String currentUid;

  // ✅ NUEVO: controla si el rol puede registrarse
  final bool canRegister;

  const EventListScreen({
    super.key,
    required this.isAdmin,
    required this.currentUid,
    this.canRegister = true, // por defecto true (pero en Home lo apagas para admin)
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final service = EventService();

  @override
  Widget build(BuildContext context) {
    final stream =
        widget.isAdmin ? service.streamAllEventsAdmin() : service.streamAllActiveEvents();

    return StreamBuilder<List<EventModel>>(
      stream: stream,
      initialData: const [], // ✅ evita pantalla negra/loader eterno
      builder: (context, snap) {
        // ✅ si hay error (índice, permisos, etc.) NO se queda cargando infinito
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error cargando eventos:\n${snap.error}\n\n'
                'Si dice "requires an index", crea el índice en Firebase Console.\n'
                'Si dice "permission-denied", revisa Firestore Rules.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final events = snap.data ?? const [];

        // ✅ loader SOLO si realmente está esperando y todavía no hay nada
        if (snap.connectionState == ConnectionState.waiting && events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (events.isEmpty) {
          return Center(
            child: Text(
              widget.isAdmin
                  ? 'Aún no hay eventos creados.'
                  : 'Aún no hay eventos disponibles.',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Es stream; esto solo da feedback al usuario
            await Future.delayed(const Duration(milliseconds: 300));
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final e = events[i];
              final canEdit = widget.isAdmin || e.organizerId == widget.currentUid;

              return Card(
                child: ListTile(
                  title: Text(e.title),
                  subtitle: Text('${e.category} • ${e.subcategory}\n${e.location}'),
                  isThreeLine: true,
                  trailing: e.isActive
                      ? null
                      : const Icon(Icons.cancel, color: Colors.red),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(
                          event: e,
                          canEdit: canEdit,
                          // ✅ PASO 4 Sprint 3: solo alumno puede registrarse
                          canRegister: widget.canRegister,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
