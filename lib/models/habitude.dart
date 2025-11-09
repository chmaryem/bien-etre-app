import 'package:flutter/foundation.dart';

/// Si tu as déjà ces enums ailleurs, garde-les.
/// Ici je les laisse en int (index) dans la base.
enum FrequenceType { quotidien, hebdomadaire, mensuel }

@immutable
class Habitude {
  final int? id;
  final String nom;
  final String? description;
  final int categorieId;
  final String couleur; // hex "#RRGGBB"
  final String icone;   // emoji
  final FrequenceType frequence;
  final int frequenceNombre; // par défaut 1
  final String? heureNotification; // "HH:mm"
  final bool notificationActive;
  final DateTime dateCreation;
  final int streakActuel;
  final int meilleurStreak;

  const Habitude({
    this.id,
    required this.nom,
    this.description,
    required this.categorieId,
    required this.couleur,
    required this.icone,
    required this.frequence,
    this.frequenceNombre = 1,
    this.heureNotification,
    this.notificationActive = true,
    required this.dateCreation,
    this.streakActuel = 0,
    this.meilleurStreak = 0,
  });

  Habitude copyWith({
    int? id,
    String? nom,
    String? description,
    int? categorieId,
    String? couleur,
    String? icone,
    FrequenceType? frequence,
    int? frequenceNombre,
    String? heureNotification,
    bool? notificationActive,
    DateTime? dateCreation,
    int? streakActuel,
    int? meilleurStreak,
  }) {
    return Habitude(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      categorieId: categorieId ?? this.categorieId,
      couleur: couleur ?? this.couleur,
      icone: icone ?? this.icone,
      frequence: frequence ?? this.frequence,
      frequenceNombre: frequenceNombre ?? this.frequenceNombre,
      heureNotification: heureNotification ?? this.heureNotification,
      notificationActive: notificationActive ?? this.notificationActive,
      dateCreation: dateCreation ?? this.dateCreation,
      streakActuel: streakActuel ?? this.streakActuel,
      meilleurStreak: meilleurStreak ?? this.meilleurStreak,
    );
  }

  /// Map pour SQLite. `withId:false` quand on fait un INSERT auto-incrémenté.
  Map<String, Object?> toMap({bool withId = true}) {
    final map = <String, Object?>{
      'nom': nom,
      'description': description,
      'categorieId': categorieId,
      'couleur': couleur,
      'icone': icone,
      'frequence': frequence.index,
      'frequenceNombre': frequenceNombre,
      'heureNotification': heureNotification,
      'notificationActive': notificationActive ? 1 : 0,
      'dateCreation': dateCreation.millisecondsSinceEpoch,
      'streakActuel': streakActuel,
      'meilleurStreak': meilleurStreak,
    };
    if (withId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Construction robuste depuis SQLite.
  factory Habitude.fromMap(Map<String, Object?> m) {
    int _asInt(Object? v, [int def = 0]) =>
        v is int ? v : (v is num ? v.toInt() : def);

    final int? id = (m['id'] == null) ? null : _asInt(m['id']);
    final String nom = (m['nom'] as String?) ?? '';
    final String? description = m['description'] as String?;
    final int categorieId = _asInt(m['categorieId']);
    final String couleur = (m['couleur'] as String?) ?? '#2563EB';
    final String icone = (m['icone'] as String?) ?? '✅';

    final int freqIdx = _asInt(m['frequence'], 0);
    final frequence = FrequenceType.values[
    (freqIdx >= 0 && freqIdx < FrequenceType.values.length) ? freqIdx : 0];

    final int frequenceNombre = _asInt(m['frequenceNombre'], 1);
    final String? heureNotif = m['heureNotification'] as String?;
    final bool notifActive = _asInt(m['notificationActive'], 1) == 1;

    final int createdMs = _asInt(m['dateCreation'],
        DateTime.now().millisecondsSinceEpoch);
    final dateCreation = DateTime.fromMillisecondsSinceEpoch(createdMs);

    final int streakActuel = _asInt(m['streakActuel'], 0);
    final int meilleurStreak = _asInt(m['meilleurStreak'], 0);

    return Habitude(
      id: id,
      nom: nom,
      description: description,
      categorieId: categorieId,
      couleur: couleur,
      icone: icone,
      frequence: frequence,
      frequenceNombre: frequenceNombre,
      heureNotification: heureNotif,
      notificationActive: notifActive,
      dateCreation: dateCreation,
      streakActuel: streakActuel,
      meilleurStreak: meilleurStreak,
    );
  }
}
