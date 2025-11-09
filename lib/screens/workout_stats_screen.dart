import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class WorkoutStatsScreen extends StatefulWidget {
  const WorkoutStatsScreen({super.key});

  @override
  State<WorkoutStatsScreen> createState() => _WorkoutStatsScreenState();
}

class _WorkoutStatsScreenState extends State<WorkoutStatsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance; // ✅ CORRECTION: Utilisez .instance

  double totalCalories = 0;
  Map<String, double> workoutDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  _loadStats() async {
    final calories = await dbHelper.getTotalCaloriesThisWeek();
    final distribution = await dbHelper.getWorkoutDistribution();

    setState(() {
      totalCalories = calories;
      workoutDistribution = distribution;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques d\'Entraînement'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Calories Brûlées Cette Semaine',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${totalCalories.toInt()} cal',
                      style: const TextStyle(fontSize: 24, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Répartition des Entraînements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: workoutDistribution.isEmpty
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : ListView(
                children: workoutDistribution.entries.map((entry) {
                  return Card(
                    child: ListTile(
                      title: Text(entry.key),
                      trailing: Text('${entry.value.toInt()} min'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}