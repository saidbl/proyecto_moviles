import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'create_edit_event_screen.dart';
import 'event_detail_screen.dart';
import 'scan_attendance_screen.dart';
import 'event_attendees_screen.dart';

// Enum para opciones de ordenamiento
enum SortOption { dateDesc, dateAsc, nameAsc, attendeesDesc }

class MyEventsScreen extends StatefulWidget {
  final String currentUid;
  const MyEventsScreen({super.key, required this.currentUid});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  final service = EventService();

  // Estados de Filtros (Por defecto: Solo activos y futuros)
  bool _showActive = true;     
  bool _showFinished = false;  
  bool _showCancelled = false; 

  // Estado de Ordenamiento
  SortOption _sortBy = SortOption.dateDesc; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mis eventos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // 🛠 SUPER MENÚ DE FILTROS Y ORDENAMIENTO
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.tune, color: Colors.black87), // Icono de ajuste
            tooltip: 'Filtrar y Ordenar',
            onSelected: (value) {
              setState(() {
                // Lógica para Ordenamiento
                if (value is SortOption) {
                  _sortBy = value;
                } 
                // Lógica para Filtros (Strings identificadores)
                else if (value == 'toggle_active') {
                  _showActive = !_showActive;
                } else if (value == 'toggle_finished') {
                  _showFinished = !_showFinished;
                } else if (value == 'toggle_cancelled') {
                  _showCancelled = !_showCancelled;
                }
              });
            },
            itemBuilder: (context) => [
              // --- SECCIÓN 1: ORDENAR ---
              const PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text('ORDENAR POR', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              CheckedPopupMenuItem(
                value: SortOption.dateDesc,
                checked: _sortBy == SortOption.dateDesc,
                child: const Text('Más recientes'),
              ),
              CheckedPopupMenuItem(
                value: SortOption.dateAsc,
                checked: _sortBy == SortOption.dateAsc,
                child: const Text('Más antiguos'),
              ),
              CheckedPopupMenuItem(
                value: SortOption.attendeesDesc,
                checked: _sortBy == SortOption.attendeesDesc,
                child: const Text('Mayor asistencia'),
              ),
              CheckedPopupMenuItem(
                value: SortOption.nameAsc,
                checked: _sortBy == SortOption.nameAsc,
                child: const Text('Nombre (A-Z)'),
              ),
              
              const PopupMenuDivider(),

              // --- SECCIÓN 2: FILTROS ---
              const PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text('MOSTRAR ESTADO', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              CheckedPopupMenuItem(
                value: 'toggle_active',
                checked: _showActive,
                child: const Text('Próximos / Activos'),
              ),
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
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: service.streamMyEvents(),
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }

          var allEvents = snap.data ?? const [];

          if (snap.connectionState == ConnectionState.waiting &&
              allEvents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (allEvents.isEmpty) {
            return const _EmptyMyEventsState();
          }

          // =================================================
          // 🧠 LÓGICA DE FILTRADO Y PRIORIDAD
          // =================================================
          final now = DateTime.now();
          
          final ongoingEvents = <EventModel>[];
          final otherEvents = <EventModel>[];

          for (var e in allEvents) {
            final isActive = e.isActive ?? true;
            // "En Curso": Activo + Inicio en pasado + Fin en futuro
            final isOngoing = isActive && 
                              e.startAt.isBefore(now) && 
                              e.endAt.isAfter(now);

            if (isOngoing) {
              ongoingEvents.add(e);
            } else {
              // Filtros normales
              bool keep = false;
              final isFinished = e.endAt.isBefore(now);
              final isFuture = e.startAt.isAfter(now); // O simplemente !isFinished
              
              if (!isActive) {
                if (_showCancelled) keep = true;
              } else if (isFinished) {
                if (_showFinished) keep = true;
              } else {
                // Asumimos Activo/Futuro
                if (_showActive) keep = true;
              }

              if (keep) otherEvents.add(e);
            }
          }

          // Ordenamiento de la lista secundaria
          otherEvents.sort((a, b) {
            switch (_sortBy) {
              case SortOption.dateDesc: 
                return b.startAt.compareTo(a.startAt);
              case SortOption.dateAsc: 
                return a.startAt.compareTo(b.startAt);
              case SortOption.attendeesDesc: 
                return (b.registrationsCount ?? 0).compareTo(a.registrationsCount ?? 0);
              case SortOption.nameAsc: 
                return a.title.compareTo(b.title);
            }
          });

          // Unimos: Prioridad (En curso) + Otros
          final displayList = [...ongoingEvents, ...otherEvents];

          if (displayList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text('No hay eventos con estos filtros'),
                  TextButton(
                    onPressed: () => setState(() {
                       _showActive = true; 
                       _showFinished = false; 
                       _showCancelled = false;
                    }), 
                    child: const Text('Restablecer filtros')
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: displayList.length,
            itemBuilder: (context, i) {
              final e = displayList[i];
              
              final isActive = e.isActive ?? true;
              final isOngoing = isActive && e.startAt.isBefore(now) && e.endAt.isAfter(now);
              final isFinished = e.endAt.isBefore(now);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _MyEventCard(
                  event: e,
                  isOngoing: isOngoing,
                  isFinished: isFinished,
                  isCancelled: !isActive,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// COMPONENTES VISUALES (Card, Badges, Chips)
// ---------------------------------------------------------

class _MyEventCard extends StatefulWidget {
  final EventModel event;
  final bool isOngoing;
  final bool isFinished;
  final bool isCancelled;

  const _MyEventCard({
    required this.event,
    required this.isOngoing,
    required this.isFinished,
    required this.isCancelled,
  });

  @override
  State<_MyEventCard> createState() => _MyEventCardState();
}

class _MyEventCardState extends State<_MyEventCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final theme = Theme.of(context);
    final hasImage = e.imageUrl != null && e.imageUrl!.isNotEmpty;

    // Opacidad reducida si ya pasó o se canceló
    final double opacity = (widget.isCancelled || widget.isFinished) ? 0.75 : 1.0;
    // Escala de grises si está cancelado
    final ColorFilter? colorFilter = widget.isCancelled 
        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) 
        : null;

    return AnimatedScale(
      scale: pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        child: Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              // Borde verde si está ocurriendo ahora mismo
              border: widget.isOngoing 
                  ? Border.all(color: Colors.green, width: 2) 
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🖼 IMAGEN DEL EVENTO
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: ColorFiltered(
                    colorFilter: colorFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: Stack(
                      children: [
                        hasImage
                            ? Image.network(
                                e.imageUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 120,
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                        
                        // ETIQUETAS DE ESTADO
                        if (widget.isOngoing)
                          Positioned(
                            top: 10, right: 10,
                            child: _StatusBadge(label: 'EN CURSO', color: Colors.green),
                          )
                        else if (widget.isCancelled)
                          Positioned(
                            top: 10, right: 10,
                            child: _StatusBadge(label: 'CANCELADO', color: Colors.red),
                          )
                        else if (widget.isFinished)
                          Positioned(
                            top: 10, right: 10,
                            child: _StatusBadge(label: 'FINALIZADO', color: Colors.grey.shade800),
                          ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🏷 TÍTULO
                      Text(
                        e.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: widget.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// 📍 DATOS
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${e.category} • ${e.subcategory}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${e.registrationsCount} asistentes',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// 🎛 ACCIONES (Solo mostramos lo útil)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActionChip(
                            icon: Icons.visibility,
                            label: 'Detalle',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(event: e, canEdit: true),
                              ),
                            ),
                          ),
                          
                          if (!widget.isCancelled)
                            _ActionChip(
                              icon: Icons.edit,
                              label: 'Editar',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateEditEventScreen(initial: e),
                                ),
                              ),
                            ),
                          
                          if (!widget.isCancelled && !widget.isFinished)
                             _ActionChip(
                              icon: Icons.qr_code_scanner,
                              label: 'Escanear',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScanAttendanceScreen(eventId: e.id),
                                ),
                              ),
                            ),

                          _ActionChip(
                            icon: Icons.people,
                            label: 'Asistentes',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventAttendeesScreen(eventId: e.id, eventTitle: e.title),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMyEventsState extends StatelessWidget {
  const _EmptyMyEventsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aún no has creado eventos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
    return Center(child: Text('Error: $error'));
  }
}