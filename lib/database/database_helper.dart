import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wellbeing.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        age INTEGER,
        taille REAL,
        poids REAL,
        objectif TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> createUser(User user) async {
    final db = await database;
    final hashedPassword = _hashPassword(user.password);
    
    final userMap = user.toMap();
    userMap['password'] = hashedPassword;
    userMap['created_at'] = DateTime.now().toIso8601String();

    return await db.insert('users', userMap);
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (maps.isEmpty) {
      return null;
    }

    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return User.fromMap(maps.first);
  }

  // ✅ CORRECTION : Méthode updateUser qui n'écrase PAS le password
  Future<int> updateUser(User user) async {
    final db = await database;

    // Créer une map SANS le password
    final Map<String, dynamic> updateMap = {
      'nom': user.nom,
      'email': user.email,
      'age': user.age,
      'taille': user.taille,
      'poids': user.poids,
      'objectif': user.objectif,
    };

    return await db.update(
      'users',
      updateMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<bool> emailExists(String email) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    return maps.isNotEmpty;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
  // ✅ Ajouter ces méthodes dans la classe DatabaseHelper

// Vérifier le mot de passe de l'utilisateur
Future<bool> verifyPassword(String email, String password) async {
  final db = await database;
  final hashedPassword = _hashPassword(password);

  final List<Map<String, dynamic>> maps = await db.query(
    'users',
    where: 'email = ? AND password = ?',
    whereArgs: [email, hashedPassword],
  );

  return maps.isNotEmpty;
}

// Changer le mot de passe
Future<int> changePassword(int userId, String newPassword) async {
  final db = await database;
  final hashedPassword = _hashPassword(newPassword);

  return await db.update(
    'users',
    {'password': hashedPassword},
    where: 'id = ?',
    whereArgs: [userId],
  );
}

// Supprimer un utilisateur
Future<int> deleteUser(int userId) async {
  final db = await database;

  return await db.delete(
    'users',
    where: 'id = ?',
    whereArgs: [userId],
  );
}
}