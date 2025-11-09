class Sleep {
  final int? id;
  final int userId; // Lien avec l'utilisateur connecté
  final DateTime bedTime;
  final DateTime wakeTime;
  final String? notes;
  final DateTime date;

  Sleep({
    this.id,
    required this.userId,
    required this.bedTime,
    required this.wakeTime,
    this.notes,
    required this.date,
  });

  // Métier 1: Calculer la durée de la nuit en heures
  double calculerDureeNuit() {
    Duration diff = wakeTime.difference(bedTime);
    return diff.inMinutes / 60.0;
  }

  // Métier 2: Qualifier le sommeil par durée
  String qualifierSommeilParDuree() {
    double duree = calculerDureeNuit();
    
    if (duree < 4) {
      return 'Très insuffisant';
    } else if (duree < 6) {
      return 'Insuffisant';
    } else if (duree < 7) {
      return 'Moyen';
    } else if (duree < 9) {
      return 'Bon';
    } else if (duree < 10) {
      return 'Très bon';
    } else {
      return 'Excessif';
    }
  }

  // Obtenir la couleur selon la qualité
  String getQualityColor() {
    double duree = calculerDureeNuit();
    
    if (duree < 6) {
      return '#FF5252'; // Rouge
    } else if (duree < 7) {
      return '#FFA726'; // Orange
    } else if (duree < 9) {
      return '#66BB6A'; // Vert
    } else if (duree < 10) {
      return '#42A5F5'; // Bleu
    } else {
      return '#AB47BC'; // Violet
    }
  }

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  // Créer depuis Map
  factory Sleep.fromMap(Map<String, dynamic> map) {
    return Sleep(
      id: map['id'],
      userId: map['userId'],
      bedTime: DateTime.parse(map['bedTime']),
      wakeTime: DateTime.parse(map['wakeTime']),
      notes: map['notes'],
      date: DateTime.parse(map['date']),
    );
  }

  // Copier avec modifications
  Sleep copyWith({
    int? id,
    int? userId,
    DateTime? bedTime,
    DateTime? wakeTime,
    String? notes,
    DateTime? date,
  }) {
    return Sleep(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}