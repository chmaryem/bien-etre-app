import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../database/database_helper.dart';
import 'add_workout_screen.dart';
import 'workout_stats_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  List<Workout> workouts = [];
  final DatabaseHelper dbHelper = DatabaseHelper.instance; // ✅ CORRECTION: Utilisez .instance

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  _loadWorkouts() async {
    final allWorkouts = await dbHelper.getWorkouts();
    setState(() {
      workouts = allWorkouts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Activités Sportives'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutStatsScreen()),
              );
            },
          ),
        ],
      ),
      body: workouts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            const Text(
              'Aucune activité enregistrée',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              'Commencez par ajouter votre première activité !',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: _getWorkoutIcon(workout.type),
              title: Text(
                workout.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${workout.duration} min • ${workout.calories} cal'),
                  Text(
                    '${workout.date.day}/${workout.date.month}/${workout.date.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getIntensityBadge(workout.intensity),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteWorkout(workout.id!),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWorkoutScreen(workout: workout),
                  ),
                ).then((_) => _loadWorkouts());
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddWorkoutScreen()),
          ).then((_) => _loadWorkouts());
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _getWorkoutIcon(String type) {
    switch (type.toLowerCase()) {
      case 'course':
        return const Icon(Icons.directions_run, color: Colors.green);
      case 'musculation':
        return const Icon(Icons.fitness_center, color: Colors.orange);
      case 'yoga':
        return const Icon(Icons.self_improvement, color: Colors.purple);
      case 'natation':
        return const Icon(Icons.pool, color: Colors.blue);
      default:
        return const Icon(Icons.sports, color: Colors.grey);
    }
  }

  Widget _getIntensityBadge(String intensity) {
    Color color;
    switch (intensity.toLowerCase()) {
      case 'élevée':
        color = Colors.red;
        break;
      case 'moyenne':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        intensity,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  _deleteWorkout(int id) async {
    await dbHelper.deleteWorkout(id);
    _loadWorkouts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activité supprimée')),
    );
  }
}