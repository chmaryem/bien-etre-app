import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import 'statistics_screen.dart';
import '../models/user_model.dart'; // ✅ AJOUT: Import du modèle User

class MealListImprovedScreen extends StatefulWidget {
  final int userId; // ✅ AJOUT: userId passé en paramètre

  const MealListImprovedScreen({super.key, required this.userId}); // ✅ MODIF: Constructeur avec userId

  @override
  State<MealListImprovedScreen> createState() => _MealListImprovedScreenState();
}

class _MealListImprovedScreenState extends State<MealListImprovedScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Map<String, List<Meal>> _mealsByDate = {};
  bool _isLoading = true;
  int _selectedDays = 7;
  // ✅ SUPPRIMER: final int _currentUserId = 1;
  // ✅ REMPLACER PAR:
  int get _currentUserId => widget.userId; // ✅ Utilise le userId passé en paramètre

  // ✅ AJOUT : Variable pour tracker si des modifications ont été faites
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    final meals = await _dbHelper.getMealsByUser(_currentUserId);

    final Map<String, List<Meal>> grouped = {};
    final now = DateTime.now();

    for (int i = 0; i < _selectedDays; i++) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped[key] = [];
    }

    for (var meal in meals) {
      final key = DateFormat('yyyy-MM-dd').format(meal.dateTime);
      if (grouped.containsKey(key)) {
        grouped[key]!.add(meal);
      }
    }

    setState(() {
      _mealsByDate = grouped;
      _isLoading = false;
    });
  }

  int _getCaloriesForDate(String dateKey) {
    return _mealsByDate[dateKey]
        ?.fold<int>(0, (sum, meal) => sum + meal.calories) ??
        0;
  }

  int _getWeekCalories() {
    return _mealsByDate.values
        .expand((meals) => meals)
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  // ✅ MODIFIÉ : Marquer qu'il y a eu des changements
  Future<void> _confirmDeleteMeal(int id, String mealName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "$mealName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteMeal(id);
      _hasChanges = true; // ✅ AJOUT
      _loadMeals();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repas supprimé')),
      );
    }
  }

  // ✅ MODIFIÉ : Marquer qu'il y a eu des changements
  void _showEditMealDialog(Meal meal) {
    final nameController = TextEditingController(text: meal.name);
    final caloriesController = TextEditingController(text: meal.calories.toString());
    String selectedType = meal.type;
    DateTime selectedDateTime = meal.dateTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le repas'),
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
                  final updatedMeal = Meal(
                    id: meal.id,
                    userId: _currentUserId, // ✅ Utilise le userId dynamique
                    name: nameController.text,
                    type: selectedType,
                    calories: int.parse(caloriesController.text),
                    dateTime: selectedDateTime,
                  );
                  await _dbHelper.updateMeal(updatedMeal);
                  _hasChanges = true; // ✅ AJOUT
                  Navigator.pop(context);
                  _loadMeals();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repas modifié')),
                  );
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MODIFIÉ : Marquer qu'il y a eu des changements
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
                    userId: _currentUserId, // ✅ Utilise le userId dynamique
                    name: nameController.text,
                    type: selectedType,
                    calories: int.parse(caloriesController.text),
                    dateTime: selectedDateTime,
                  );
                  await _dbHelper.createMeal(meal);
                  _hasChanges = true; // ✅ AJOUT
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
    return WillPopScope( // ✅ AJOUT : Intercepter le bouton retour
      onWillPop: () async {
        Navigator.pop(context, _hasChanges); // ✅ Retourner true si des changements
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Repas'),
          backgroundColor: Colors.green,
          leading: IconButton( // ✅ AJOUT : Gérer le bouton retour manuellement
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatisticsScreen(userId: _currentUserId)), // ✅ MODIF: Passer userId
                );
              },
            ),
            PopupMenuButton<int>(
              icon: const Icon(Icons.filter_list),
              onSelected: (days) {
                setState(() => _selectedDays = days);
                _loadMeals();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 7, child: Text('7 derniers jours')),
                const PopupMenuItem(value: 14, child: Text('14 derniers jours')),
                const PopupMenuItem(value: 30, child: Text('30 derniers jours')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadMeals,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                  Text(
                    'Calories des $_selectedDays derniers jours',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_getWeekCalories()} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Moyenne: ${(_getWeekCalories() / _selectedDays).round()} kcal/jour',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _mealsByDate.length,
                itemBuilder: (context, index) {
                  final dateKey = _mealsByDate.keys.elementAt(index);
                  final date = DateTime.parse(dateKey);
                  final meals = _mealsByDate[dateKey]!;
                  final totalCalories = _getCaloriesForDate(dateKey);
                  final isToday = DateFormat('yyyy-MM-dd')
                      .format(DateTime.now()) ==
                      dateKey;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: isToday ? 4 : 2,
                    color: isToday ? Colors.green.shade50 : null,
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: isToday
                            ? Colors.green
                            : Colors.grey.shade300,
                        child: Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        isToday
                            ? "Aujourd'hui"
                            : DateFormat('EEEE d MMMM', 'fr_FR')
                            .format(date),
                        style: TextStyle(
                          fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '$totalCalories kcal • ${meals.length} repas',
                        style: TextStyle(
                          color: isToday ? Colors.green.shade700 : null,
                        ),
                      ),
                      children: meals.isEmpty
                          ? [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Aucun repas ce jour',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      ]
                          : meals.map((meal) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                            _getTypeColor(meal.type),
                            radius: 20,
                            child: Text(
                              meal.type[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            meal.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${meal.type} • ${DateFormat('HH:mm').format(meal.dateTime)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${meal.calories} kcal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                onPressed: () => _showEditMealDialog(meal),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _confirmDeleteMeal(meal.id!, meal.name),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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