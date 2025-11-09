import 'package:flutter/material.dart';
import '../models/sleep_model.dart';
import '../database/sleep_database_helper.dart';
import '../services/sleep_analytics.dart';

class SleepScreen extends StatefulWidget {
  final int userId;
  
  const SleepScreen({super.key, required this.userId});
  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> with SingleTickerProviderStateMixin {
  List<Sleep> sleeps = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    refreshSleeps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshSleeps() async {
    setState(() => isLoading = true);
    sleeps = await SleepDatabaseHelper.instance.readAllSleeps(widget.userId);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6A1B9A),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Gestion Sommeil',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6A1B9A),
                      Color(0xFF8E24AA),
                      Color(0xFFAB47BC),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bedtime_rounded,
                    size: 60,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(icon: Icon(Icons.list_alt), text: 'Historique'),
                Tab(icon: Icon(Icons.analytics), text: 'Analyses'),
              ],
            ),
          ),

          // Contenu selon l'onglet
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
              ),
            )
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoriqueTab(),
                  _buildAnalysesTab(),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSleepDialog(context),
        backgroundColor: const Color(0xFF6A1B9A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ==================== ONGLET HISTORIQUE ====================
  Widget _buildHistoriqueTab() {
    if (sleeps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Aucune donnée de sommeil',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Commencez à enregistrer vos nuits',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshSleeps,
      color: const Color(0xFF6A1B9A),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sleeps.length,
        itemBuilder: (context, index) => _buildSleepCard(sleeps[index]),
      ),
    );
  }

  // ==================== ONGLET ANALYSES ====================
  Widget _buildAnalysesTab() {
    if (sleeps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'Pas assez de données',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Enregistrez quelques nuits pour voir vos analyses',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final stats = SleepAnalytics.statistiquesGenerales(sleeps);
    final weekSleeps = sleeps.take(7).toList();
    final regularite = SleepAnalytics.regulariteHoraire(weekSleeps);
    final evolution = SleepAnalytics.evolutionSemaine(weekSleeps);
    final recommandations = SleepAnalytics.getRecommandations(sleeps);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques générales
          _buildSectionTitle('📊 Statistiques Générales'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Durée moyenne',
                  '${stats['dureeMoyenne'].toStringAsFixed(1)}h',
                  Icons.timer_outlined,
                  const Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Nuits totales',
                  '${stats['total']}',
                  Icons.calendar_today,
                  const Color(0xFF66BB6A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Min / Max',
                  '${stats['dureeMin'].toStringAsFixed(1)}h / ${stats['dureeMax'].toStringAsFixed(1)}h',
                  Icons.trending_up,
                  const Color(0xFFFFA726),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Objectifs
          _buildSectionTitle('🎯 Objectifs de Sommeil'),
          const SizedBox(height: 12),
          _buildObjectifCard('Objectif 7h+', stats['objectif7h']),
          const SizedBox(height: 8),
          _buildObjectifCard('Objectif 8h+', stats['objectif8h']),

          const SizedBox(height: 24),

          // Régularité Horaire
          _buildSectionTitle('⏰ Régularité Horaire (7 derniers jours)'),
          const SizedBox(height: 12),
          _buildRegulariteCard(regularite),

          const SizedBox(height: 24),

          // Évolution
          _buildSectionTitle('📈 Évolution de la Semaine'),
          const SizedBox(height: 12),
          _buildEvolutionCard(evolution),

          const SizedBox(height: 24),

          // Recommandations
          _buildSectionTitle('💡 Recommandations'),
          const SizedBox(height: 12),
          ...recommandations.map((rec) => _buildRecommandationCard(rec)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==================== WIDGETS DE CONSTRUCTION ====================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A1B9A),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectifCard(String title, double pourcentage) {
    final color = pourcentage >= 70
        ? const Color(0xFF66BB6A)
        : pourcentage >= 50
            ? const Color(0xFFFFA726)
            : const Color(0xFFEF5350);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${pourcentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pourcentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegulariteCard(Map<String, dynamic> regularite) {
    final score = regularite['score'] as double;
    final color = score >= 85
        ? const Color(0xFF66BB6A)
        : score >= 70
            ? const Color(0xFF42A5F5)
            : score >= 50
                ? const Color(0xFFFFA726)
                : const Color(0xFFEF5350);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                'Score de régularité',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  regularite['qualite'],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Score: ${score.toStringAsFixed(0)}/100',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coucher moyen',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      regularite['moyenneCoucher'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réveil moyen',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      regularite['moyenneReveil'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionCard(Map<String, dynamic> evolution) {
    final tendance = evolution['tendance'] as String;
    final color = tendance == 'En amélioration'
        ? const Color(0xFF66BB6A)
        : tendance == 'En baisse'
            ? const Color(0xFFEF5350)
            : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durée moyenne',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${evolution['dureeMoyenne'].toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      tendance == 'En amélioration'
                          ? Icons.trending_up
                          : tendance == 'En baisse'
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tendance,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildEvolutionDetail(
                  'Jours analysés',
                  '${evolution['joursAnalyses']}',
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildEvolutionDetail(
                  'Consistance',
                  evolution['consistance'],
                  Icons.bar_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionDetail(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRecommandationCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.4),
      ),
    );
  }

  Widget _buildSleepCard(Sleep sleep) {
    final duree = sleep.calculerDureeNuit();
    final qualite = sleep.qualifierSommeilParDuree();
    final colorHex = sleep.getQualityColor();
    final color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSleepDetails(sleep),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.bedtime_rounded, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(sleep.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            qualite,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${duree.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.nightlight_round,
                          size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(sleep.bedTime),
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.wb_sunny_rounded,
                          size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(sleep.wakeTime),
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (sleep.notes != null && sleep.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sleep.notes!,
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DIALOGS ====================

  void _showAddSleepDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay bedTime = const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A1B9A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Color(0xFF6A1B9A)),
              ),
              const SizedBox(width: 12),
              const Text('Ajouter un sommeil'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.grey[100],
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF6A1B9A)),
                  title: const Text('Date', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_formatDate(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.grey[100],
                  leading: const Icon(Icons.nightlight_round, color: Color(0xFF6A1B9A)),
                  title: const Text('Heure de coucher',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(bedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: bedTime,
                    );
                    if (time != null) {
                      setDialogState(() => bedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.grey[100],
                  leading: const Icon(Icons.wb_sunny, color: Color(0xFF6A1B9A)),
                  title: const Text('Heure de réveil',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(wakeTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: wakeTime,
                    );
                    if (time != null) {
                      setDialogState(() => wakeTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optionnel)',
                    hintText: 'Ex: Bien dormi, réveil difficile...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.note_outlined),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler',
                  style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final bedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  bedTime.hour,
                  bedTime.minute,
                );

                var wakeDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  wakeTime.hour,
                  wakeTime.minute,
                );

                if (wakeDateTime.isBefore(bedDateTime)) {
                  wakeDateTime = wakeDateTime.add(const Duration(days: 1));
                }

                final sleep = Sleep(
                  userId: widget.userId,
                  bedTime: bedDateTime,
                  wakeTime: wakeDateTime,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  date: selectedDate,
                );

                await SleepDatabaseHelper.instance.createSleep(sleep);
                refreshSleeps();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sommeil ajouté avec succès!'),
                    backgroundColor: Color(0xFF66BB6A),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepDetails(Sleep sleep) {
    final color = Color(
        int.parse(sleep.getQualityColor().substring(1), radix: 16) + 0xFF000000);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bedtime_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(_formatDate(sleep.date))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Durée',
                '${sleep.calculerDureeNuit().toStringAsFixed(1)} heures'),
            _buildDetailRow('Qualité', sleep.qualifierSommeilParDuree()),
            _buildDetailRow('Coucher', _formatTime(sleep.bedTime)),
            _buildDetailRow('Réveil', _formatTime(sleep.wakeTime)),
            if (sleep.notes != null && sleep.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(sleep.notes!),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmer'),
                  content: const Text(
                      'Voulez-vous vraiment supprimer ce sommeil?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Supprimer',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // ✅ FIX UNIQUE : passer aussi le userId
                await SleepDatabaseHelper.instance.deleteSleep(
                  sleep.id!,
                  userId: widget.userId,
                );
                refreshSleeps();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sommeil supprimé'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  // ==================== FORMATAGE ====================

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
