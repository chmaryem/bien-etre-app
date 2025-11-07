import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Bonne matinée 🌤️";
    } else if (hour < 18) {
      return "Bon après-midi ☀️";
    } else {
      return "Bonne soirée 🌙";
    }
  }

  // ✅ Méthode pour naviguer vers le profil et récupérer les données mises à jour
  Future<void> _navigateToProfile() async {
    final updatedUser = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(user: currentUser),
      ),
    );

    // Mettre à jour l'utilisateur si des modifications ont été faites
    if (updatedUser != null && updatedUser is User) {
      setState(() {
        currentUser = updatedUser;
      });
    }
  }

  // ✅ Méthode pour naviguer vers les statistiques
  void _navigateToStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(user: currentUser),
      ),
    );
  }

  // ✅ Dialogue de confirmation pour se déconnecter
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // ✅ Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildMotivationCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: _navigateToProfile,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
            child: Text(
              currentUser.nom.isNotEmpty 
                  ? currentUser.nom[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${currentUser.nom} ! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getGreetingMessage(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        // Première ligne : 2 cartes
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.check_circle_outline,
                "Habitudes",
                const Color(0xFF667eea),
                () => _showComingSoon("Habitudes"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                Icons.restaurant_menu,
                "Alimentation",
                const Color(0xFF48bb78),
                () => _showComingSoon("Alimentation"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Deuxième ligne : 2 cartes
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.bedtime,
                "Sommeil",
                const Color(0xFF9f7aea),
                () => _showComingSoon("Sommeil"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                Icons.fitness_center,
                "Entraînement",
                const Color(0xFFf56565),
                () => _showComingSoon("Entraînement"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Troisième ligne : 1 carte centrée
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 2,
              child: _buildActionCard(
                Icons.flag_outlined,
                "Objectifs",
                const Color(0xFFed8936),
                () => _showComingSoon("Objectifs"),
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature : Bientôt disponible ! 🚀'),
        backgroundColor: const Color(0xFF667eea),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildMotivationCard() {
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
          const Text(
            "Astuce du jour 💡",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Fais une pause et respire profondément.\nTon bien-être commence par une seule respiration.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          if (currentUser.objectif != null && currentUser.objectif!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ton objectif : ${currentUser.objectif}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF667eea),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 4) {
          _navigateToProfile();
        } else if (index == 1) {
          // ✅ Navigation vers les statistiques
          _navigateToStats();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Agenda"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alertes"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ],
    );
  }
}