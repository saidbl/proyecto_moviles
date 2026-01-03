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

  String? selectedCategory;
  String? selectedLocation;
  DateTime? selectedDate;

  final connectivity = ConnectivityService();

  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    connectivity.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => hasInternet = connected);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final stream = widget.isAdmin
        ? service.streamAllEventsAdmin()
        : service.streamAllActiveEvents();

    final isTablet = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Eventos disponibles'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: stream,
        initialData: const [],
        builder: (context, snap) {
          if (snap.hasError) {
            return _ErrorView(error: snap.error.toString());
          }

          final allEvents = (snap.data ?? [])
              .where((e) => !e.hasStarted)
              .toList();

          final categories =
              allEvents.map((e) => e.category).toSet().toList();
          final locations =
              allEvents.map((e) => e.location).toSet().toList();

          final filteredEvents = allEvents.where((e) {
            if (selectedCategory != null &&
                e.category != selectedCategory) {
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

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                children: [

                  /// 🔎 FILTROS
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

                  /// 📋 LISTA
                  Expanded(
                    child: filteredEvents.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: () async =>
                                Future.delayed(
                                    const Duration(milliseconds: 300)),
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 24 : 16,
                                vertical: 8,
                              ),
                              itemCount: filteredEvents.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final e = filteredEvents[i];
                                final canEdit = widget.isAdmin ||
                                    e.organizerId ==
                                        widget.currentUid;

                                return _EventCard(
                                  event: e,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EventDetailScreen(
                                          event: e,
                                          canEdit: canEdit,
                                          canRegister:
                                              widget.canRegister,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: const [
                Icon(Icons.filter_list, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Todas')),
                ...categories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: onCategoryChanged,
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Ubicación',
                prefixIcon: Icon(Icons.place),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Todas')),
                ...locations.map(
                  (l) => DropdownMenuItem(value: l, child: Text(l)),
                ),
              ],
              onChanged: onLocationChanged,
            ),

            const SizedBox(height: 8),

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
              TextButton(
                onPressed: onClear,
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      ),
    );
  }
}
class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!event.isActive)
                    const Icon(Icons.cancel,
                        color: Colors.red),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${event.category} • ${event.subcategory}',
                style:
                    TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place,
                      size: 16, color: Colors.indigo),
                  const SizedBox(width: 4),
                  Text(event.location),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay eventos que coincidan con los filtros',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          error,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
