import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/goal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('goals.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
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
  }

  Future<int> insertGoal(Goal goal) async {
    final db = await instance.database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoals() async {
    final db = await instance.database;
    final result = await db.query('goals');
    return result.map((json) => Goal(
      id: json['id'] as int,
      title: json['title'] as String,
      type: json['type'] as String,
      targetValue: json['targetValue'] as double,
      currentValue: json['currentValue'] as double,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
    )).toList();
  }

  // 🔹 Mettre à jour un objectif existant
  Future<int> updateGoal(Goal goal) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // 🔹 Supprimer un objectif
  Future<int> deleteGoal(int id) async {
    final db = await instance.database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 Fermer la base
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
