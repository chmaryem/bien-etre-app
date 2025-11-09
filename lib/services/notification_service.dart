import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/goal.dart';
import '../database/database_helper.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  // Initialiser les notifications
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Gérer le clic sur la notification
      },
    );

    // Demander les permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Planifier des notifications pour un objectif
  Future<void> scheduleGoalNotifications(Goal goal) async {
    // Annuler les anciennes notifications pour cet objectif
    await cancelGoalNotifications(goal.id!);

    // Notification de rappel quotidien
    await _scheduleDailyReminder(goal);

    // Notification de motivation en milieu de semaine
    await _scheduleWeeklyMotivation(goal);

    // Notification d'approche de l'échéance
    await _scheduleDeadlineReminder(goal);

    // Notification de progression
    await _scheduleProgressCheck(goal);
  }

  // Rappel quotidien personnalisé selon le type d'objectif
  Future<void> _scheduleDailyReminder(Goal goal) async {
    final time = _getOptimalTimeForGoalType(goal.type);
    final message = _getDailyMessage(goal);

    await _notifications.zonedSchedule(
      goal.id! * 10 + 1, // ID unique
      '📌 ${goal.title}',
      message,
      _nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Rappels quotidiens',
          channelDescription: 'Rappels quotidiens pour vos objectifs',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(message),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Motivation hebdomadaire
  Future<void> _scheduleWeeklyMotivation(Goal goal) async {
    final progress = goal.targetValue > 0
        ? (goal.currentValue / goal.targetValue * 100).toInt()
        : 0;
    final message = _getMotivationalMessage(goal, progress);

    await _notifications.zonedSchedule(
      goal.id! * 10 + 2,
      '💪 Continue comme ça !',
      message,
      _nextInstanceOfDay(DateTime.wednesday, 18, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_motivation',
          'Motivation hebdomadaire',
          channelDescription: 'Messages de motivation pour vos objectifs',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(message),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Rappel d'échéance
  Future<void> _scheduleDeadlineReminder(Goal goal) async {
    try {
      final endDate = DateTime.parse(goal.endDate);
      final now = DateTime.now();
      final daysRemaining = endDate.difference(now).inDays;

      if (daysRemaining > 7) {
        // Notification 7 jours avant
        final reminderDate = endDate.subtract(const Duration(days: 7));
        if (reminderDate.isAfter(now)) {
          await _notifications.zonedSchedule(
            goal.id! * 10 + 3,
            '⏰ Échéance proche',
            'Plus que 7 jours pour "${goal.title}" ! Tu y es presque 💪',
            tz.TZDateTime.from(reminderDate, tz.local),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'deadline_reminder',
                'Rappels d\'échéance',
                channelDescription: 'Notifications pour les échéances proches',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      if (daysRemaining > 1 && daysRemaining <= 3) {
        // Notification de dernière ligne droite
        await showNotification(
          goal.id! * 10 + 4,
          '🏁 Dernière ligne droite !',
          'Il reste $daysRemaining jours pour "${goal.title}". Donne tout ! 🔥',
        );
      }
    } catch (e) {
      // Date invalide
    }
  }

  // Vérification de progression et notification immédiate
  Future<void> checkProgressAndNotify(Goal goal) async {
    final progress = goal.targetValue > 0
        ? (goal.currentValue / goal.targetValue * 100).toInt()
        : 0;

    print('🔔 Vérification progression: ${goal.title} - $progress%'); // Debug

    // Notifications de jalons - envoyées immédiatement
    if (progress >= 25 && progress < 50) {
      await showNotification(
        goal.id! * 10 + 5,
        '🎯 25% accompli !',
        'Excellent début pour "${goal.title}" ! Continue sur cette lancée 🌟',
      );
    } else if (progress >= 50 && progress < 75) {
      await showNotification(
        goal.id! * 10 + 6,
        '🎊 À mi-chemin !',
        'Déjà 50% de "${goal.title}" ! Tu es incroyable 💪',
      );
    } else if (progress >= 75 && progress < 90) {
      await showNotification(
        goal.id! * 10 + 7,
        '🔥 75% complété !',
        'Plus que 25% pour "${goal.title}" ! Le finish est proche 🏆',
      );
    } else if (progress >= 90 && progress < 100) {
      await showNotification(
        goal.id! * 10 + 8,
        '🚀 Presque fini !',
        '90% de "${goal.title}" ! Tu vas y arriver 🌈',
      );
    } else if (progress >= 100) {
      await showNotification(
        goal.id! * 10 + 9,
        '🏆 OBJECTIF ATTEINT !',
        'Félicitations ! Tu as complété "${goal.title}" ! 🎉🎊',
      );
    }
  }

  // Vérification de progression (pour planification future)
  Future<void> _scheduleProgressCheck(Goal goal) async {
    final progress = goal.targetValue > 0
        ? (goal.currentValue / goal.targetValue * 100).toInt()
        : 0;

    // Note: Cette méthode est utilisée pour la planification
    // Les notifications de jalon sont maintenant gérées par checkProgressAndNotify()
    // qui est appelée immédiatement lors de la mise à jour d'un objectif
  }

  // Notification immédiate (méthode publique pour usage externe)
  Future<void> showNotification(int id, String title, String body) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notification',
          'Notifications instantanées',
          channelDescription: 'Notifications importantes',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  // Annuler les notifications d'un objectif
  Future<void> cancelGoalNotifications(int goalId) async {
    for (int i = 1; i <= 9; i++) {
      await _notifications.cancel(goalId * 10 + i);
    }
  }

  // Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Mettre à jour toutes les notifications selon les objectifs
  Future<void> updateAllNotifications() async {
    final goals = await DatabaseHelper.instance.getGoals();
    for (var goal in goals) {
      await scheduleGoalNotifications(goal);
    }
  }

  // Messages personnalisés selon le type d'objectif
  String _getDailyMessage(Goal goal) {
    final progress = goal.targetValue > 0
        ? (goal.currentValue / goal.targetValue * 100).toInt()
        : 0;

    switch (goal.type.toLowerCase()) {
      case 'sommeil':
        return 'N\'oublie pas ton objectif de sommeil ! $progress% accompli 🌙';
      case 'sport':
        return 'C\'est l\'heure de bouger ! Objectif sport à $progress% 🏋️';
      case 'poids':
        return 'Reste motivé(e) ! Objectif poids à $progress% ⚖️';
      case 'masse musculaire':
        return 'Continue ton entraînement ! $progress% vers ton objectif 💪';
      default:
        return 'Continue ! Tu es à $progress% de ton objectif 🎯';
    }
  }

  String _getMotivationalMessage(Goal goal, int progress) {
    final messages = [
      'Tu fais un travail formidable sur "${goal.title}" ! ($progress%)',
      'Bravo pour ta persévérance ! "${goal.title}" progresse bien 🌟',
      'Chaque petit pas compte ! Continue avec "${goal.title}" 👏',
      'Tu es sur la bonne voie ! "${goal.title}" avance bien 🚀',
      'Fier/Fière de toi ! "${goal.title}" : $progress% accompli 💫',
    ];
    return messages[progress % messages.length];
  }

  // Heure optimale selon le type d'objectif
  _OptimalTime _getOptimalTimeForGoalType(String type) {
    switch (type.toLowerCase()) {
      case 'sommeil':
        return _OptimalTime(21, 0); // 21h
      case 'sport':
        return _OptimalTime(8, 0); // 8h
      case 'poids':
        return _OptimalTime(7, 30); // 7h30
      case 'masse musculaire':
        return _OptimalTime(18, 0); // 18h
      default:
        return _OptimalTime(9, 0); // 9h
    }
  }

  // Calculer la prochaine occurrence d'une heure
  tz.TZDateTime _nextInstanceOfTime(_OptimalTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Calculer la prochaine occurrence d'un jour spécifique
  tz.TZDateTime _nextInstanceOfDay(int weekday, int hour, int minute) {
    var scheduledDate = tz.TZDateTime.now(tz.local);

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}

// Classe helper pour représenter une heure
class _OptimalTime {
  final int hour;
  final int minute;

  _OptimalTime(this.hour, this.minute);
}