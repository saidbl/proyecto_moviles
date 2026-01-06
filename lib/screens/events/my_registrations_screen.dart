import 'package:flutter/material.dart';
import '../../models/my_registration_model.dart';
import '../../services/event_service.dart';
import 'my_attendance_qr_screen.dart';

class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

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
      body: StreamBuilder<List<MyRegistration>>(
        stream: service.streamMyRegistrations(),
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }

          final regs = snap.data ?? const [];

          if (snap.connectionState == ConnectionState.waiting &&
              regs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (regs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: regs.length,
            itemBuilder: (context, i) {
              final r = regs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _RegistrationCard(
                  registration: r,
                  service: service,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class _RegistrationCard extends StatefulWidget {
  final MyRegistration registration;
  final EventService service;

  const _RegistrationCard({
    required this.registration,
    required this.service,
  });

  @override
  State<_RegistrationCard> createState() => _RegistrationCardState();
}

class _RegistrationCardState extends State<_RegistrationCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.registration;
    final theme = Theme.of(context);

    final start = r.eventStartAt == null ? null : _fmt(r.eventStartAt!);

    final subtitle = [
      if ((r.eventLocation ?? '').isNotEmpty) r.eventLocation!,
      if (start != null) start,
    ].join(' • ');

    return AnimatedScale(
      scale: pressed ? 0.98 : 1,
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
                blurRadius: 30,
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
                r.eventTitle ?? 'Evento (${r.eventId})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle.isEmpty ? 'ID: ${r.eventId}' : subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 16),

              /// 🔘 ÁREA DINÁMICA (ESTADO Y BOTONES)
              StreamBuilder(
                stream: widget.service.streamEventById(r.eventId),
                builder: (context, snapshot) {
                  // Valores por defecto
                  bool isActive = true;
                  bool eventExists = true;

                  if (snapshot.hasError) {
                    // Si da error, asumimos que fue borrado (Hard Delete)
                    eventExists = false;
                    isActive = false;
                  } else if (snapshot.hasData) {
                    isActive = snapshot.data!.isActive;
                  }

                  // ¿Debemos mostrar la UI de cancelado/ocultar?
                  final isHideAction = !isActive || !eventExists;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      if (isHideAction)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 20, color: Colors.red.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  eventExists
                                      ? 'Este evento ha sido cancelado por el organizador.'
                                      : 'Este evento ha sido eliminado.',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 🔘 2. BOTONES DE ACCIÓN
                      Row(
                        children: [
                          // Botón QR (Solo visible si el evento está activo)
                          if (!isHideAction) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Mi QR'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MyAttendanceQrScreen(
                                        eventId: r.eventId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Botón Dinámico (Cancelar vs Ocultar)
                          Expanded(
                            child: TextButton.icon(
                              icon: Icon(isHideAction
                                  ? Icons.visibility_off_outlined
                                  : Icons.close),
                              label: Text(
                                  isHideAction ? 'Ocultar' : 'Cancelar'),
                              style: TextButton.styleFrom(
                                foregroundColor: isHideAction
                                    ? Colors.grey.shade700
                                    : Colors.redAccent,
                                backgroundColor: isHideAction
                                    ? Colors.grey.shade100
                                    : null,
                              ),
                              onPressed: () async {
                                try {
                                  await widget.service
                                      .unregisterFromEvent(r.eventId);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(isHideAction
                                            ? 'Registro eliminado de tu lista'
                                            : 'Tu asistencia ha sido cancelada'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(e
                                            .toString()
                                            .replaceFirst(
                                                'Exception: ', '')),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.event_available_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes registros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando te registres en un evento, aparecerá aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
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
    final theme = Theme.of(context);

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
              'Ocurrió un problema',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
String _fmt(DateTime d) {
  final two = (int x) => x.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} '
      '${two(d.hour)}:${two(d.minute)}';
}
