import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../models/my_registration_model.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi calendario')),
      body: StreamBuilder<List<MyRegistration>>(
        stream: eventService.streamMyRegistrations(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final upcoming = snap.data!
              .where((r) =>
                  r.eventStartAt != null &&
                  r.eventStartAt!.isAfter(now))
              .toList();

          if (upcoming.isEmpty) {
            return const Center(
              child: Text('No tienes eventos próximos'),
            );
          }

          return ListView.builder(
            itemCount: upcoming.length,
            itemBuilder: (context, i) {
              final r = upcoming[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(r.eventTitle ?? 'Evento sin título'),
                  subtitle: Text(
                    '${_fmt(r.eventStartAt!)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
