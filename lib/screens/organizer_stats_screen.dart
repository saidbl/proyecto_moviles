import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class OrganizerStatsScreen extends StatelessWidget {
  const OrganizerStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;

    final eventsStream =
        db.collection('events').where('organizerId', isEqualTo: uid).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas generales')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: eventsStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snap.data!.docs;

          if (events.isEmpty) {
            return const Center(
              child: Text('Aún no tienes eventos para analizar'),
            );
          }

          int totalEvents = events.length;
          int totalRegs = 0;
          int attended = 0;

          final Map<String, int> categoryCount = {};
          final Map<int, int> monthCount = {};

          for (final e in events) {
            final data = e.data();
            final cat = data['category'] ?? 'Otros';
            categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;

            final start = (data['startAt'] as Timestamp?)?.toDate();
            if (start != null) {
              monthCount[start.month] = (monthCount[start.month] ?? 0) + 1;
            }

            totalRegs += (data['registrationsCount'] ?? 0) as int;
          }

          // 🔁 Contar asistencias reales
          return FutureBuilder<int>(
            future: _countAttended(uid),
            builder: (context, attSnap) {
              attended = attSnap.data ?? 0;

              final attendanceRate = totalRegs == 0
                  ? 0
                  : ((attended / totalRegs) * 100).round();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 📊 KPIs
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _KpiCard('Eventos', totalEvents, Icons.event),
                      _KpiCard('Registros', totalRegs, Icons.people),
                      _KpiCard('Asistencias', attended, Icons.check_circle),
                      _KpiCard('% Asistencia', attendanceRate, Icons.trending_up),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 🥧 Pie asistencia
                  const Text('Asistencia global',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(sections: [
                        PieChartSectionData(
                          value: attended.toDouble(),
                          color: Colors.green,
                          title: 'Asistió',
                        ),
                        PieChartSectionData(
                          value: (totalRegs - attended).toDouble(),
                          color: Colors.red,
                          title: 'No asistió',
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 📊 Categorías
                  const Text('Eventos por categoría',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: categoryCount.entries.map((e) {
                          return BarChartGroupData(
                            x: categoryCount.keys.toList().indexOf(e.key),
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                color: Colors.blue,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<int> _countAttended(String organizerId) async {
    final db = FirebaseFirestore.instance;
    final events = await db
        .collection('events')
        .where('organizerId', isEqualTo: organizerId)
        .get();

    int count = 0;

    for (final e in events.docs) {
      final regs = await db
          .collection('events')
          .doc(e.id)
          .collection('registrations')
          .where('attended', isEqualTo: true)
          .get();

      count += regs.docs.length;
    }

    return count;
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _KpiCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          trailing: Text(
            value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
