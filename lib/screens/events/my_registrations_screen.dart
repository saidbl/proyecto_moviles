import 'package:flutter/material.dart';
import '../../models/my_registration_model.dart';
import '../../services/event_service.dart';
import 'my_attendance_qr_screen.dart';

// Enum para ordenamiento
enum SortOption { dateDesc, dateAsc, titleAsc }

class MyRegistrationsScreen extends StatefulWidget {
  const MyRegistrationsScreen({super.key});

  @override
  State<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends State<MyRegistrationsScreen> {
  final service = EventService();

  // Configuración Sección ACTIVOS
  SortOption _sortActive = SortOption.dateAsc; // Próximos primero

  // Configuración Sección HISTORIAL
  SortOption _sortHistory = SortOption.dateDesc; // Más recientes primero
  
  //  FILTROS DE VISIBILIDAD (Estado)
  bool _showFinished = true;  
  bool _showCancelled = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mis registros',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: StreamBuilder<List<MyRegistration>>(
        stream: service.streamMyRegistrations(),
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }

          final allRegs = snap.data ?? [];

          if (snap.connectionState == ConnectionState.waiting && allRegs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allRegs.isEmpty) {
            return const _EmptyState();
          }

          // ====================================================
          //  LÓGICA DE SEPARACIÓN (Basada en Fecha)
          // ====================================================
          final now = DateTime.now();
          
          final activeList = <MyRegistration>[];
          final historyList = <MyRegistration>[];

          for (var r in allRegs) {
            // Clasificación temporal: ¿Ya pasó la fecha fin?
            final isFinishedTime = r.eventEndAt != null && r.eventEndAt!.isBefore(now);
            
            if (isFinishedTime) {
              historyList.add(r);
            } else {
              activeList.add(r);
            }
          }

          // ORDENAMIENTO ACTIVOS
          activeList.sort((a, b) {
            final dateA = a.eventStartAt ?? DateTime(0);
            final dateB = b.eventStartAt ?? DateTime(0);
            switch (_sortActive) {
              case SortOption.dateAsc: return dateA.compareTo(dateB);
              case SortOption.dateDesc: return dateB.compareTo(dateA);
              case SortOption.titleAsc: return (a.eventTitle ?? '').compareTo(b.eventTitle ?? '');
            }
          });

          // ORDENAMIENTO HISTORIAL
          historyList.sort((a, b) {
            final dateA = a.eventStartAt ?? DateTime(0);
            final dateB = b.eventStartAt ?? DateTime(0);
            switch (_sortHistory) {
              case SortOption.dateAsc: return dateA.compareTo(dateB);
              case SortOption.dateDesc: return dateB.compareTo(dateA);
              case SortOption.titleAsc: return (a.eventTitle ?? '').compareTo(b.eventTitle ?? '');
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // === SECCIÓN 1: ACTIVOS ===
                _SectionHeader(
                  title: 'Activos',
                  // Nota: El conteo real visual dependerá de si se ocultan cancelados,
                  // pero como aquí están mezclados, mostramos el total temporal.
                  count: activeList.length, 
                  icon: Icons.event_available,
                  color: Colors.indigo,
                  action: PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort, color: Colors.grey),
                    tooltip: 'Ordenar activos',
                    onSelected: (val) => setState(() => _sortActive = val),
                    itemBuilder: (ctx) => [
                      CheckedPopupMenuItem(
                        value: SortOption.dateAsc,
                        checked: _sortActive == SortOption.dateAsc,
                        child: const Text('Más próximos'),
                      ),
                      CheckedPopupMenuItem(
                        value: SortOption.dateDesc,
                        checked: _sortActive == SortOption.dateDesc,
                        child: const Text('Más lejanos'),
                      ),
                    ],
                  ),
                ),
                
                if (activeList.isEmpty)
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 20),
                     child: Text('No tienes eventos activos.', style: TextStyle(color: Colors.grey)),
                   )
                else
                  // Pasamos los filtros a la tarjeta para que ella decida si mostrarse
                  ...activeList.map((r) => _RegistrationCardWrapper(
                    registration: r, 
                    service: service,
                    showCancelled: _showCancelled,
                    showFinished: _showFinished,
                  )),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // === SECCIÓN 2: HISTORIAL ===
                _SectionHeader(
                  title: 'Historial',
                  count: historyList.length,
                  icon: Icons.history,
                  color: Colors.grey.shade700,
                  action: PopupMenuButton<dynamic>(
                    icon: Stack(
                      children: [
                        const Icon(Icons.tune, color: Colors.grey),
                        if (!_showFinished || !_showCancelled)
                          Positioned(right: 0, top: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                      ],
                    ),
                    tooltip: 'Filtros historial',
                    onSelected: (val) {
                      setState(() {
                         if (val is SortOption) _sortHistory = val;
                         if (val == 'toggle_finished') _showFinished = !_showFinished;
                         if (val == 'toggle_cancelled') _showCancelled = !_showCancelled;
                      });
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(enabled: false, height: 32, child: Text('ORDENAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      CheckedPopupMenuItem(
                        value: SortOption.dateDesc,
                        checked: _sortHistory == SortOption.dateDesc,
                        child: const Text('Más recientes'),
                      ),
                       CheckedPopupMenuItem(
                        value: SortOption.dateAsc,
                        checked: _sortHistory == SortOption.dateAsc,
                        child: const Text('Más antiguos'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(enabled: false, height: 32, child: Text('MOSTRAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      CheckedPopupMenuItem(
                        value: 'toggle_finished',
                        checked: _showFinished,
                        child: const Text('Finalizados'),
                      ),
                      CheckedPopupMenuItem(
                        value: 'toggle_cancelled',
                        checked: _showCancelled,
                        child: const Text('Cancelados'),
                      ),
                    ],
                  ),
                ),

                if (historyList.isEmpty)
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 20),
                     child: Text('No tienes historial.', style: TextStyle(color: Colors.grey)),
                   )
                else
                  // Usamos el wrapper para manejar la visibilidad individual
                  ...historyList.map((r) => _RegistrationCardWrapper(
                    registration: r, 
                    service: service,
                    showCancelled: _showCancelled,
                    showFinished: _showFinished,
                  )),
                  
                 const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------------------
// COMPONENTES UI
// --------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final Widget action;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        // Nota: Este contador muestra el total de la lista, aunque algunos se oculten por filtro.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
          child: Text(count.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        const Spacer(),
        action,
      ],
    );
  }
}

///  WRAPPER INTELIGENTE
/// Este widget decide si mostrar la tarjeta o un espacio vacío (SizedBox.shrink)
/// basándose en el estado REAL del evento y los filtros globales.
class _RegistrationCardWrapper extends StatelessWidget {
  final MyRegistration registration;
  final EventService service;
  final bool showCancelled;
  final bool showFinished;

  const _RegistrationCardWrapper({
    required this.registration,
    required this.service,
    required this.showCancelled,
    required this.showFinished,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.streamEventById(registration.eventId),
      builder: (context, snapshot) {
        // 1. Determinar el estado REAL del evento
        bool eventExists = true;
        bool isActive = true;
        DateTime? endAt;

        if (snapshot.hasError) {
          eventExists = false; // Borrado físico (Hard delete) -> Se considera Cancelado
          isActive = false;
        } else if (snapshot.hasData) {
          final evt = snapshot.data!;
          isActive = evt.isActive;
          endAt = evt.endAt;
        } else {
          // Cargando... mostramos un placeholder o esperamos
          return const Padding(
             padding: EdgeInsets.only(bottom: 16),
             child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          );
        }

        final now = DateTime.now();
        final isFinished = endAt != null && endAt.isBefore(now);
        // "Cancelado" es si el admin lo puso inactive o lo borró
        final isCancelled = !isActive || !eventExists;

        // 2. APLICAR FILTROS (Aquí es donde ocurre la magia)
        if (isCancelled && !showCancelled) {
          return const SizedBox.shrink(); // Ocultar si filtro de cancelados está OFF
        }
        // Nota: Priorizamos "Cancelado" sobre "Finalizado". 
        // Si un evento se canceló, cuenta como cancelado aunque la fecha ya haya pasado.
        if (!isCancelled && isFinished && !showFinished) {
          return const SizedBox.shrink(); // Ocultar si filtro de finalizados está OFF
        }

        // 3. Si pasa los filtros, mostramos la tarjeta
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _RegistrationCardContent(
            registration: registration, 
            service: service,
            isFinished: isFinished,
            isCancelled: isCancelled,
            eventExists: eventExists,
          ),
        );
      },
    );
  }
}

/// Contenido visual de la tarjeta (Separado para limpieza)
class _RegistrationCardContent extends StatefulWidget {
  final MyRegistration registration;
  final EventService service;
  final bool isFinished;
  final bool isCancelled;
  final bool eventExists;

  const _RegistrationCardContent({
    required this.registration,
    required this.service,
    required this.isFinished,
    required this.isCancelled,
    required this.eventExists,
  });

  @override
  State<_RegistrationCardContent> createState() => _RegistrationCardContentState();
}

class _RegistrationCardContentState extends State<_RegistrationCardContent> {
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
              Text(
                r.eventTitle ?? 'Evento (${r.eventId})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle.isEmpty ? 'ID: ${r.eventId}' : subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // --- UI DE ESTADO ---
              if (widget.isCancelled)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.eventExists 
                              ? 'Cancelado por el organizador.' 
                              : 'Evento eliminado.',
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.isFinished)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Este evento ha finalizado.',
                          style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // --- BOTONES ---
              // Si está cancelado o finalizado -> NO mostramos botones (ni Ocultar, ni Cancelar Registro)
              // Solo mostramos botones si está ACTIVO.
              if (!widget.isCancelled && !widget.isFinished)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Mi QR'),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MyAttendanceQrScreen(eventId: r.eventId)));
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () async {
                           // Lógica de desuscripción
                           // (Tu EventService.unregisterFromEvent ya se encarga del resto)
                           try {
                             await widget.service.unregisterFromEvent(r.eventId);
                           } catch(e) {
                             if(context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                             }
                           }
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No tienes registros'));
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Error: $error'));
  }
}

String _fmt(DateTime d) {
  final two = (int x) => x.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}