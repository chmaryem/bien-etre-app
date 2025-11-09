import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/meal.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart'; // ✅ AJOUT: Import du modèle User

class StatisticsScreen extends StatefulWidget {
  final int userId; // ✅ AJOUT: userId passé en paramètre

  const StatisticsScreen({super.key, required this.userId}); // ✅ MODIF: Constructeur avec userId

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Meal> _meals = [];
  bool _isLoading = true;
  int _selectedDays = 7;
  // ✅ SUPPRIMER: final int _currentUserId = 1;
  // ✅ REMPLACER PAR:
  int get _currentUserId => widget.userId; // ✅ Utilise le userId passé en paramètre

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    final meals = await _dbHelper.getMealsByUser(_currentUserId);
    setState(() {
      _meals = meals;
      _isLoading = false;
    });
  }

  // Calculer calories par jour pour le graphique linéaire
  Map<DateTime, int> _getCaloriesPerDay() {
    Map<DateTime, int> caloriesMap = {};
    final now = DateTime.now();

    for (int i = _selectedDays - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      caloriesMap[date] = 0;
    }

    for (var meal in _meals) {
      final mealDate = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
      if (caloriesMap.containsKey(mealDate)) {
        caloriesMap[mealDate] = caloriesMap[mealDate]! + meal.calories;
      }
    }

    return caloriesMap;
  }

  // Calculer répartition par type de repas
  Map<String, int> _getMealTypeDistribution() {
    Map<String, int> distribution = {
      'Petit-déjeuner': 0,
      'Déjeuner': 0,
      'Dîner': 0,
      'Collation': 0,
    };

    for (var meal in _meals) {
      final key = DateFormat('yyyy-MM-dd').format(meal.dateTime);
      final now = DateTime.now();
      final daysAgo = now.difference(meal.dateTime).inDays;

      if (daysAgo < _selectedDays) {
        distribution[meal.type] = (distribution[meal.type] ?? 0) + meal.calories;
      }
    }

    return distribution;
  }

  // Statistiques générales
  int _getTotalCalories() {
    final now = DateTime.now();
    return _meals
        .where((meal) => now.difference(meal.dateTime).inDays < _selectedDays)
        .fold(0, (sum, meal) => sum + meal.calories);
  }

  int _getTotalMeals() {
    final now = DateTime.now();
    return _meals.where((meal) => now.difference(meal.dateTime).inDays < _selectedDays).length;
  }

  double _getAverageCalories() {
    final total = _getTotalCalories();
    return _selectedDays > 0 ? total / _selectedDays : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.green,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cartes de résumé
            _buildSummaryCards(),
            const SizedBox(height: 24),

            // Graphique linéaire : Calories par jour
            _buildSectionTitle('📊 Calories par jour'),
            const SizedBox(height: 16),
            _buildLineChart(),
            const SizedBox(height: 32),

            // Graphique circulaire : Répartition par type
            _buildSectionTitle('🥧 Répartition par type de repas'),
            const SizedBox(height: 16),
            _buildPieChart(),
            const SizedBox(height: 32),

            // Graphique en barres : Calories par type
            _buildSectionTitle('📊 Calories par type de repas'),
            const SizedBox(height: 16),
            _buildBarChart(),
          ],
        ),
      ),
    );
  }

  // Cartes de résumé
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Calories',
            '${_getTotalCalories()}',
            'kcal',
            Colors.orange,
            Icons.local_fire_department,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Moyenne/jour',
            '${_getAverageCalories().round()}',
            'kcal',
            Colors.blue,
            Icons.show_chart,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Repas',
            '${_getTotalMeals()}',
            'total',
            Colors.green,
            Icons.restaurant,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Graphique linéaire
  Widget _buildLineChart() {
    final caloriesPerDay = _getCaloriesPerDay();
    if (caloriesPerDay.isEmpty) {
      return _buildNoDataWidget();
    }

    final spots = caloriesPerDay.entries.map((entry) {
      final dayIndex = caloriesPerDay.keys.toList().indexOf(entry.key).toDouble();
      return FlSpot(dayIndex, entry.value.toDouble());
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < caloriesPerDay.length) {
                    final date = caloriesPerDay.keys.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Graphique circulaire
  Widget _buildPieChart() {
    final distribution = _getMealTypeDistribution();
    final total = distribution.values.fold(0, (sum, val) => sum + val);

    if (total == 0) {
      return _buildNoDataWidget();
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: distribution['Petit-déjeuner']!.toDouble(),
                    color: Colors.orange,
                    title: '${((distribution['Petit-déjeuner']! / total) * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: distribution['Déjeuner']!.toDouble(),
                    color: Colors.blue,
                    title: '${((distribution['Déjeuner']! / total) * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: distribution['Dîner']!.toDouble(),
                    color: Colors.purple,
                    title: '${((distribution['Dîner']! / total) * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: distribution['Collation']!.toDouble(),
                    color: Colors.green,
                    title: '${((distribution['Collation']! / total) * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem('Petit-déj', Colors.orange, distribution['Petit-déjeuner']!),
                _buildLegendItem('Déjeuner', Colors.blue, distribution['Déjeuner']!),
                _buildLegendItem('Dîner', Colors.purple, distribution['Dîner']!),
                _buildLegendItem('Collation', Colors.green, distribution['Collation']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int calories) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '$calories',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Graphique en barres
  Widget _buildBarChart() {
    final distribution = _getMealTypeDistribution();

    if (distribution.values.every((val) => val == 0)) {
      return _buildNoDataWidget();
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: distribution['Petit-déjeuner']!.toDouble(),
                  color: Colors.orange,
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: distribution['Déjeuner']!.toDouble(),
                  color: Colors.blue,
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: distribution['Dîner']!.toDouble(),
                  color: Colors.purple,
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
            BarChartGroupData(
              x: 3,
              barRods: [
                BarChartRodData(
                  toY: distribution['Collation']!.toDouble(),
                  color: Colors.green,
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = ['Petit-déj', 'Déjeuner', 'Dîner', 'Collation'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      titles[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}