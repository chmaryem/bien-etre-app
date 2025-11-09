import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../config/theme.dart';
import '../models/habitude.dart';
import '../store/habits_store.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  late Future<_StatsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_StatsData> _loadData() async {
    final store = Provider.of<HabitsStore>(context, listen: false);
    final habits = await store.getAllHabitudes();

    // totaux
    final totalHabits = habits.length;

    // accomplis aujourd'hui
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    int doneToday = 0;
    for (final h in habits) {
      final ok = await store.isHabitudeAccomplie(h.id!, todayNorm);
      if (ok) doneToday++;
    }

    // histogramme 7 derniers jours par habitude
    final start = todayNorm.subtract(const Duration(days: 6));
    final end = todayNorm.add(const Duration(days: 1)); // inclusif
    final Map<int, int> countByHabit = {for (final h in habits) h.id!: 0};

    for (final h in habits) {
      final histo = await store.getHistoriqueByHabitude(h.id!);
      for (final e in histo) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        final inRange = !d.isBefore(start) && d.isBefore(end);
        if (inRange && e.accompli) {
          countByHabit[h.id!] = (countByHabit[h.id!] ?? 0) + 1;
        }
      }
    }

    // Couleurs harmonisées (palettes bleu & teal, proches du thème)
    final List<Color> palette = [
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.cyan.shade500,
      Colors.lightBlue.shade600,
      Colors.blueGrey.shade400,
      Colors.teal.shade600,
      Colors.indigo.shade300,
    ];

    final bars = <_BarItem>[];
    for (int i = 0; i < habits.length; i++) {
      final h = habits[i];
      final v = countByHabit[h.id!] ?? 0;
      bars.add(
        _BarItem(
          label: h.nom,
          value: v.toDouble(),
          color: palette[i % palette.length],
        ),
      );
    }

    return _StatsData(
      totalHabits: totalHabits,
      doneToday: doneToday,
      bars: bars,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StatsData>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ligne de 2 cartes
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.table_chart_outlined,
                    title: 'Habitudes totales',
                    value: '${data.totalHabits}',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE8F0FF), // bleu très clair
                        Color(0xFFDDEBFF),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outlined,
                    title: "Accomplies aujourd'hui",
                    value: '${data.doneToday}',
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF1D6), // ambré très clair
                        Color(0xFFFFE7BE),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Accomplissements (7 derniers jours)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 2,
                        checkToShowHorizontalLine: (v) => v % 2 == 0,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, meta) => Text(
                              v.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.bars.length) {
                                return const SizedBox.shrink();
                              }
                              final label = data.bars[i].label;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  label.length > 8 ? '${label.substring(0, 8)}…' : label,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (int i = 0; i < data.bars.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: data.bars[i].value,
                                width: 18,
                                // barres rectangulaires
                                borderRadius: BorderRadius.zero,
                                color: data.bars[i].color,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- Cartes du haut (anti-overflow) ----
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Gradient gradient;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 8),
            // Texte flexible pour éviter tout overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre en gras, wraps s'il le faut
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    softWrap: true,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Modèles internes ----
class _StatsData {
  final int totalHabits;
  final int doneToday;
  final List<_BarItem> bars;

  _StatsData({
    required this.totalHabits,
    required this.doneToday,
    required this.bars,
  });
}

class _BarItem {
  final String label;
  final double value;
  final Color color;

  _BarItem({
    required this.label,
    required this.value,
    required this.color,
  });
}
