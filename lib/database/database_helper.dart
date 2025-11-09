import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/meal.dart';
import '../models/user_goal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wellness.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Créer les tables
  Future _createDB(Database db, int version) async {
    // Table meals
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL DEFAULT 1,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        calories INTEGER NOT NULL,
        dateTime TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Table goals
    await db.execute('''
      CREATE TABLE goals (
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

  // Migration de la base de données
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goals (
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

  // ========== MEALS CRUD ==========

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

  // ========== USER GOALS CRUD ==========

  // CREATE - Ajouter un objectif
  Future<int> createUserGoal(UserGoal userGoal) async {
    final db = await database;
    return await db.insert('goals', userGoal.toMap());
  }

  // READ - Lire tous les objectifs d'un utilisateur
  Future<List<UserGoal>> getUserGoalsByUser(int userId) async {
    final db = await database;
    final result = await db.query(
      'goals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => UserGoal.fromMap(map)).toList();
  }

  // READ - Lire l'objectif actif d'un utilisateur pour un type spécifique
  Future<UserGoal?> getActiveUserGoalByUserAndType(int userId, String type) async {
    final db = await database;
    final result = await db.query(
      'goals',
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

  // UPDATE - Modifier un objectif
  Future<int> updateUserGoal(UserGoal userGoal) async {
    final db = await database;
    return await db.update(
      'goals',
      userGoal.toMap(),
      where: 'id = ?',
      whereArgs: [userGoal.id],
    );
  }

  // DELETE - Supprimer un objectif
  Future<int> deleteUserGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Désactiver tous les objectifs d'un type pour un utilisateur
  Future<int> deactivateUserGoalsByUserAndType(int userId, String type) async {
    final db = await database;
    return await db.update(
      'goals',
      {'isActive': 0},
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, type],
    );
  }

  // Fermer la base de données
  Future close() async {
    final db = await database;
    db.close();
  }
}