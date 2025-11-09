// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'config/theme.dart';
import 'services/notif_service.dart';
import 'screens/start_screen.dart'; // <- remplace l'ancien import

// Store (Sqflite)
import 'store/habits_store.dart';
import 'database/sqflite_habits_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  // Initialise la base
  final store = SqfliteHabitsStore();
  await store.init();

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final HabitsStore store;
  const MyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Expose l’interface abstraite → l’UI reste découplée
        Provider<HabitsStore>(create: (_) => store),
        Provider<NotificationService>(create: (_) => NotificationService()..init()),
      ],
      child: MaterialApp(
        title: 'Habitude App',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const StartScreen(), // <- remplace HomeScreen()
      ),
    );
  }
}
