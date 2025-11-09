import 'package:flutter/material.dart';
import 'screens/signup_screen.dart';
import 'services/notification_service.dart'; // Assure-toi que le chemin est correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les notifications avant de lancer l'app
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bien-être',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      home: const SignupScreen(),
    );
  }
}
