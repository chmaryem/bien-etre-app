import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../database/database_helper.dart';
import '../models/meal.dart';
import '../models/user_goal.dart';
import 'meal_list_improved_screen.dart';
import 'goal_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final int _currentUserId = 1;

  int _todayCalories = 0;
  int _todayMeals = 0;
  bool _isLoading = true;
  UserGoal? _calorieGoal;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Liste de citations motivantes
  final List<Map<String, String>> _quotes = [
    {
      'text': 'Prends soin de ton corps, c\'est le seul endroit où tu es obligé de vivre.',
      'author': 'Jim Rohn'
    },
    {
      'text': 'La santé est la vraie richesse, pas les pièces d\'or et d\'argent.',
      'author': 'Mahatma Gandhi'
    },
    {
      'text': 'Ton corps peut tout supporter. C\'est ton esprit que tu dois convaincre.',
      'author': 'Anonyme'
    },
    {
      'text': 'Mange bien, bouge ton corps, reste hydraté, dors suffisamment.',
      'author': 'Conseil santé'
    },
    {
      'text': 'Chaque petit pas compte vers une meilleure version de toi-même.',
      'author': 'Anonyme'
    },
    {
      'text': 'La nourriture que tu manges peut être la médecine la plus puissante.',
      'author': 'Hippocrate'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayData();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Charger tous les repas de l'utilisateur
    final allMeals = await _dbHelper.getMealsByUser(_currentUserId);

    // Filtrer les repas d'aujourd'hui
    final todayMeals = allMeals.where((meal) {
      final mealDate = DateTime(
        meal.dateTime.year,
        meal.dateTime.month,
        meal.dateTime.day,
      );
      return mealDate.isAtSameMomentAs(today);
    }).toList();

    // Charger l'objectif calorique
    final goal = await _dbHelper.getActiveUserGoalByUserAndType(_currentUserId, 'calories');

    setState(() {
      _todayMeals = todayMeals.length;
      _todayCalories = todayMeals.fold(0, (sum, meal) => sum + meal.calories);
      _calorieGoal = goal;
      _isLoading = false;
    });

    // Debug
    print('📅 Date aujourd\'hui: $today');
    print('🍽️ Repas trouvés: ${todayMeals.length}');
    print('🔥 Calories totales: $_todayCalories');
    print('🎯 Objectif: ${goal?.targetValue ?? "Non défini"}');
  }

  Map<String, String> _getRandomQuote() {
    final random = Random();
    return _quotes[random.nextInt(_quotes.length)];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bonjour';
    } else if (hour < 18) {
      return 'Bon après-midi';
    } else {
      return 'Bonsoir';
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _getRandomQuote();
    final greeting = _getGreeting();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Bouton pour définir l'objectif
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalSettingsScreen(),
                ),
              );
              if (result == true) {
                _loadTodayData();
              }
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
              Colors.teal.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // En-tête avec emoji et salutation
                    Text(
                      '👋 $greeting !',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Citation motivante
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            quote['text']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '— ${quote['author']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🎯 PROGRESSION VERS L'OBJECTIF
                    if (_calorieGoal != null)
                      _buildGoalProgress()
                    else
                      _buildNoGoalCard(),

                    const SizedBox(height: 40),

                    // Résumé du jour
                    const Text(
                      '📊 Aujourd\'hui',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                        : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.local_fire_department,
                            label: 'Calories',
                            value: '$_todayCalories',
                            unit: 'kcal',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.restaurant,
                            label: 'Repas',
                            value: '$_todayMeals',
                            unit: 'enregistrés',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Bouton principal
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MealListImprovedScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _loadTodayData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Voir mes repas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.green.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bouton secondaire
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MealListImprovedScreen(),
                            ),
                          );
                          if (result == true && mounted) {
                            _loadTodayData();
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text(
                          'Ajouter un repas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget de progression vers l'objectif
  Widget _buildGoalProgress() {
    final targetCalories = _calorieGoal!.targetValue.toInt();
    final percentage = (_todayCalories / targetCalories * 100).clamp(0, 100);
    final isGoalReached = _todayCalories >= targetCalories;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎯 Objectif du jour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalSettingsScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadTodayData();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cercle de progression
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isGoalReached ? Colors.amber : Colors.white,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_todayCalories / $targetCalories',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Message de statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isGoalReached
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isGoalReached
                  ? '🎉 Objectif atteint !'
                  : 'Encore ${targetCalories - _todayCalories} kcal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isGoalReached ? Colors.amber.shade100 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget si pas d'objectif défini
  Widget _buildNoGoalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.flag_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pas d\'objectif défini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez votre objectif calorique quotidien',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalSettingsScreen(),
                ),
              );
              if (result == true) {
                _loadTodayData();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Définir un objectif'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}