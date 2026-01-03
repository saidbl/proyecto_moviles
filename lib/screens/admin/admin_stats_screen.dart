import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Estadísticas del sistema',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 📊 KPIs PRINCIPALES
          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 700 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatCard(
                title: 'Eventos totales',
                icon: Icons.event,
                color: Colors.indigo,
                stream: db.collection('events').snapshots(),
                builder: (q) => q.docs.length.toString(),
              ),
              _StatCard(
                title: 'Eventos activos',
                icon: Icons.check_circle,
                color: Colors.green,
                stream: db
                    .collection('events')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (q) => q.docs.length.toString(),
              ),
              _StatCard(
                title: 'Eventos cancelados',
                icon: Icons.cancel,
                color: Colors.redAccent,
                stream: db
                    .collection('events')
                    .where('isActive', isEqualTo: false)
                    .snapshots(),
                builder: (q) => q.docs.length.toString(),
              ),
              _StatCard(
                title: 'Usuarios',
                icon: Icons.people,
                color: Colors.blueGrey,
                stream: db.collection('users').snapshots(),
                builder: (q) => q.docs.length.toString(),
              ),
              _StatCard(
                title: 'Alumnos',
                icon: Icons.school,
                color: Colors.deepPurple,
                stream: db
                    .collection('users')
                    .where('role', isEqualTo: 'estudiante')
                    .snapshots(),
                builder: (q) => q.docs.length.toString(),
              ),
              _StatCard(
                title: 'Organizadores',
                icon: Icons.event_note,
                color: Colors.orange,
                stream: db
                    .collection('users')
                    .where('role', isEqualTo: 'organizador')
                    .snapshots(),
                builder: (q) => q.docs.length.toString(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          /// 📈 INDICADORES AVANZADOS
          const _SectionTitle('Indicadores avanzados'),
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
                totalRegistrations +=
                    (e['registrationsCount'] ?? 0) as int;
              }

              final avgRegistrations = events.isNotEmpty
                  ? (totalRegistrations / events.length)
                      .toStringAsFixed(1)
                  : '0';

              final occupancy = totalCapacity > 0
                  ? ((totalRegistrations / totalCapacity) * 100)
                      .toStringAsFixed(0)
                  : '0';

              return Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      label: 'Promedio de inscritos',
                      value: avgRegistrations,
                      icon: Icons.analytics,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      label: 'Ocupación global',
                      value: '$occupancy%',
                      icon: Icons.pie_chart,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          /// ⭐ TOP EVENTOS
          const _SectionTitle('Top eventos por inscritos'),
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

                  return _RankCard(
                    title: e['title'] ?? 'Evento',
                    subtitle: 'Inscritos: $regs / $cap',
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          /// 🥧 CATEGORÍAS
          const _SectionTitle('Eventos por categoría'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('events').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();

              final Map<String, int> categoryCount = {};
              for (final e in snap.data!.docs) {
                final cat =
                    (e['category'] ?? 'Sin categoría') as String;
                categoryCount[cat] =
                    (categoryCount[cat] ?? 0) + 1;
              }

              final colors = [
                Colors.indigo,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.red,
                Colors.teal,
              ];

              int i = 0;

              return SizedBox(
                height: 260,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PieChart(
                      PieChartData(
                        sections: categoryCount.entries.map((entry) {
                          final color =
                              colors[i++ % colors.length];
                          return PieChartSectionData(
                            value: entry.value.toDouble(),
                            title: '${entry.key}\n${entry.value}',
                            color: color,
                            radius: 90,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          /// ⚠️ BAJA ASISTENCIA
          const _SectionTitle('Eventos con baja asistencia'),
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
                return const _GoodState();
              }

              return Column(
                children: lowAttendance.map((e) {
                  return _WarningCard(
                    title: e['title'] ?? 'Evento',
                    subtitle: 'Menos del 30% de ocupación',
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
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String Function(QuerySnapshot<Map<String, dynamic>>) builder;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        final value = snap.hasData ? builder(snap.data!) : '—';

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
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(label,
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RankCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WarningCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading:
            const Icon(Icons.warning, color: Colors.orange),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _GoodState extends StatelessWidget {
  const _GoodState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        'Todos los eventos presentan buena asistencia.',
        style: TextStyle(color: Colors.green),
      ),
    );
  }
}
