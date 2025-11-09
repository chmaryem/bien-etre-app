import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ IMPORT CORRECT
import '../models/meal.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';

class MealListScreen extends StatefulWidget {
  final int userId;

  const MealListScreen({super.key, required this.userId});

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    final meals = await _dbHelper.getMealsByUser(widget.userId);
    setState(() {
      _meals = meals;
      _isLoading = false;
    });
  }

  int _getTodayCalories() {
    final today = DateTime.now();
    return _meals
        .where((meal) =>
    meal.dateTime.year == today.year &&
        meal.dateTime.month == today.month &&
        meal.dateTime.day == today.day)
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  Future<void> _deleteMeal(int id) async {
    await _dbHelper.deleteMeal(id);
    _loadMeals();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Repas supprimé')),
    );
  }

  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    String selectedType = 'Petit-déjeuner';
    DateTime selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un repas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du repas',
                    hintText: 'Ex: Salade César',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['Petit-déjeuner', 'Déjeuner', 'Dîner', 'Collation']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    hintText: 'Ex: 350',
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    // ✅ CORRECTION: DateFormat correctement utilisé
                    'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    caloriesController.text.isNotEmpty) {
                  final meal = Meal(
                    userId: widget.userId,
                    name: nameController.text,
                    type: selectedType,
                    calories: int.parse(caloriesController.text),
                    dateTime: selectedDateTime,
                  );
                  await _dbHelper.createMeal(meal);
                  Navigator.pop(context);
                  _loadMeals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repas ajouté')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Repas'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMeals,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Calories du jour',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_getTodayCalories()} kcal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _meals.isEmpty
                ? const Center(
              child: Text(
                'Aucun repas enregistré\nCliquez sur + pour ajouter',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(meal.type),
                      child: Text(
                        meal.type[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      meal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      // ✅ CORRECTION: DateFormat correctement utilisé
                      '${meal.type} • ${DateFormat('dd/MM/yyyy HH:mm').format(meal.dateTime)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${meal.calories} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () => _deleteMeal(meal.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Petit-déjeuner':
        return Colors.orange;
      case 'Déjeuner':
        return Colors.blue;
      case 'Dîner':
        return Colors.purple;
      case 'Collation':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}