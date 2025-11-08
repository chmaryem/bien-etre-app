import 'package:flutter/material.dart';
import 'screens/add_goal_screen.dart';
import 'screens/goals_list_page.dart';
import 'screens/progress_dashboard.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Santé & Bien-être',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6A5AE0),
          secondary: Color(0xFF8C7BFF),
          surface: Color(0xFFF5F6FA),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      routes: {
        '/addGoal': (context) => const AddGoalScreen(),
        '/goalsList': (context) => const GoalsListPage(),
        '/progressDashboard': (context) => const ProgressDashboard(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

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
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // 🔹 Message de bienvenue
            Row(
              children: const [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFE0E0FF),
                  child: Text('',
                      style: TextStyle(
                        fontSize: 26,
                        color: Color(0xFF6A5AE0),
                        fontWeight: FontWeight.bold,
                      )),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(" ",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Bon après-midi ☀️",
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 Les cartes de catégories
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCategoryCard(
                    context, "Habitudes", Icons.check_circle, Colors.blueAccent),
                _buildCategoryCard(
                    context, "Alimentation", Icons.restaurant, Colors.green),
                _buildCategoryCard(
                    context, "Sommeil", Icons.nightlight_round, Colors.deepPurple),
                _buildCategoryCard(
                    context, "Entraînement", Icons.fitness_center, Colors.redAccent),
                _buildCategoryCard(
                    context, "Objectifs", Icons.flag, Colors.orangeAccent,
                    route: '/goalsList'),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 Carte "Astuce du jour"
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A5AE0), Color(0xFF8C7BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Astuce du jour 💡",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 8),
                  Text(
                    "Fais une pause et respire profondément.\nTon bien-être commence par une seule respiration.",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(height: 10),
                  Text("Ton objectif : Perdre poids",
                      style: TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon,
      Color color, {String? route}) {
    return InkWell(
      onTap: route != null
          ? () => Navigator.pushNamed(context, route)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
