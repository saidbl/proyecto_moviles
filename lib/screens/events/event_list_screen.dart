import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/connectivity_service.dart';
import 'event_detail_screen.dart';

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
  final connectivity = ConnectivityService();

  String? selectedCategory;
  String? selectedLocation;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    final stream = widget.isAdmin
        ? service.streamAllEventsAdmin()
        : service.streamAllActiveEvents();

    final isTablet = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Eventos disponibles',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: stream,
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorView(error: snap.error.toString());
          }

          final allEvents =
              (snap.data ?? []).where((e) => !e.hasStarted).toList();

          final categories =
              allEvents.map((e) => e.category).toSet().toList();
          final locations =
              allEvents.map((e) => e.location).toSet().toList();

          final filteredEvents = allEvents.where((e) {
            if (selectedCategory != null && e.category != selectedCategory) {
              return false;
            }
            if (selectedLocation != null &&
                e.location != selectedLocation) {
              return false;
            }
            if (selectedDate != null) {
              final d = selectedDate!;
              if (e.startAt.year != d.year ||
                  e.startAt.month != d.month ||
                  e.startAt.day != d.day) {
                return false;
              }
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _FiltersCard(
                  categories: categories,
                  locations: locations,
                  selectedCategory: selectedCategory,
                  selectedLocation: selectedLocation,
                  selectedDate: selectedDate,
                  onCategoryChanged: (v) =>
                      setState(() => selectedCategory = v),
                  onLocationChanged: (v) =>
                      setState(() => selectedLocation = v),
                  onDateChanged: (d) =>
                      setState(() => selectedDate = d),
                  onClear: () {
                    setState(() {
                      selectedCategory = null;
                      selectedLocation = null;
                      selectedDate = null;
                    });
                  },
                ),
              ),

              Expanded(
                child: filteredEvents.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: 8,
                        ),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, i) {
                          final e = filteredEvents[i];
                          final canEdit = widget.isAdmin ||
                              e.organizerId ==
                                  widget.currentUid;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _EventCard(
                              event: e,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration:
                                        const Duration(milliseconds: 350),
                                    pageBuilder: (_, __, ___) =>
                                        EventDetailScreen(
                                      event: e,
                                      canEdit: canEdit,
                                      canRegister: widget.canRegister,
                                    ),
                                    transitionsBuilder:
                                        (_, animation, __, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
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
class _EventCard extends StatefulWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.event.imageUrl != null &&
            widget.event.imageUrl!.isNotEmpty;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼 IMAGEN / HEADER
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  color: Colors.grey.shade200,
                  image: hasImage
                      ? DecorationImage(
                          image:
                              NetworkImage(widget.event.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          widget.event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // 📄 CONTENIDO
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasImage)
                      Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 8),

                    Text(
                      '${widget.event.category} • ${widget.event.subcategory}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(Icons.place,
                            size: 16,
                            color: Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style:
                                const TextStyle(fontSize: 13),
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
    );
  }
}
class _FiltersCard extends StatelessWidget {
  final List<String> categories;
  final List<String> locations;
  final String? selectedCategory;
  final String? selectedLocation;
  final DateTime? selectedDate;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onClear;

  const _FiltersCard({
    required this.categories,
    required this.locations,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.selectedDate,
    required this.onCategoryChanged,
    required this.onLocationChanged,
    required this.onDateChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar eventos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration:
                  const InputDecoration(labelText: 'Categoría'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Todas')),
                ...categories.map(
                  (c) =>
                      DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: onCategoryChanged,
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration:
                  const InputDecoration(labelText: 'Ubicación'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Todas')),
                ...locations.map(
                  (l) =>
                      DropdownMenuItem(value: l, child: Text(l)),
                ),
              ],
              onChanged: onLocationChanged,
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                selectedDate == null
                    ? 'Seleccionar fecha'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
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

            if (selectedCategory != null ||
                selectedLocation != null ||
                selectedDate != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onClear,
                  child: const Text('Limpiar filtros'),
                ),
              ),
          ],
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
              Icons.event_busy_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay eventos disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar o limpiar los filtros para ver más resultados.',
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
class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

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
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Ocurrió un problema',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
