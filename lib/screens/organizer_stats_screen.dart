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

    final eventsStream = db
        .collection('events')
        .where('organizerId', isEqualTo: uid)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Estadísticas generales',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: eventsStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snap.data!.docs;

          if (events.isEmpty) {
            return const _EmptyStatsState();
          }

          int totalEvents = events.length;
          int totalRegs = 0;

          final Map<String, int> categoryCount = {};

          for (final e in events) {
            final data = e.data();
            final cat = data['category'] ?? 'Otros';
            categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
            totalRegs += (data['registrationsCount'] ?? 0) as int;
          }

          return FutureBuilder<int>(
            future: _countAttended(uid),
            builder: (context, attSnap) {
              final attended = attSnap.data ?? 0;
              final attendanceRate = totalRegs == 0
                  ? 0
                  : ((attended / totalRegs) * 100).round();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// 📊 KPIs
                  GridView.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _KpiCard(
                        label: 'Eventos',
                        value: totalEvents,
                        icon: Icons.event,
                        color: Colors.indigo,
                      ),
                      _KpiCard(
                        label: 'Registros',
                        value: totalRegs,
                        icon: Icons.people,
                        color: Colors.blueGrey,
                      ),
                      _KpiCard(
                        label: 'Asistencias',
                        value: attended,
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _KpiCard(
                        label: '% Asistencia',
                        value: attendanceRate,
                        icon: Icons.trending_up,
                        color: Colors.deepPurple,
                        suffix: '%',
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  ///  ASISTENCIA
                  const _SectionTitle('Asistencia global'),
                  SizedBox(
                    height: 220,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 48,
                            sections: [
                              PieChartSectionData(
                                value: attended.toDouble(),
                                color: Colors.green,
                                title: 'Asistió',
                                radius: 60,
                                titleStyle:
                                    const TextStyle(color: Colors.white),
                              ),
                              PieChartSectionData(
                                value:
                                    (totalRegs - attended).toDouble(),
                                color: Colors.redAccent,
                                title: 'No asistió',
                                radius: 60,
                                titleStyle:
                                    const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  ///  CATEGORÍAS
                  const _SectionTitle('Eventos por categoría'),
                  SizedBox(
                    height: 260,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    final key = categoryCount.keys
                                        .elementAt(value.toInt());
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(top: 8),
                                      child: Text(
                                        key,
                                        style:
                                            const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: categoryCount.entries.map((e) {
                              final index = categoryCount.keys
                                  .toList()
                                  .indexOf(e.key);
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value.toDouble(),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    color: Colors.indigo,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
  final Color color;
  final String suffix;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            '$value$suffix',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}
class _EmptyStatsState extends StatelessWidget {
  const _EmptyStatsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin datos para mostrar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea eventos para empezar a ver estadísticas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
