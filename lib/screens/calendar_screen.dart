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

          // 🔹 Eventos futuros
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

          // 🔹 Ordenar por fecha
          upcoming.sort(
            (a, b) => a.eventStartAt!.compareTo(b.eventStartAt!),
          );

          // 🔹 Agrupar por día
          final Map<DateTime, List<MyRegistration>> grouped = {};
          for (final r in upcoming) {
            final d = _onlyDate(r.eventStartAt!);
            grouped.putIfAbsent(d, () => []);
            grouped[d]!.add(r);
          }

          final days = grouped.keys.toList()..sort();

          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final events = grouped[day]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DayHeader(date: day),
                  ...events.map((r) => _EventTile(reg: r)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // 🔹 Normaliza fecha (sin hora)
  DateTime _onlyDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);
}

class _DayHeader extends StatelessWidget {
  final DateTime date;

  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'HOY';
    } else if (date == tomorrow) {
      label = 'MAÑANA';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: date == today
              ? Theme.of(context).colorScheme.primary
              : Colors.black87,
        ),
      ),
    );
  }
}
class _EventTile extends StatelessWidget {
  final MyRegistration reg;

  const _EventTile({required this.reg});

  @override
  Widget build(BuildContext context) {
    final start = reg.eventStartAt!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(
          reg.eventTitle ?? 'Evento sin título',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Hora: ${_fmtTime(start)}',
        ),
      ),
    );
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
