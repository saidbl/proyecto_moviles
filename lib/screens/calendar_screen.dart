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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mi calendario',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
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
            return const _EmptyCalendarState();
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
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final events = grouped[day]!;

              return _DaySection(
                date: day,
                events: events,
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
class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<MyRegistration> events;

  const _DaySection({
    required this.date,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DayHeader(date: date),
          const SizedBox(height: 12),
          ...events.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EventCard(reg: r),
            ),
          ),
        ],
      ),
    );
  }
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

    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: date == today
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: date == today
                ? Theme.of(context).colorScheme.primary
                : Colors.black87,
          ),
        ),
      ],
    );
  }
}
class _EventCard extends StatefulWidget {
  final MyRegistration reg;

  const _EventCard({required this.reg});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final start = widget.reg.eventStartAt!;
    final theme = Theme.of(context);

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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ///  HORA
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  _fmtTime(start),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              ///  INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reg.eventTitle ??
                          'Evento sin título',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reg.eventLocation ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState();

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
              Icons.calendar_month_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes eventos próximos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando te registres en un evento futuro, aparecerá aquí.',
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
