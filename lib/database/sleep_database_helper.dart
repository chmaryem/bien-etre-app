import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sleep_model.dart';

class SleepDatabaseHelper {
  static final SleepDatabaseHelper instance = SleepDatabaseHelper._init();
  static Database? _database;

  SleepDatabaseHelper._init();

  // Singleton DB
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sleep.db');
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

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textNotNull = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intNotNull = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE sleep (
        id $idType,
        userId $intNotNull,
        bedTime $textNotNull,
        wakeTime $textNotNull,
        notes $textNullable,
        date $textNotNull
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_user ON sleep(userId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sleep_date ON sleep(date);');
  }

  // -------------------- CRUD harmonisés avec l'UI --------------------

  // CREATE
  Future<Sleep> createSleep(Sleep sleep) async {
    final db = await instance.database;
    final id = await db.insert('sleep', sleep.toMap());
    return sleep.copyWith(id: id);
  }

  // READ - Tous les enregistrements d'un user
  Future<List<Sleep>> readAllSleeps(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'sleep',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => Sleep.fromMap(json)).toList();
  }

  // READ - Un enregistrement par id (optionnellement vérifier l'user)
  Future<Sleep?> readSleep(int id, {int? userId}) async {
    final db = await instance.database;
    final maps = await db.query(
      'sleep',
      where: userId == null ? 'id = ?' : 'id = ? AND userId = ?',
      whereArgs: userId == null ? [id] : [id, userId],
      limit: 1,
    );
    if (maps.isNotEmpty) return Sleep.fromMap(maps.first);
    return null;
  }

  // READ - 7 derniers jours pour un user
  Future<List<Sleep>> readLastWeek(int userId) async {
    final db = await instance.database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final result = await db.query(
      'sleep',
      where: 'userId = ? AND date >= ?',
      whereArgs: [userId, weekAgo],
      orderBy: 'date DESC',
    );

    return result.map((json) => Sleep.fromMap(json)).toList();
  }

  // UPDATE
  Future<int> updateSleep(Sleep sleep) async {
    final db = await instance.database;
    return db.update(
      'sleep',
      sleep.toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [sleep.id, sleep.userId],
    );
  }

  // DELETE
  Future<int> deleteSleep(int id, {required int userId}) async {
    final db = await instance.database;
    return await db.delete(
      'sleep',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}

// -------------------- Extension copyWith (corrigée) --------------------
extension SleepCopy on Sleep {
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
