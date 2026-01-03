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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mis eventos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: service.streamMyEvents(),
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }

          var events = snap.data ?? const [];

          if (snap.connectionState == ConnectionState.waiting &&
              events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (events.isEmpty) {
            return const _EmptyMyEventsState();
          }

          /// 🔹 ORDENAR POR FECHA DE TÉRMINO (MÁS RECIENTE PRIMERO)
          events = [...events]..sort((a, b) {
              final aDate = a.endAt;
              final bDate = b.endAt;

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;

              return bDate.compareTo(aDate); // DESC
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _MyEventCard(event: e),
              );
            },
          );
        },
      ),
    );
  }
}
class _MyEventCard extends StatefulWidget {
  final EventModel event;

  const _MyEventCard({required this.event});

  @override
  State<_MyEventCard> createState() => _MyEventCardState();
}

class _MyEventCardState extends State<_MyEventCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final theme = Theme.of(context);
    final hasImage = e.imageUrl != null && e.imageUrl!.isNotEmpty;

    return AnimatedScale(
      scale: pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🖼 IMAGEN DEL EVENTO
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: hasImage
                    ? Image.network(
                        e.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🏷 TÍTULO
                    Text(
                      e.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// 📍 INFO
                    Text(
                      '${e.category} • ${e.subcategory}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 🎛 ACCIONES
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionChip(
                          icon: Icons.visibility,
                          label: 'Detalle',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(
                                  event: e,
                                  canEdit: true,
                                ),
                              ),
                            );
                          },
                        ),
                        _ActionChip(
                          icon: Icons.edit,
                          label: 'Editar',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreateEditEventScreen(
                                  initial: e,
                                ),
                              ),
                            );
                          },
                        ),
                        _ActionChip(
                          icon: Icons.qr_code_scanner,
                          label: 'Escanear',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ScanAttendanceScreen(
                                  eventId: e.id,
                                ),
                              ),
                            );
                          },
                        ),
                        _ActionChip(
                          icon: Icons.people,
                          label: 'Asistentes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventAttendeesScreen(
                                  eventId: e.id,
                                  eventTitle: e.title,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _EmptyMyEventsState extends StatelessWidget {
  const _EmptyMyEventsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no has creado eventos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando crees un evento, aparecerá aquí para que puedas gestionarlo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar tus eventos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
