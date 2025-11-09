class Workout {
  int? id;
  String type;
  String name;
  double duration;
  int calories;
  DateTime date;
  String? notes;
  double? distance;
  String intensity;

  Workout({
    this.id,
    required this.type,
    required this.name,
    required this.duration,
    required this.calories,
    required this.date,
    this.notes,
    this.distance,
    required this.intensity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'duration': duration,
      'calories': calories,
      'date': date.toIso8601String(),
      'notes': notes,
      'distance': distance,
      'intensity': intensity,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      type: map['type'],
      name: map['name'],
      duration: map['duration'] is int ? (map['duration'] as int).toDouble() : map['duration'],
      calories: map['calories'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      distance: map['distance']?.toDouble(),
      intensity: map['intensity'],
    );
  }

  Workout copyWith({
    int? id,
    String? type,
    String? name,
    double? duration,
    int? calories,
    DateTime? date,
    String? notes,
    double? distance,
    String? intensity,
  }) {
    return Workout(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      calories: calories ?? this.calories,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      distance: distance ?? this.distance,
      intensity: intensity ?? this.intensity,
    );
  }
}