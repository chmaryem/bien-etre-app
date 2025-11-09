class User {
  final int? id;
  final String nom;
  final String email;
  final String password;
  final int? age;
  final double? taille;
  final double? poids;
  final String? objectif;
  final String? createdAt;

  User({
    this.id,
    required this.nom,
    required this.email,
    required this.password,
    this.age,
    this.taille,
    this.poids,
    this.objectif,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'password': password,
      'age': age,
      'taille': taille,
      'poids': poids,
      'objectif': objectif,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      nom: map['nom'],
      email: map['email'],
      password: map['password'],
      age: map['age'],
      taille: map['taille'],
      poids: map['poids'],
      objectif: map['objectif'],
      createdAt: map['created_at'],
    );
  }

  User copyWith({
    int? id,
    String? nom,
    String? email,
    String? password,
    int? age,
    double? taille,
    double? poids,
    String? objectif,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      password: password ?? this.password,
      age: age ?? this.age,
      taille: taille ?? this.taille,
      poids: poids ?? this.poids,
      objectif: objectif ?? this.objectif,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}