import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'habitudes_sqflite.db'; // ✅ NOUVEAU NOM
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // Table des habitudes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        description TEXT,
        categorieId INTEGER NOT NULL DEFAULT 0,
        couleur TEXT NOT NULL DEFAULT '#2563EB',
        icone TEXT NOT NULL DEFAULT '🏷️',
        frequence INTEGER NOT NULL DEFAULT 0,         -- 0=quotidien, 1=hebdo
        frequenceNombre INTEGER NOT NULL DEFAULT 1,
        heureNotification TEXT,
        notificationActive INTEGER NOT NULL DEFAULT 1, -- 0/1
        dateCreation TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        streakActuel INTEGER NOT NULL DEFAULT 0,
        meilleurStreak INTEGER NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_cat ON habits(categorieId);');

    // Table historique
    await db.execute('''
      CREATE TABLE IF NOT EXISTS habits_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitudeId INTEGER NOT NULL,
        date TEXT NOT NULL,      -- stockée normalisée "YYYY-MM-DD"
        accompli INTEGER NOT NULL DEFAULT 0, -- 0/1
        note TEXT,
        FOREIGN KEY(habitudeId) REFERENCES habits(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_hist_habit ON habits_history(habitudeId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_hist_date  ON habits_history(date);');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // migrations futures si besoin
  }

  Future<void> close() async {
    final d = _db;
    if (d != null && d.isOpen) {
      await d.close();
    }
    _db = null;
  }
}
