import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_detail_screen.dart';

// Enum para ordenamiento
enum SortOption { dateDesc, dateAsc, nameAsc, attendeesDesc }

class EventListScreen extends StatefulWidget {
  final bool isAdmin;
  final String currentUid;
  final bool canRegister;

  const EventListScreen({
    super.key,
    required this.isAdmin,
    required this.currentUid,
    this.canRegister = true,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final service = EventService();

  // Filtros de Búsqueda (Búsqueda Avanzada)
  String? selectedCategory;
  String? selectedLocation;
  DateTime? selectedDate;

  // Filtros de Estado (AppBar - Super Menú)
  // Por defecto ocultamos lo "viejo" para no ensuciar la vista
  bool _showFinished = false;
  bool _showCancelled = false;
  bool _showOngoing = true; 
  bool _showUpcoming = true; 

  // Ordenamiento
  SortOption _sortBy = SortOption.dateAsc; 

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 700;

    // Usamos el stream que trae TODO (Tu servicio ya lo hace bien)
    final stream = widget.isAdmin
        ? service.streamAllEventsAdmin()
        : service.streamAllPublicEvents(); 

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Eventos disponibles',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        actions: [
          // 🛠 SUPER MENÚ DE CONFIGURACIÓN
          PopupMenuButton<dynamic>(
            icon: Stack(
              children: [
                const Icon(Icons.tune, color: Colors.black87),
                // Se enciende si hay filtros raros (Cancelados/Finalizados ON) o (Próximos OFF)
                if (_showCancelled || _showFinished || !_showUpcoming) 
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  )
              ],
            ),
            tooltip: 'Configurar vista',
            onSelected: (value) {
              setState(() {
                if (value is SortOption) {
                  _sortBy = value;
                } else if (value == 'toggle_finished') {
                  _showFinished = !_showFinished;
                } else if (value == 'toggle_cancelled') {
                  _showCancelled = !_showCancelled;
                } else if (value == 'toggle_ongoing') {
                  _showOngoing = !_showOngoing;
                } else if (value == 'toggle_upcoming') { 
                  _showUpcoming = !_showUpcoming;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false, height: 32,
                child: Text('ORDENAR POR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              CheckedPopupMenuItem(
                value: SortOption.dateAsc,
                checked: _sortBy == SortOption.dateAsc,
                child: const Text('Más próximos'),
              ),
              CheckedPopupMenuItem(
                value: SortOption.dateDesc,
                checked: _sortBy == SortOption.dateDesc,
                child: const Text('Más lejanos'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                enabled: false, height: 32,
                child: Text('MOSTRAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              CheckedPopupMenuItem(
                value: 'toggle_upcoming',
                checked: _showUpcoming,
                child: const Text('Próximos'),
              ),
              if (!widget.isAdmin)
                CheckedPopupMenuItem(
                  value: 'toggle_ongoing',
                  checked: _showOngoing,
                  child: const Text('Eventos en curso'),
                ),
              CheckedPopupMenuItem(
                value: 'toggle_finished',
                checked: _showFinished,
                child: const Text('Finalizados (Historial)'),
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
        stream: stream,
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) return _ErrorView(error: snap.error.toString());
          
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var allEvents = snap.data ?? [];

          // Pre-cálculo para los dropdowns
          final categories = allEvents.map((e) => e.category).toSet().toList();
          final locations = allEvents.map((e) => e.location).toSet().toList();
          final now = DateTime.now();

          // =================================================
          // 🧠 LÓGICA DE FILTRADO MAESTRO
          // =================================================
          final ongoingEvents = <EventModel>[];
          final otherEvents = <EventModel>[];

          for (var e in allEvents) {
            // 1. Filtros de Búsqueda Avanzada (Categoría, Ubicación, Fecha)
            if (selectedCategory != null && e.category != selectedCategory) continue;
            if (selectedLocation != null && e.location != selectedLocation) continue;
            if (selectedDate != null) {
              if (e.startAt.year != selectedDate!.year ||
                  e.startAt.month != selectedDate!.month ||
                  e.startAt.day != selectedDate!.day) continue;
            }

            // 2. Determinar Estado
            final isActive = e.isActive ?? true;
            final isOngoing = isActive && e.startAt.isBefore(now) && e.endAt.isAfter(now);
            final isFinished = e.endAt.isBefore(now);
            final isCancelled = !isActive;
            final isFuture = isActive && e.startAt.isAfter(now);

            // 3. Clasificación
            // EN CURSO: Prioridad
            if (isOngoing) {
              if (widget.isAdmin || _showOngoing) ongoingEvents.add(e);
              continue; 
            }

            // OTROS: Dependen de los toggles
            bool keep = false;
            
            if (isCancelled) {
              if (_showCancelled) keep = true;
            } else if (isFinished) {
              if (_showFinished) keep = true;
            } else if (isFuture) {
              if (_showUpcoming) keep = true; 
            }

            if (keep) otherEvents.add(e);
          }

          // 4. Ordenamiento
          otherEvents.sort((a, b) {
            switch (_sortBy) {
              case SortOption.dateAsc: return a.startAt.compareTo(b.startAt);
              case SortOption.dateDesc: return b.startAt.compareTo(a.startAt);
              case SortOption.nameAsc: return a.title.compareTo(b.title);
              case SortOption.attendeesDesc: 
                return (b.registrationsCount ?? 0).compareTo(a.registrationsCount ?? 0);
            }
          });

          final displayList = [...ongoingEvents, ...otherEvents];
          final isFilterActive = selectedCategory != null || selectedLocation != null || selectedDate != null;

          return Column(
            children: [
              // ✅ BÚSQUEDA AVANZADA (Desplegable)
              _AdvancedSearchCard(
                categories: categories,
                locations: locations,
                selectedCategory: selectedCategory,
                selectedLocation: selectedLocation,
                selectedDate: selectedDate,
                isFilterActive: isFilterActive, 
                onCategoryChanged: (v) => setState(() => selectedCategory = v),
                onLocationChanged: (v) => setState(() => selectedLocation = v),
                onDateChanged: (d) => setState(() => selectedDate = d),
                onClear: () {
                  setState(() {
                    selectedCategory = null;
                    selectedLocation = null;
                    selectedDate = null;
                  });
                },
              ),

              // Indicador de filtros ocultos (Ayuda visual al usuario)
              if (!_showFinished || !_showCancelled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        'Los eventos finalizados o cancelados están ocultos por defecto.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: displayList.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: 8,
                        ),
                        itemCount: displayList.length,
                        itemBuilder: (context, i) {
                          final e = displayList[i];
                          final canEdit = widget.isAdmin || e.organizerId == widget.currentUid;
                          
                          final isActive = e.isActive ?? true;
                          final isOngoing = isActive && e.startAt.isBefore(now) && e.endAt.isAfter(now);
                          final isFinished = e.endAt.isBefore(now);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _EventCard(
                              event: e,
                              isOngoing: isOngoing,
                              isFinished: isFinished,
                              isCancelled: !isActive,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 350),
                                    pageBuilder: (_, __, ___) => EventDetailScreen(
                                      event: e,
                                      canEdit: canEdit,
                                      canRegister: widget.canRegister,
                                    ),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------
// ✅ BÚSQUEDA AVANZADA MEJORADA
// ---------------------------------------------------------
class _AdvancedSearchCard extends StatelessWidget {
  final List<String> categories;
  final List<String> locations;
  final String? selectedCategory;
  final String? selectedLocation;
  final DateTime? selectedDate;
  final bool isFilterActive;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onClear;

  const _AdvancedSearchCard({
    required this.categories,
    required this.locations,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.selectedDate,
    required this.isFilterActive,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onDateChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Borde sutil para que se vea como un input
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
      child: Theme(
        // Quitamos las líneas divisorias feas por defecto
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Si hay filtros activos, forzamos que esté abierto, si no, cerrado.
          // OJO: Usamos key para que se repinte si cambia el estado
          key: PageStorageKey<String>('search_card_$isFilterActive'),
          initiallyExpanded: isFilterActive, 
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFilterActive ? Colors.indigo.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search_rounded, 
              color: isFilterActive ? Colors.indigo : Colors.grey.shade600,
              size: 20,
            ),
          ),
          title: Text(
            isFilterActive ? 'Filtros aplicados' : 'Búsqueda avanzada',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isFilterActive ? Colors.indigo : Colors.black87,
              fontSize: 15,
            ),
          ),
          subtitle: isFilterActive 
            ? const Text('Resultados filtrados', style: TextStyle(fontSize: 12, color: Colors.grey))
            : const Text('Categoría, ubicación, fecha...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(),
            const SizedBox(height: 12),
            
            // Fila 1
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Categoría',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLocation,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Ubicación',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...locations.map((l) => DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: onLocationChanged,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Fila 2
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade700),
                    label: Text(
                      selectedDate == null 
                        ? 'Seleccionar Fecha' 
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey.shade50,
                      side: BorderSide(color: Colors.grey.shade600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (d != null) onDateChanged(d);
                    },
                  ),
                ),
                if (isFilterActive) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Limpiar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// COMPONENTES VISUALES
// (Copia estos tal cual si no los tenías definidos abajo)
// ---------------------------------------------------------

class _EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isOngoing;
  final bool isFinished;
  final bool isCancelled;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.isOngoing,
    required this.isFinished,
    required this.isCancelled,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final hasImage = e.imageUrl != null && e.imageUrl!.isNotEmpty;
    final double opacity = (widget.isCancelled || widget.isFinished) ? 0.75 : 1.0;
    final ColorFilter? colorFilter = widget.isCancelled 
        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) 
        : null;

    return AnimatedScale(
      scale: pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        child: Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: widget.isOngoing 
                  ? Border.all(color: Colors.green, width: 2) 
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Header Imagen
                Container(
                  height: 160,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                    color: Color(0xFFEEEEEE), 
                  ),
                  child: ClipRRect(
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                     child: ColorFiltered(
                       colorFilter: colorFilter ?? const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                       child: Stack(
                         fit: StackFit.expand,
                         children: [
                           if (hasImage)
                             Image.network(e.imageUrl!, fit: BoxFit.cover)
                           else
                             Container(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   colors: [Colors.indigo.shade300, Colors.indigo.shade100],
                                   begin: Alignment.bottomLeft, end: Alignment.topRight,
                                 ),
                               ),
                               child: const Icon(Icons.event, color: Colors.white54, size: 50),
                             ),

                           if (hasImage)
                             Container(
                               decoration: BoxDecoration(
                                 gradient: LinearGradient(
                                   begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                   colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                 ),
                               ),
                             ),

                           Positioned(
                             bottom: 16, left: 16, right: 16,
                             child: Text(
                               e.title,
                               maxLines: 2, overflow: TextOverflow.ellipsis,
                               style: const TextStyle(
                                 color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                                 shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                               ),
                             ),
                           ),

                           if (widget.isOngoing)
                            Positioned(top: 12, right: 12, child: _StatusBadge(label: 'EN CURSO', color: Colors.green))
                           else if (widget.isCancelled)
                            Positioned(top: 12, right: 12, child: _StatusBadge(label: 'CANCELADO', color: Colors.red))
                           else if (widget.isFinished)
                            Positioned(top: 12, right: 12, child: _StatusBadge(label: 'FINALIZADO', color: Colors.black54)),
                         ],
                       ),
                     ),
                  ),
                ),
                
                // 📄 Info
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(icon: Icons.category, text: '${e.category} • ${e.subcategory}'),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.place, text: e.location),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.access_time, text: _formatDate(e.startAt)),
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
  
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No se encontraron eventos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Error: $error'));
  }
}