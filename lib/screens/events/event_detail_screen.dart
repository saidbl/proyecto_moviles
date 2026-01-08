import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_comments_screen.dart';

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
        final isTablet = MediaQuery.of(context).size.width >= 700;
        final hasImage = e.imageUrl != null && e.imageUrl!.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: CustomScrollView(
            slivers: [
              /// 🖼 HEADER VISUAL (SOLO IMAGEN)
              SliverAppBar(
                expandedHeight: hasImage ? 260 : 140,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                // ELIMINADO: actions: [ ... IconButton ... ] 
                // Ya no permitimos cancelar desde aquí.
                
                flexibleSpace: FlexibleSpaceBar(
                  background: hasImage
                      ? Image.network(
                          e.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey.shade200),
                ),
              ),

              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 16,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🏷 CATEGORÍA
                          Text(
                            '${e.category} • ${e.subcategory}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),

                          /// 🏷 TÍTULO
                          Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 20),

                          isTablet
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child:
                                            _GeneralInfoCard(event: e)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                        child:
                                            _CapacityCard(event: e)),
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

                          /// 💬 COMENTARIOS — SOLO ORGANIZADOR
                          if (canEdit) ...[
                            const SizedBox(height: 16),
                            _CommentsButton(event: e),
                          ],

                          const SizedBox(height: 24),

                          if (e.hasEnded)
                            const _StatusMessage(
                              icon: Icons.event_busy,
                              text: 'Este evento ya finalizó',
                              color: Colors.red,
                            ),

                          if (!e.isActive)
                            const _StatusMessage(
                              icon: Icons.cancel,
                              text: 'Evento cancelado',
                              color: Colors.red,
                            ),

                          /// 📝 REGISTRO — SOLO ALUMNO
                          if (!canEdit &&
                              canRegister &&
                              e.isActive &&
                              !e.hasStarted) ...[
                            const SizedBox(height: 20),
                            _RegisterButton(
                                event: e, service: service),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _TagLine extends StatelessWidget {
  final EventModel event;
  const _TagLine({required this.event});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${event.category} • ${event.subcategory}',
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
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
        _InfoRow(
            Icons.check_circle, 'Registrados',
            '${event.registrationsCount}'),
        Row(
          children: [
            Icon(Icons.event_seat,
                color: remaining == 0 ? Colors.red : Colors.green),
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
        Text(
          description,
          style: const TextStyle(height: 1.5),
        ),
      ],
    );
  }
}
class _CommentsButton extends StatelessWidget {
  final EventModel event;
  const _CommentsButton({required this.event});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.comment),
      label: const Text('Ver comentarios'),
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
        
        // 1. SI YA ESTÁS REGISTRADO: Mostrar solo mensaje informativo
        if (registered) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ya te has registrado al evento.\nPuedes verlo desde "Mis registros".',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 2. SI NO ESTÁS REGISTRADO: Mostrar botón de registro normal
        final disabled = event.isFull;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo, // Color normal de registro
            ),
            onPressed: disabled
                ? null
                : () async {
                    await service.registerToEvent(event.id);
                  },
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text(
              event.isFull ? 'Evento lleno' : 'Registrarme',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600)),
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
          child: Text(error, textAlign: TextAlign.center),
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
