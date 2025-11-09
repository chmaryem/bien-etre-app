class UserGoal {
  int? id;
  int userId;
  String type; // 'calories', 'sleep', 'workout', etc.
  double targetValue; // Ex: 2000 kcal
  String unit; // 'kcal', 'heures', 'km', etc.
  DateTime createdAt;
  bool isActive;

  UserGoal({
    this.id,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.unit,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convertir un UserGoal en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'targetValue': targetValue,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Créer un UserGoal depuis une Map depuis SQLite
  factory UserGoal.fromMap(Map<String, dynamic> map) {
    return UserGoal(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      targetValue: map['targetValue'],
      unit: map['unit'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }
}