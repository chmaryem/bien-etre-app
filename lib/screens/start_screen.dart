import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/habitude.dart';
import '../services/notif_service.dart';

// Store (interface) — l’implémentation Sqflite est fournie dans main.dart via Provider
import '../store/habits_store.dart';

// Écrans
import 'habitude_form_screen.dart';
import 'habitude_detail_screen.dart';
import 'calendrier_screen.dart';
import 'statistiques_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initNotifsAndReschedule();
  }

  Future<void> _initNotifsAndReschedule() async {
    final notif = Provider.of<NotificationService>(context, listen: false);
    final store = Provider.of<HabitsStore>(context, listen: false);

    await notif.init();
    await notif.requestNotificationsPermission();

    final habits = await store.getAllHabitudes();

    for (final h in habits) {
      // sécurités : id non null + notif active + heure présente
      if ((h.id ?? -1) >= 0 &&
          h.notificationActive &&
          (h.heureNotification ?? '').isNotEmpty) {
        await notif.cancelForHabit(h.id!); // éviter les doublons
        await notif.scheduleDailySmart(
          idUnique: h.id!,
          titre: h.nom,
          corps: 'Il est l’heure: ${h.nom}',
          hhmm: h.heureNotification!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notif = Provider.of<NotificationService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Habitudes'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Outils notifications',
            icon: const Icon(Icons.notifications_outlined),
            onSelected: (value) async {
              switch (value) {
                case 'state':
                  final enabled = await notif.areNotificationsEnabled();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        enabled
                            ? '✅ Notifications AUTORISÉES pour cette app'
                            : '⛔ Notifications BLOQUÉES pour cette app.\nActive-les dans Paramètres Android > Applications > Habitude App > Notifications.',
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  break;

                case 'now':
                  {
                    final ok = await notif.areNotificationsEnabled();
                    if (!mounted) return;
                    if (!ok) {
                      _toastBlocked();
                      return;
                    }
                    await notif.showNowTest();
                    break;
                  }

                case 'in5_timer':
                  {
                    final ok = await notif.areNotificationsEnabled();
                    if (!mounted) return;
                    if (!ok) {
                      _toastBlocked();
                      return;
                    }
                    await notif.showIn5sViaTimer();
                    if (!mounted) return;
                    _snack('Test via Timer dans 5s (app au 1er plan).');
                    break;
                  }

                case 'in15_alarm':
                  {
                    final ok = await notif.areNotificationsEnabled();
                    if (!mounted) return;
                    if (!ok) {
                      _toastBlocked();
                      return;
                    }
                    await notif.scheduleInSeconds(15);
                    if (!mounted) return;
                    _snack('Test planifié via AlarmManager: ~15s (écran éteint accepté).');
                    break;
                  }

                case 'in1_zoned':
                  {
                    final ok = await notif.areNotificationsEnabled();
                    if (!mounted) return;
                    if (!ok) {
                      _toastBlocked();
                      return;
                    }
                    await notif.scheduleIn1Minute();
                    if (!mounted) return;
                    _snack('Test planifié: notification dans ~1 minute (AlarmManager).');
                    break;
                  }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'state', child: Text('État des permissions')),
              PopupMenuItem(value: 'now', child: Text('Test immédiat (show)')),
              PopupMenuItem(value: 'in5_timer', child: Text('Test 5s (Timer – foreground)')),
              PopupMenuItem(value: 'in15_alarm', child: Text('Test +15s (AlarmManager — écran éteint)')),
              PopupMenuItem(value: 'in1_zoned', child: Text('Test +1 min (AlarmManager)')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendrier',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistiques',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HabitudeFormScreen()),
          );
          if (created == true && mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle habitude'),
      )
          : null,
    );
  }

  void _toastBlocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications BLOQUÉES par le système.\nActive-les dans Paramètres Android > Applications > Habitude App > Notifications.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildAccueilTab();
      case 1:
        return const CalendrierScreen();      // <-- branché sur le vrai calendrier
      case 2:
        return const StatistiquesScreen();    // <-- branché sur les vraies stats
      default:
        return _buildAccueilTab();
    }
  }

  // Onglet Accueil
  Widget _buildAccueilTab() {
    final store = Provider.of<HabitsStore>(context);

    return FutureBuilder<List<Habitude>>(
      future: store.getAllHabitudes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final habitudes = snapshot.data ?? [];

        if (habitudes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.spa_outlined,
                    size: 80, color: AppTheme.textSecondaryColor),
                const SizedBox(height: 24),
                Text('Aucune habitude',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Commencez par créer votre première habitude !',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HabitudeFormScreen(),
                      ),
                    );
                    if (created == true && mounted) setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer ma première habitude'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: habitudes.length,
          itemBuilder: (context, index) {
            final h = habitudes[index];

            return Dismissible(
              key: ValueKey(h.id ?? index),
              direction: DismissDirection.horizontal,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Modifier', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Modifier
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HabitudeFormScreen(initial: h), // passe l’objet
                    ),
                  );
                  setState(() {});
                  return false;
                } else {
                  // Supprimer
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer cette habitude ?'),
                      content: Text('“${h.nom}” et son historique seront supprimés.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final store =
                    Provider.of<HabitsStore>(context, listen: false);
                    if ((h.id ?? -1) >= 0) {
                      await store.deleteHabitude(h.id!);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Habitude supprimée')),
                    );
                    return true;
                  }
                  return false;
                }
              },
              onDismissed: (_) => setState(() {}),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hexToColor(h.couleur).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        h.icone,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  title: Text(h.nom),
                  subtitle: Text(
                    (h.description ?? 'Aucune description') +
                        '  •  🔥 ${h.streakActuel}j (best ${h.meilleurStreak}j)',
                  ),
                  onTap: () async {
                    if ((h.id ?? -1) < 0) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HabitudeDetailScreen(habitudeId: h.id!),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {});
                  },
                  trailing: FutureBuilder<bool>(
                    future: (h.id == null)
                        ? Future.value(false)
                        : Provider.of<HabitsStore>(context, listen: false)
                        .isHabitudeAccomplie(h.id!, DateTime.now()),
                    builder: (context, doneSnap) {
                      final checked = doneSnap.data ?? false;
                      return Checkbox(
                        value: checked,
                        onChanged: (value) async {
                          final store =
                          Provider.of<HabitsStore>(context, listen: false);
                          if ((h.id ?? -1) < 0) return;
                          final newVal =
                          await store.toggleAccompliAujourdHui(h.id!);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(newVal
                                  ? 'Marquée accomplie ✅'
                                  : 'Marquée non accomplie'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
