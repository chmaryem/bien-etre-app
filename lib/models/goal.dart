class Goal {
  final int? id;
  final String title;
  final String type;
  final double targetValue;
  final double currentValue;
  final String startDate;
  final String endDate;

  Goal({
    this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  /// ✅ Ajout de fromMap pour reconstruire un Goal depuis la base SQLite
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      title: map['title'] as String,
      type: map['type'] as String,
      targetValue: (map['targetValue'] as num).toDouble(),
      currentValue: (map['currentValue'] as num).toDouble(),
      startDate: map['startDate'] as String,
      endDate: map['endDate'] as String,
    );
  }
}
