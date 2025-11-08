import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'dart:math' as math;

class StatsScreen extends StatefulWidget {
  final User user;

  const StatsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = '7 jours';
  
  // Données simulées pour les statistiques
  final List<Map<String, dynamic>> _weeklyData = [
    {'day': 'Lun', 'value': 75},
    {'day': 'Mar', 'value': 85},
    {'day': 'Mer', 'value': 60},
    {'day': 'Jeu', 'value': 90},
    {'day': 'Ven', 'value': 70},
    {'day': 'Sam', 'value': 95},
    {'day': 'Dim', 'value': 80},
  ];

  double _calculateBMI() {
    if (widget.user.poids == null || widget.user.taille == null) {
      return 0.0;
    }
    final heightInMeters = widget.user.taille! / 100;
    return widget.user.poids! / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Insuffisant';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Surpoids';
    return 'Obésité';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _calculateBMI();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text('Mes Statistiques'),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de période
              _buildPeriodSelector(),
              const SizedBox(height: 20),

              // Carte d'informations personnelles
              _buildPersonalInfoCard(),
              const SizedBox(height: 20),

              // IMC (BMI)
              if (bmi > 0) ...[
                _buildBMICard(bmi),
                const SizedBox(height: 20),
              ],

              // Graphique de progression
              _buildProgressChart(),
              const SizedBox(height: 20),

              // Statistiques rapides
              _buildQuickStats(),
              const SizedBox(height: 20),

              // Objectifs atteints
              _buildAchievements(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['7 jours', '30 jours', '3 mois', '1 an'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF667eea)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  widget.user.nom.isNotEmpty
                      ? widget.user.nom[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                  Icons.cake,
                  widget.user.age != null
                      ? '${widget.user.age} ans'
                      : 'N/A'),
              _buildInfoItem(
                  Icons.height,
                  widget.user.taille != null
                      ? '${widget.user.taille} cm'
                      : 'N/A'),
              _buildInfoItem(
                  Icons.monitor_weight,
                  widget.user.poids != null
                      ? '${widget.user.poids} kg'
                      : 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBMICard(double bmi) {
    final category = _getBMICategory(bmi);
    final color = _getBMIColor(bmi);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Indice de Masse Corporelle (IMC)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
              Icon(Icons.analytics, color: color),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (bmi / 40).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progression hebdomadaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF48bb78).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: Color(0xFF48bb78), size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+12%',
                      style: TextStyle(
                        color: Color(0xFF48bb78),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyData.map((data) {
                return _buildChartBar(data['day'], data['value']);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, int value) {
    final maxValue = 100;
    final height = (value / maxValue) * 120;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value%',
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2d3748),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                Icons.local_fire_department,
                '1,245',
                'Calories',
                const Color(0xFFf56565),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                Icons.directions_walk,
                '8,432',
                'Pas',
                const Color(0xFF48bb78),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                Icons.bedtime,
                '7.5h',
                'Sommeil',
                const Color(0xFF9f7aea),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                Icons.water_drop,
                '2.1L',
                'Eau',
                const Color(0xFF4299e1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFed8936), size: 24),
              SizedBox(width: 8),
              Text(
                'Objectifs atteints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2d3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAchievementItem(
            '🔥 Série de 7 jours',
            'Continue comme ça !',
            0.7,
            const Color(0xFFf56565),
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            '💪 10 entraînements',
            '8/10 complétés',
            0.8,
            const Color(0xFF48bb78),
          ),
          const SizedBox(height: 12),
          _buildAchievementItem(
            '🎯 Objectif mensuel',
            '15/30 jours',
            0.5,
            const Color(0xFF667eea),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
      String title, String subtitle, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2d3748),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}