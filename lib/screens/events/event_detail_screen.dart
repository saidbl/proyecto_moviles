import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event; // viene de la lista
  final bool canEdit; // admin o dueño
  final bool canRegister; // ✅ nuevo: solo alumno

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.canEdit,
    this.canRegister = true,
  });

  @override
  Widget build(BuildContext context) {
    final service = EventService();

    // ✅ escuchamos el evento en tiempo real
    return StreamBuilder<EventModel>(
      stream: service.streamEventById(event.id),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle del evento')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error:\n${snap.error}', textAlign: TextAlign.center),
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final e = snap.data!;
        final remaining = e.remaining;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del evento'),
            actions: [
              if (canEdit)
                IconButton(
                  tooltip: 'Cancelar evento',
                  onPressed: () async {
                    await service.cancelEvent(e.id);
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
                Text(
                  e.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${e.category} • ${e.subcategory}'),
                const SizedBox(height: 8),
                Text('Lugar: ${e.location}'),
                const SizedBox(height: 8),
                Text('Inicio: ${e.startAt}'),
                Text('Fin: ${e.endAt}'),
                const SizedBox(height: 8),

                // ✅ Cupo en vivo
                Text('Cupo máximo: ${e.capacity}'),
                Text('Registrados: ${e.registrationsCount}'),
                Text(
                  'Lugares disponibles: $remaining',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remaining == 0 ? Colors.red : Colors.green,
                  ),
                ),

                const SizedBox(height: 8),
                Text('Organizador: ${e.organizerName}'),
                const SizedBox(height: 16),
                Text(e.description),
                const SizedBox(height: 24),

                if (!e.isActive)
                  const Text(
                    '⚠️ Evento cancelado',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),

                // ✅ Botón alumno: registrarse / cancelar registro (en vivo)
                if (canRegister && e.isActive) ...[
                  const SizedBox(height: 18),
                  StreamBuilder<bool>(
                    stream: service.streamAmIRegistered(e.id),
                    initialData: false,
                    builder: (context, regSnap) {
                      final amIRegistered = regSnap.data == true;

                      // ✅ BACKFILL: si ya estaba registrado y su doc es viejo,
                      // agregamos userId/eventTitle/... con merge.
                      // Usamos Future.microtask para evitar loops de build.
                      if (amIRegistered) {
                        Future.microtask(() => service.ensureRegistrationProjectionIfNeeded(e));
                      }

                      final disabled = e.isFull && !amIRegistered;

                      return ElevatedButton.icon(
                        onPressed: disabled
                            ? null
                            : () async {
                                try {
                                  if (amIRegistered) {
                                    await service.unregisterFromEvent(e.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Registro cancelado')),
                                      );
                                    }
                                  } else {
                                    await service.registerToEvent(e.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Registro exitoso')),
                                      );
                                    }
                                  }
                                } catch (err) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          err.toString().replaceFirst('Exception: ', ''),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(amIRegistered ? Icons.close : Icons.check),
                        label: Text(
                          amIRegistered
                              ? 'Cancelar registro'
                              : (e.isFull ? 'Evento lleno' : 'Registrarme'),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
