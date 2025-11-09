class Meal {
  int? id;
  int userId;  // ✅ Nouveau champ
  String name;
  String type;
  int calories;
  DateTime dateTime;
  String? description;

  Meal({
    this.id,
    this.userId = 1,  // ✅ Valeur par défaut = 1
    required this.name,
    required this.type,
    required this.calories,
    required this.dateTime,
    this.description,
  });

  // Convertir un Meal en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,  // ✅ Ajouté
      'name': name,
      'type': type,
      'calories': calories,
      'dateTime': dateTime.toIso8601String(),
      'description': description,
    };
  }

  // Créer un Meal depuis une Map depuis SQLite
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      userId: map['userId'] ?? 1,  // ✅ Ajouté avec valeur par défaut
      name: map['name'],
      type: map['type'],
      calories: map['calories'],
      dateTime: DateTime.parse(map['dateTime']),
      description: map['description'],
    );
  }
}