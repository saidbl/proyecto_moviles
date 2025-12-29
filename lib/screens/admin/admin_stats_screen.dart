import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas del sistema')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            title: 'Eventos totales',
            icon: Icons.event,
            stream: db.collection('events').snapshots(),
            builder: (q) => q.docs.length.toString(),
          ),

          _StatCard(
            title: 'Eventos activos',
            icon: Icons.check_circle,
            stream: db
                .collection('events')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (q) => q.docs.length.toString(),
          ),

          _StatCard(
            title: 'Eventos cancelados',
            icon: Icons.cancel,
            stream: db
                .collection('events')
                .where('isActive', isEqualTo: false)
                .snapshots(),
            builder: (q) => q.docs.length.toString(),
          ),

          _StatCard(
            title: 'Usuarios registrados',
            icon: Icons.people,
            stream: db.collection('users').snapshots(),
            builder: (q) => q.docs.length.toString(),
          ),

          _StatCard(
            title: 'Alumnos',
            icon: Icons.school,
            stream: db
                .collection('users')
                .where('role', isEqualTo: 'estudiante')
                .snapshots(),
            builder: (q) => q.docs.length.toString(),
          ),

          _StatCard(
            title: 'Organizadores',
            icon: Icons.event_note,
            stream: db
                .collection('users')
                .where('role', isEqualTo: 'organizador')
                .snapshots(),
            builder: (q) => q.docs.length.toString(),
          ),
          const SizedBox(height: 24),
const Text(
  'Indicadores avanzados',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: db.collection('events').snapshots(),
  builder: (context, snap) {
    if (!snap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final events = snap.data!.docs;

    int totalCapacity = 0;
    int totalRegistrations = 0;

    for (final e in events) {
      totalCapacity += (e['capacity'] ?? 0) as int;
      totalRegistrations += (e['registrationsCount'] ?? 0) as int;
    }

    final avgRegistrations = events.isNotEmpty
        ? (totalRegistrations / events.length).toStringAsFixed(1)
        : '0';

    final occupancy = totalCapacity > 0
        ? ((totalRegistrations / totalCapacity) * 100).toStringAsFixed(0)
        : '0';

    return Column(
      children: [
        _SimpleStatRow('Promedio de inscritos', avgRegistrations),
        _SimpleStatRow('Ocupación global', '$occupancy %'),
      ],
    );
  },
),
const SizedBox(height: 24),
const Text(
  'Top eventos por inscritos',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: db.collection('events').snapshots(),
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox();

    final events = [...snap.data!.docs];

    events.sort((a, b) =>
        (b['registrationsCount'] ?? 0)
            .compareTo(a['registrationsCount'] ?? 0));

    return Column(
      children: events.take(5).map((e) {
        final regs = e['registrationsCount'] ?? 0;
        final cap = e['capacity'] ?? 0;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.star),
            title: Text(e['title'] ?? 'Evento'),
            subtitle: Text('Inscritos: $regs / $cap'),
          ),
        );
      }).toList(),
    );
  },
),
const SizedBox(height: 24),
const Text(
  'Eventos por categoría',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: db.collection('events').snapshots(),
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox();

    final Map<String, int> categoryCount = {};

    for (final e in snap.data!.docs) {
      final cat = (e['category'] ?? 'Sin categoría') as String;
      categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    int i = 0;

    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: categoryCount.entries.map((entry) {
            final color = colors[i++ % colors.length];
            return PieChartSectionData(
              value: entry.value.toDouble(),
              title: '${entry.key}\n${entry.value}',
              color: color,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  },
),
const SizedBox(height: 24),
const Text(
  'Eventos con baja asistencia',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: db.collection('events').snapshots(),
  builder: (context, snap) {
    if (!snap.hasData) return const SizedBox();

    final lowAttendance = snap.data!.docs.where((e) {
      final cap = e['capacity'] ?? 0;
      final reg = e['registrationsCount'] ?? 0;
      return cap > 0 && (reg / cap) < 0.3;
    }).toList();

    if (lowAttendance.isEmpty) {
      return const Text('Todos los eventos tienen buena asistencia');
    }

    return Column(
      children: lowAttendance.map((e) {
        return Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(e['title'] ?? 'Evento'),
            subtitle: const Text('Menos del 30% de ocupación'),
          ),
        );
      }).toList(),
    );
  },
),

        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String Function(QuerySnapshot<Map<String, dynamic>>) builder;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.stream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final value = snap.hasData ? builder(snap.data!) : '—';

        return Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
class _SimpleStatRow extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleStatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.analytics),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
