import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../services/user_service.dart';
import '../models/my_registration_model.dart';
import '../models/user_model.dart';
import 'certificates/certificate_screen.dart';
import 'events/event_comments_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
          'Historial de eventos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<MyRegistration>>(
        stream: eventService.streamMyRegistrations(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snap.data!
              .where(
                (r) =>
                    r.eventEndAt != null &&
                    r.eventEndAt!.isBefore(now),
              )
              .toList();

          if (history.isEmpty) {
            return const _EmptyHistoryState();
          }

          return StreamBuilder<AppUser>(
            stream: UserService().streamMe(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final u = userSnap.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, i) {
                  final r = history[i];
                  final attended = r.attended == true;

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 20),
                    child: _HistoryCard(
                      reg: r,
                      user: u,
                      attended: attended,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
class _HistoryCard extends StatefulWidget {
  final MyRegistration reg;
  final AppUser user;
  final bool attended;

  const _HistoryCard({
    required this.reg,
    required this.user,
    required this.attended,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.reg;
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
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🏷 TÍTULO
              Text(
                r.eventTitle ?? 'Evento sin título',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              /// 📅 FECHA
              Text(
                'Finalizó el ${_fmt(r.eventEndAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 16),

              /// 🎓 ESTADO
              Row(
                children: [
                  Icon(
                    widget.attended
                        ? Icons.verified
                        : Icons.info_outline,
                    size: 18,
                    color: widget.attended
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.attended
                        ? 'Asistencia registrada'
                        : 'No se registró asistencia',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /// 🔘 ACCIONES (SOLO SI ASISTIÓ)
              if (widget.attended)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon:
                            const Icon(Icons.comment),
                        label:
                            const Text('Comentarios'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EventCommentsScreen(
                                eventId: r.eventId,
                                eventTitle:
                                    r.eventTitle ??
                                        'Evento',
                                canComment: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                            Icons.picture_as_pdf),
                        label:
                            const Text('Constancia'),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.redAccent,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CertificateScreen(
                                reg: r,
                                studentName:
                                    widget.user.name,
                                studentEmail:
                                    widget.user.email,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

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
              Icons.history_edu_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes historial',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando finalices un evento, aparecerá aquí junto con su constancia.',
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
