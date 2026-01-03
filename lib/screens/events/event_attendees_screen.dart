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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Asistentes · $eventTitle',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: regsRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const _EmptyAttendeesState();
          }

          final attended = docs.where((doc) {
            final data = doc.data();
            return data['attended'] == true;
          }).length;
          final total = docs.length;

          return Column(
            children: [
              /// 📊 RESUMEN
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total',
                        value: total.toString(),
                        icon: Icons.people,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Asistieron',
                        value: attended.toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'No asistieron',
                        value: (total - attended).toString(),
                        icon: Icons.cancel,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),

              /// 👥 LISTA
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = docs[i].data();

                    final name = d['userName'] ?? 'Sin nombre';
                    final email = d['userEmail'] ?? '';
                    final attended = d['attended'] == true;

                    return _AttendeeTile(
                      name: name,
                      email: email,
                      attended: attended,
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
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
class _AttendeeTile extends StatelessWidget {
  final String name;
  final String email;
  final bool attended;

  const _AttendeeTile({
    required this.name,
    required this.email,
    required this.attended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: attended
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
          ),
          child: Icon(
            attended ? Icons.check : Icons.close,
            color: attended ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          email,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Text(
          attended ? 'Asistió' : 'No asistió',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: attended ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
class _EmptyAttendeesState extends StatelessWidget {
  const _EmptyAttendeesState();

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
              Icons.people_outline,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin asistentes aún',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los registros aparecerán aquí conforme los alumnos se inscriban.',
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
