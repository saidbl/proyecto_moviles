import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_comments_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final bool canEdit;
  final bool canRegister;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.canEdit,
    this.canRegister = true,
  });

  @override
  Widget build(BuildContext context) {
    final service = EventService();

    return StreamBuilder<EventModel>(
      stream: service.streamEventById(event.id),
      builder: (context, snap) {
        if (snap.hasError) {
          return _ErrorView(error: snap.error.toString());
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final e = snap.data!;
        final remaining = e.remaining;
        final isTablet = MediaQuery.of(context).size.width >= 700;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: const Text('Detalle del evento'),
            centerTitle: true,
            actions: [
              if (canEdit)
                IconButton(
                  tooltip: 'Cancelar evento',
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: () async {
                    await service.cancelEvent(e.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 16,
                  vertical: 20,
                ),
                children: [
                  _Header(event: e),
                  const SizedBox(height: 20),

                  isTablet
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _GeneralInfoCard(event: e)),
                            const SizedBox(width: 16),
                            Expanded(child: _CapacityCard(event: e)),
                          ],
                        )
                      : Column(
                          children: [
                            _GeneralInfoCard(event: e),
                            const SizedBox(height: 16),
                            _CapacityCard(event: e),
                          ],
                        ),

                  const SizedBox(height: 16),
                  _DescriptionCard(description: e.description),

                  const SizedBox(height: 16),
                  _CommentsButton(event: e),

                  const SizedBox(height: 24),
                  if (e.hasEnded)
                    const Center(
                      child: Text(
                        '⛔ Este evento ya finalizó',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),


                  if (!e.isActive)
                    const Center(
                      child: Text(
                        '⚠️ Evento cancelado',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                  if (canRegister && e.isActive && !e.hasStarted) ...[
                    const SizedBox(height: 20),
                    _RegisterButton(event: e, service: service),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
class _Header extends StatelessWidget {
  final EventModel event;
  const _Header({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${event.category} • ${event.subcategory}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
class _GeneralInfoCard extends StatelessWidget {
  final EventModel event;
  const _GeneralInfoCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Información general',
      children: [
        _InfoRow(Icons.place, 'Lugar', event.location),
        _InfoRow(Icons.schedule, 'Inicio', _fmtDateTime(event.startAt)),
        _InfoRow(Icons.schedule_outlined, 'Fin', _fmtDateTime(event.endAt)),
        _InfoRow(Icons.person, 'Organizador', event.organizerName),
      ],
    );
  }
}
class _CapacityCard extends StatelessWidget {
  final EventModel event;
  const _CapacityCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final remaining = event.remaining;

    return _InfoCard(
      title: 'Cupo',
      children: [
        _InfoRow(Icons.groups, 'Capacidad', '${event.capacity}'),
        _InfoRow(Icons.check_circle, 'Registrados', '${event.registrationsCount}'),
        Row(
          children: [
            Icon(
              Icons.event_seat,
              color: remaining == 0 ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              'Disponibles: $remaining',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: remaining == 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class _DescriptionCard extends StatelessWidget {
  final String description;
  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Descripción',
      children: [
        Text(description),
      ],
    );
  }
}
class _CommentsButton extends StatelessWidget {
  final EventModel event;
  const _CommentsButton({required this.event});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.comment),
      label: const Text('Ver comentarios'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo.shade50,
        foregroundColor: Colors.indigo,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventCommentsScreen(
              eventId: event.id,
              eventTitle: event.title,
              canComment: false,
            ),
          ),
        );
      },
    );
  }
}
class _RegisterButton extends StatelessWidget {
  final EventModel event;
  final EventService service;

  const _RegisterButton({required this.event, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: service.streamAmIRegistered(event.id),
      initialData: false,
      builder: (context, snap) {
        final registered = snap.data == true;
        if (registered) {
          Future.microtask(
            () => service.ensureRegistrationProjectionIfNeeded(event),
          );
        }

        final disabled = event.isFull && !registered;
        
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor:
                registered ? Colors.redAccent : Colors.indigo,
          ),
          onPressed: disabled
              ? null
              : () async {
                  if (registered) {
                    await service.unregisterFromEvent(event.id);
                  } else {
                    await service.registerToEvent(event.id);
                  }
                },
          icon: Icon(
            registered ? Icons.close : Icons.check,
            color: Colors.white,
          ),
          label: Text(
            registered
                ? 'Cancelar registro'
                : (event.isFull ? 'Evento lleno' : 'Registrarme'),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }
}
class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            ...children.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.indigo),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del evento')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            error,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
String _fmtDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} '
      '${two(d.hour)}:${two(d.minute)}';
}
