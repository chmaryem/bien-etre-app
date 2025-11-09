import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../database/database_helper.dart';

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({Key? key}) : super(key: key);

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  late Future<List<Goal>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _goalsFuture = DatabaseHelper.instance.getGoals();
  }

  // Calculer la progression globale
  Map<String, dynamic> _calculateOverallProgress(List<Goal> goals) {
    if (goals.isEmpty) return {'completed': 0, 'inProgress': 0, 'notStarted': 0, 'avgProgress': 0.0};

    int completed = 0;
    int inProgress = 0;
    int notStarted = 0;
    double totalProgress = 0.0;

    for (var goal in goals) {
      double progress = goal.targetValue > 0 ? (goal.currentValue / goal.targetValue) : 0.0;
      totalProgress += progress;

      if (progress >= 1.0) {
        completed++;
      } else if (progress > 0.0) {
        inProgress++;
      } else {
        notStarted++;
      }
    }

    return {
      'completed': completed,
      'inProgress': inProgress,
      'notStarted': notStarted,
      'avgProgress': (totalProgress / goals.length).clamp(0.0, 1.0),
    };
  }

  // Grouper les objectifs par type
  Map<String, List<Goal>> _groupByType(List<Goal> goals) {
    Map<String, List<Goal>> grouped = {};
    for (var goal in goals) {
      if (!grouped.containsKey(goal.type)) {
        grouped[goal.type] = [];
      }
      grouped[goal.type]!.add(goal);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFF6A5AE0), Color(0xFF8C7BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Progression',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: FutureBuilder<List<Goal>>(
        future: _goalsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6A5AE0)),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune donnée disponible',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez des objectifs pour voir vos statistiques',
                    style: TextStyle(color: Colors.black38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final goals = snapshot.data!;
          final stats = _calculateOverallProgress(goals);
          final groupedGoals = _groupByType(goals);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte de progression globale
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A5AE0).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Progression Globale',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: stats['avgProgress'],
                              strokeWidth: 12,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${(stats['avgProgress'] * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Complété',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip('✓ Terminés', stats['completed'], Colors.white),
                          _buildStatChip('⏳ En cours', stats['inProgress'], Colors.white70),
                          _buildStatChip('○ Non démarrés', stats['notStarted'], Colors.white54),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Titre "Progression par type"
                const Text(
                  'Progression par Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Cartes par type d'objectif
                ...groupedGoals.entries.map((entry) {
                  final type = entry.key;
                  final typeGoals = entry.value;
                  final typeProgress = typeGoals.map((g) =>
                  g.targetValue > 0 ? (g.currentValue / g.targetValue) : 0.0
                  ).reduce((a, b) => a + b) / typeGoals.length;

                  return _buildTypeProgressCard(
                    type,
                    typeGoals.length,
                    typeProgress,
                    _getTypeIcon(type),
                    _getTypeColor(type),
                  );
                }),

                const SizedBox(height: 24),

                // Liste détaillée des objectifs
                const Text(
                  'Détails des Objectifs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                ...goals.map((goal) {
                  final progress = goal.targetValue > 0
                      ? (goal.currentValue / goal.targetValue).clamp(0.0, 1.0)
                      : 0.0;
                  return _buildGoalProgressCard(goal, progress);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeProgressCard(String type, int count, double progress, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$count objectif${count > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% complété',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(Goal goal, double progress) {
    final color = _getTypeColor(goal.type);
    final daysRemaining = _calculateDaysRemaining(goal.endDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.type,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentValue} / ${goal.targetValue}',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              if (daysRemaining != null)
                Text(
                  daysRemaining > 0
                      ? '$daysRemaining jours restants'
                      : 'Échéance dépassée',
                  style: TextStyle(
                    color: daysRemaining > 0 ? Colors.black54 : Colors.redAccent,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sommeil':
        return Icons.nightlight_round;
      case 'sport':
        return Icons.fitness_center;
      case 'poids':
        return Icons.monitor_weight;
      case 'masse musculaire':
        return Icons.accessibility_new;
      default:
        return Icons.flag;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sommeil':
        return Colors.deepPurple;
      case 'sport':
        return Colors.redAccent;
      case 'poids':
        return Colors.green;
      case 'masse musculaire':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF6A5AE0);
    }
  }

  int? _calculateDaysRemaining(String endDate) {
    try {
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      return end.difference(now).inDays;
    } catch (e) {
      return null;
    }
  }
}