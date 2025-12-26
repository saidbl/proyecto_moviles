import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;
  final bool canEdit; // admin o dueño

  const EventDetailScreen({super.key, required this.event, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final service = EventService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del evento'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Cancelar evento',
              onPressed: () async {
                await service.cancelEvent(event.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${event.category} • ${event.subcategory}'),
            const SizedBox(height: 8),
            Text('Lugar: ${event.location}'),
            const SizedBox(height: 8),
            Text('Inicio: ${event.startAt}'),
            Text('Fin: ${event.endAt}'),
            const SizedBox(height: 8),
            Text('Cupo máximo: ${event.capacity}'),
            const SizedBox(height: 8),
            Text('Organizador: ${event.organizerName}'),
            const SizedBox(height: 16),
            Text(event.description),
            const SizedBox(height: 24),
            if (!event.isActive)
              const Text('⚠️ Evento cancelado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
