import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventAttendeesScreen extends StatelessWidget {
  final String eventId;
  final String eventTitle;

  const EventAttendeesScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    final regsRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('registrations');

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistentes · $eventTitle'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: regsRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Aún no hay registros para este evento'),
            );
          }

          final attended = docs.where((d) => d['attended'] == true).length;
          final total = docs.length;

          return Column(
            children: [
              // 📊 RESUMEN
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SummaryChip(
                      label: 'Total',
                      value: total.toString(),
                      color: Colors.blue,
                    ),
                    _SummaryChip(
                      label: 'Asistieron',
                      value: attended.toString(),
                      color: Colors.green,
                    ),
                    _SummaryChip(
                      label: 'No asistieron',
                      value: (total - attended).toString(),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 👥 LISTA
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();

                    final name = d['userName'] ?? 'Sin nombre';
                    final email = d['userEmail'] ?? '';
                    final attended = d['attended'] == true;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          attended ? Icons.check_circle : Icons.cancel,
                          color: attended ? Colors.green : Colors.red,
                        ),
                        title: Text(name),
                        subtitle: Text(email),
                        trailing: attended
                            ? const Text(
                                'Asistió',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                'No asistió',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
