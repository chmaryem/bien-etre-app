// lib/data/sqflite_habits_store.dart
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/habitude.dart';
import '../models/historique.dart';
import '../store/habits_store.dart';

class SqfliteHabitsStore implements HabitsStore {
  static const _dbName = 'habitudes.sqlite';
  static const _dbVersion = 2; // bump si tu modifies le schéma

  Database? _db;
  bool _inited = false;

  DateTime _norm(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<void> init() async {
    if (_inited) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, v) async {
        // Habitudes
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Habitudes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            description TEXT,
            categorieId INTEGER NOT NULL,
            couleur TEXT NOT NULL,
            icone TEXT NOT NULL,
            frequence INTEGER NOT NULL,
            frequenceNombre INTEGER NOT NULL DEFAULT 1,
            heureNotification TEXT,
            notificationActive INTEGER NOT NULL DEFAULT 1,
            dateCreation INTEGER NOT NULL,
            streakActuel INTEGER NOT NULL DEFAULT 0,
            meilleurStreak INTEGER NOT NULL DEFAULT 0
          );
        ''');

        // Historique
        await db.execute('''
          CREATE TABLE IF NOT EXISTS HistoriqueHabitudes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habitudeId INTEGER NOT NULL,
            date INTEGER NOT NULL,
            accompli INTEGER NOT NULL DEFAULT 0,
            note TEXT
          );
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_histo_hab_date ON HistoriqueHabitudes(habitudeId, date);',
        );
      },
      onUpgrade: (db, oldV, newV) async {
        // Sécurise : recrée les tables si besoin
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Habitudes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            description TEXT,
            categorieId INTEGER NOT NULL,
            couleur TEXT NOT NULL,
            icone TEXT NOT NULL,
            frequence INTEGER NOT NULL,
            frequenceNombre INTEGER NOT NULL DEFAULT 1,
            heureNotification TEXT,
            notificationActive INTEGER NOT NULL DEFAULT 1,
            dateCreation INTEGER NOT NULL,
            streakActuel INTEGER NOT NULL DEFAULT 0,
            meilleurStreak INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS HistoriqueHabitudes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habitudeId INTEGER NOT NULL,
            date INTEGER NOT NULL,
            accompli INTEGER NOT NULL DEFAULT 0,
            note TEXT
          );
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_histo_hab_date ON HistoriqueHabitudes(habitudeId, date);',
        );
      },
    );

    _inited = true;
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _inited = false;
  }

  Database get _ensureDb {
    final db = _db;
    if (db == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return db;
  }

  // ---------- HABITUDES ----------
  @override
  Future<List<Habitude>> getAllHabitudes() async {
    final db = _ensureDb;
    final rows = await db.query('Habitudes', orderBy: 'id DESC');
    return rows.map((m) => Habitude.fromMap(m)).toList();
  }

  @override
  Future<Habitude?> getHabitudeById(int id) async {
    final db = _ensureDb;
    final rows = await db.query('Habitudes', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Habitude.fromMap(rows.first);
  }

  @override
  Future<List<Habitude>> getHabitudesByCategorie(int categorieId) async {
    final db = _ensureDb;
    final rows = await db.query('Habitudes', where: 'categorieId=?', whereArgs: [categorieId]);
    return rows.map((m) => Habitude.fromMap(m)).toList();
  }

  @override
  Future<int> createHabitude(Habitude habitude) async {
    final db = _ensureDb;
    // dateCreation/streaks doivent être présents dans l’objet
    final id = await db.insert('Habitudes', habitude.toMap(withId: false));
    return id;
  }

  @override
  Future<bool> updateHabitude(Habitude habitude) async {
    final db = _ensureDb;
    final count = await db.update(
      'Habitudes',
      habitude.toMap(withId: false),
      where: 'id=?',
      whereArgs: [habitude.id],
    );
    return count > 0;
  }

  @override
  Future<int> deleteHabitude(int id) async {
    final db = _ensureDb;
    // Supprime l’historique lié
    await db.delete('HistoriqueHabitudes', where: 'habitudeId=?', whereArgs: [id]);
    return db.delete('Habitudes', where: 'id=?', whereArgs: [id]);
  }

  // ---------- HISTORIQUE ----------
  @override
  Future<int> marquerHabitudeAccomplie(int habitudeId, DateTime date) async {
    final db = _ensureDb;
    final d = _norm(date).millisecondsSinceEpoch;

    final existing = await db.query(
      'HistoriqueHabitudes',
      where: 'habitudeId=? AND date=?',
      whereArgs: [habitudeId, d],
      limit: 1,
    );

    int res;
    if (existing.isEmpty) {
      res = await db.insert('HistoriqueHabitudes', {
        'habitudeId': habitudeId,
        'date': d,
        'accompli': 1,
        'note': null,
      });
    } else {
      res = await db.update(
        'HistoriqueHabitudes',
        {'accompli': 1},
        where: 'id=?',
        whereArgs: [existing.first['id']],
      );
    }

    await _recalcStreaks(habitudeId);
    return res;
  }

  @override
  Future<bool> toggleAccompliAujourdHui(int habitudeId) async {
    final db = _ensureDb;
    final d = _norm(DateTime.now()).millisecondsSinceEpoch;

    final existing = await db.query(
      'HistoriqueHabitudes',
      where: 'habitudeId=? AND date=?',
      whereArgs: [habitudeId, d],
      limit: 1,
    );

    final newVal = existing.isEmpty
        ? 1
        : ((existing.first['accompli'] as int? ?? 0) == 1 ? 0 : 1);

    if (existing.isEmpty) {
      await db.insert('HistoriqueHabitudes', {
        'habitudeId': habitudeId,
        'date': d,
        'accompli': newVal,
        'note': null,
      });
    } else {
      await db.update(
        'HistoriqueHabitudes',
        {'accompli': newVal},
        where: 'id=?',
        whereArgs: [existing.first['id']],
      );
    }

    await _recalcStreaks(habitudeId);
    return newVal == 1;
  }

  @override
  Future<List<HistoriqueHabitude>> getHistoriqueByHabitude(int habitudeId) async {
    final db = _ensureDb;
    final rows = await db.query(
      'HistoriqueHabitudes',
      where: 'habitudeId=?',
      whereArgs: [habitudeId],
      orderBy: 'date DESC',
    );
    return rows.map((m) => HistoriqueHabitude.fromMap(m)).toList();
  }

  @override
  Future<bool> isHabitudeAccomplie(int habitudeId, DateTime date) async {
    final db = _ensureDb;
    final d = _norm(date).millisecondsSinceEpoch;
    final rows = await db.query(
      'HistoriqueHabitudes',
      where: 'habitudeId=? AND date=? AND accompli=1',
      whereArgs: [habitudeId, d],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<int> calculerStreak(int habitudeId) async {
    final histo = await getHistoriqueByHabitude(habitudeId);
    if (histo.isEmpty) return 0;

    int streak = 0;
    DateTime check = _norm(DateTime.now());

    for (final e in histo) {
      final entryDate = _norm(e.date);
      if (entryDate == check && e.accompli) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ---------- internes ----------
  Future<void> _recalcStreaks(int habitudeId) async {
    final db = _ensureDb;
    final rows = await db.query(
      'HistoriqueHabitudes',
      where: 'habitudeId=? AND accompli=1',
      whereArgs: [habitudeId],
      orderBy: 'date ASC',
    );

    if (rows.isEmpty) {
      await db.update(
        'Habitudes',
        {'streakActuel': 0, 'meilleurStreak': 0},
        where: 'id=?',
        whereArgs: [habitudeId],
      );
      return;
    }

    final completed = rows
        .map((m) => DateTime.fromMillisecondsSinceEpoch((m['date'] as int)))
        .map(_norm)
        .toSet();

    // streak actuel
    int current = 0;
    var cursor = _norm(DateTime.now());
    while (completed.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // meilleur streak
    int best = 0, run = 0;
    DateTime? prev;
    for (final d in completed.toList()..sort()) {
      if (prev == null || d.difference(prev!).inDays == 1) {
        run += 1;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = d;
    }

    await db.update(
      'Habitudes',
      {'streakActuel': current, 'meilleurStreak': best},
      where: 'id=?',
      whereArgs: [habitudeId],
    );
  }
}
