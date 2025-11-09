import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/meal.dart';
import '../models/user_goal.dart';
import '../models/goal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // --- OBTENIR LA DATABASE ---
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wellbeing.db');
    return _database!;
  }

  // --- INITIALISATION ---
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // ✅ Version 4 pour toutes les tables
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // --- CRÉATION DES TABLES ---
  Future<void> _createDB(Database db, int version) async {
    // Table Users (de ton collègue)
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

    // Table Goals (de ton collègue)
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        type TEXT,
        targetValue REAL,
        currentValue REAL,
        startDate TEXT,
        endDate TEXT
      )
    ''');

    // Table Meals (TON module)
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        calories INTEGER NOT NULL,
        dateTime TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Table UserGoals (TON module - renommée pour éviter conflit)
    await db.execute('''
      CREATE TABLE user_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        type TEXT NOT NULL,
        targetValue REAL NOT NULL,
        unit TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  // --- MISE À JOUR DE LA BASE ---
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          type TEXT,
          targetValue REAL,
          currentValue REAL,
          startDate TEXT,
          endDate TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          calories INTEGER NOT NULL,
          dateTime TEXT NOT NULL,
          description TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          type TEXT NOT NULL,
          targetValue REAL NOT NULL,
          unit TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
  }

  // ============================================================
  // 🔹 PARTIE UTILISATEUR (de ton collègue - COMPLÈTE)
  // ============================================================

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

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    final updateMap = {
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
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  Future<bool> verifyPassword(String email, String password) async {
    final db = await database;
    final hashedPassword = _hashPassword(password);
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );
    return maps.isNotEmpty;
  }

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

  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ============================================================
  // 🔹 PARTIE GOALS (de ton collègue - COMPLÈTE)
  // ============================================================

  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoals() async {
    final db = await database;
    final result = await db.query('goals');
    return result.map((json) => Goal.fromMap(json)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // 🔹 PARTIE MEALS (TON module - COMPLÈTE)
  // ============================================================

  Future<int> createMeal(Meal meal) async {
    final db = await database;
    return await db.insert('meals', meal.toMap());
  }

  Future<List<Meal>> getAllMeals() async {
    final db = await database;
    final result = await db.query('meals', orderBy: 'dateTime DESC');
    return result.map((map) => Meal.fromMap(map)).toList();
  }

  Future<List<Meal>> getMealsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'meals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateTime DESC',
    );
    return result.map((map) => Meal.fromMap(map)).toList();
  }

  Future<Meal?> getMealById(int id) async {
    final db = await database;
    final result = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Meal.fromMap(result.first);
    }
    return null;
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final result = await db.query(
      'meals',
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return result.map((map) => Meal.fromMap(map)).toList();
  }

  Future<List<Meal>> getMealsByUserAndDate(int userId, DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final result = await db.query(
      'meals',
      where: 'userId = ? AND dateTime >= ? AND dateTime < ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime DESC',
    );
    return result.map((map) => Meal.fromMap(map)).toList();
  }

  Future<int> updateMeal(Meal meal) async {
    final db = await database;
    return await db.update(
      'meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  Future<int> deleteMeal(int id) async {
    final db = await database;
    return await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUserMeals(int userId) async {
    final db = await database;
    return await db.delete(
      'meals',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteAllMeals() async {
    final db = await database;
    return await db.delete('meals');
  }

  // ============================================================
  // 🔹 PARTIE USER GOALS (TON module - COMPLÈTE)
  // ============================================================

  Future<int> createUserGoal(UserGoal userGoal) async {
    final db = await database;
    return await db.insert('user_goals', userGoal.toMap());
  }

  Future<List<UserGoal>> getUserGoalsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'user_goals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => UserGoal.fromMap(map)).toList();
  }

  Future<UserGoal?> getActiveUserGoalByUserAndType(int userId, String type) async {
    final db = await database;
    final result = await db.query(
      'user_goals',
      where: 'userId = ? AND type = ? AND isActive = 1',
      whereArgs: [userId, type],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return UserGoal.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUserGoal(UserGoal userGoal) async {
    final db = await database;
    return await db.update(
      'user_goals',
      userGoal.toMap(),
      where: 'id = ?',
      whereArgs: [userGoal.id],
    );
  }

  Future<int> deleteUserGoal(int id) async {
    final db = await database;
    return await db.delete(
      'user_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateUserGoalsByUserAndType(int userId, String type) async {
    final db = await database;
    return await db.update(
      'user_goals',
      {'isActive': 0},
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, type],
    );
  }

  // ============================================================
  // 🔹 FERMETURE
  // ============================================================
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}