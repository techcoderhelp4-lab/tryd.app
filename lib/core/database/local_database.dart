import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tryd.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS rewards');
      await _createRewardsTable(db);
    }
    if (oldVersion < 3) {
      // Add HIIT/Workout specific columns to activities table and fix calories naming
      // We try to add caloriesBurned if it doesn't exist (version 2 might already have a different layout)
      try {
        await db.execute('ALTER TABLE activities ADD COLUMN caloriesBurned REAL DEFAULT 0');
      } catch (e) { /* already exists */ }
      try {
        await db.execute('ALTER TABLE activities ADD COLUMN exercisesCount INTEGER');
      } catch (e) { /* already exists */ }
      try {
        await db.execute('ALTER TABLE activities ADD COLUMN roundsCount INTEGER');
      } catch (e) { /* already exists */ }
      try {
        await db.execute('ALTER TABLE activities ADD COLUMN workTime INTEGER');
      } catch (e) { /* already exists */ }
      try {
        await db.execute('ALTER TABLE activities ADD COLUMN restTime INTEGER');
      } catch (e) { /* already exists */ }
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS rewards');
      await _createRewardsTable(db);
    }
  }

  Future<void> _createRewardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE rewards (
        _id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        requiredPoints INTEGER,
        imageUrl TEXT,
        partner TEXT,
        category TEXT,
        requiresApproval INTEGER,
        maxPerUser INTEGER
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // Activities Table
    await db.execute('''
      CREATE TABLE activities (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        distance REAL NOT NULL DEFAULT 0,
        duration INTEGER NOT NULL DEFAULT 0,
        caloriesBurned REAL NOT NULL DEFAULT 0,
        averagePace REAL NOT NULL DEFAULT 0,
        averageBPM REAL NOT NULL DEFAULT 0,
        exercisesCount INTEGER,
        roundsCount INTEGER,
        workTime INTEGER,
        restTime INTEGER,
        date TEXT NOT NULL,
        syncStatus TEXT DEFAULT 'synced'
      )
    ''');

    // Challenges Table
    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startDate TEXT,
        endDate TEXT,
        targetKm REAL,
        rewardPoints INTEGER,
        imageUrl TEXT,
        isJoined INTEGER,
        userProgress REAL,
        progressPercentage REAL,
        participantCount INTEGER
      )
    ''');

    // Rewards Table
    await _createRewardsTable(db);

    // Generic Key-Value Store (For Profile, Home Stats, Search results, etc.)
    await db.execute('''
      CREATE TABLE kv_store (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  // --- Specific Helpers ---

  Future<void> insertActivity(Map<String, dynamic> activity) async {
    final db = await database;
    await db.insert('activities', activity, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getActivities() async {
    final db = await database;
    return await db.query('activities', orderBy: 'date DESC');
  }

  Future<void> updateSyncStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'activities',
      {'syncStatus': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncStatusAndId(String oldId, String newId, String status) async {
    final db = await database;
    await db.update(
      'activities',
      {
        'id': newId,
        'syncStatus': status,
      },
      where: 'id = ?',
      whereArgs: [oldId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingActivities() async {
    final db = await database;
    return await db.query('activities', where: 'syncStatus = ?', whereArgs: ['pending']);
  }

  Future<void> saveChallenges(List<Map<String, dynamic>> challenges) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var c in challenges) {
        await txn.insert('challenges', c, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getChallenges() async {
    final db = await database;
    return await db.query('challenges');
  }

  Future<void> saveRewards(List<Map<String, dynamic>> rewards) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var r in rewards) {
        await txn.insert('rewards', r, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getRewards() async {
    final db = await database;
    return await db.query('rewards');
  }

  Future<void> deleteAllRewards() async {
    final db = await database;
    await db.delete('rewards');
  }

  Future<void> deleteRewardsByCategory(String category) async {
    final db = await database;
    await db.delete('rewards', where: 'category = ?', whereArgs: [category.toLowerCase()]);
  }

  // --- Generic KV Store Helpers ---

  Future<void> setKV(String key, String jsonValue) async {
    final db = await database;
    await db.insert(
      'kv_store',
      {
        'key': key,
        'value': jsonValue,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getKV(String key) async {
    final db = await database;
    final results = await db.query('kv_store', where: 'key = ?', whereArgs: [key]);
    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  // --- Sync Queue Helpers ---

  Future<void> enqueueAction(String endpoint, String method, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'endpoint': endpoint,
      'method': method,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> removeFromQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('activities');
      await txn.delete('challenges');
      await txn.delete('rewards');
      await txn.delete('kv_store');
      await txn.delete('sync_queue');
    });
    // Also clear singleton instance to force re-init if needed
    _database = null;
  }
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});
