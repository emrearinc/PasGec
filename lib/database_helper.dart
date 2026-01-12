// File: lib/database_helper.dart
// Screen: Database layer
// Purpose: Assets DB'yi kopyalar, tabloları garanti eder,
// index/versiyon tablosunu yönetir, kategori listesi/sayıları sağlar
// ve CRUD + game records işlemlerini yapar.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    const dbName = 'words_database.db';
    final path = join(await getDatabasesPath(), dbName);

    await _copyDatabaseIfNotExists(dbName);

    // Not: Assets DB kopyalandığında onCreate tetiklenmez.
    // Bu yüzden openDatabase sonrası tabloları garanti edeceğiz.
    final db = await openDatabase(
      path,
      version: 1,
      onUpgrade: _onUpgrade,
    );

    await _ensureSchema(db);
    return db;
  }

  Future<void> _copyDatabaseIfNotExists(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);

    if (!await databaseExists(path)) {
      final data = await rootBundle.load('assets/database/$dbName');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
  }

  Future<void> _ensureSchema(Database db) async {
    // words
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        forbidden_words TEXT NOT NULL,
        category TEXT DEFAULT 'Genel',
        is_active INTEGER DEFAULT 1,
        created_by TEXT DEFAULT '1'
      )
    ''');

    // jokers
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jokers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_by TEXT DEFAULT '1'
      )
    ''');

    // game_records
    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team1_name TEXT NOT NULL,
        team2_name TEXT NOT NULL,
        team1_score INTEGER NOT NULL,
        team2_score INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // player_performances
    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_performances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        team_name TEXT NOT NULL,
        player_name TEXT NOT NULL,
        correct_count INTEGER DEFAULT 0,
        taboo_count INTEGER DEFAULT 0,
        pass_count INTEGER DEFAULT 0,
        FOREIGN KEY (game_id) REFERENCES game_records (id) ON DELETE CASCADE
      )
    ''');

    // version_info (remote pack versiyonunu tutar)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS version_info (
        id INTEGER PRIMARY KEY,
        version TEXT NOT NULL,
        description TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Unique index: aynı kelimeyi tekrar ekleme
    await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_words_word ON words(word);');

    // Kategori filtresi hızlansın (opsiyonel ama iyi)
    await db.execute(
        'CREATE INDEX IF NOT EXISTS ix_words_category_active ON words(category, is_active);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Şu an versiyon 1; ileride burayı kullanacağız.
    await _ensureSchema(db);
  }

  // ---------- Genel CRUD ----------
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  // ---------- Words ----------
  Future<List<Map<String, dynamic>>> getWords(
      {String? where, List<Object?>? whereArgs}) async {
    return query('words', where: where, whereArgs: whereArgs);
  }

  /// Seçili kategorilere göre aktif kelimeleri getirir.
  /// - categories null/empty => karışık (tüm aktif)
  /// - dolu => sadece o kategoriler
  Future<List<Map<String, dynamic>>> getActiveWordsByCategories(
      List<String>? categories) async {
    final db = await database;

    if (categories == null || categories.isEmpty) {
      return db.query('words', where: 'is_active = ?', whereArgs: [1]);
    }

    final placeholders = List.filled(categories.length, '?').join(',');
    return db.query(
      'words',
      where: 'is_active = ? AND category IN ($placeholders)',
      whereArgs: [1, ...categories],
    );
  }

  /// Kategori listesi (aktif kelimelerden)
  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT TRIM(category) AS category
      FROM words
      WHERE is_active = 1 AND category IS NOT NULL AND TRIM(category) <> ''
      ORDER BY category COLLATE NOCASE ASC
    ''');
    return rows.map((e) => e['category'].toString()).toList();
  }

  /// Kategori başına aktif kelime sayısı
  Future<Map<String, int>> getCategoryCounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT TRIM(category) AS category, COUNT(*) AS cnt
      FROM words
      WHERE is_active = 1 AND category IS NOT NULL AND TRIM(category) <> ''
      GROUP BY TRIM(category)
      ORDER BY category COLLATE NOCASE ASC
    ''');
    return {
      for (final r in rows) r['category'].toString(): (r['cnt'] as int),
    };
  }

  Future<void> addWord(
    String word,
    List<String> forbiddenWords, {
    String category = 'Genel',
  }) async {
    final db = await database;

    final normalizedCategory =
        category.trim().isEmpty ? 'Genel' : category.trim();

    await db.insert(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
        'category': normalizedCategory,
        'created_by': '2', // kullanıcı ekledi
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> updateWord(
    int id,
    String word,
    List<String> forbiddenWords, {
    String category = 'Genel',
  }) async {
    final db = await database;

    final normalizedCategory =
        category.trim().isEmpty ? 'Genel' : category.trim();

    await db.update(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
        'category': normalizedCategory,
        'created_by': '0',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateWordIsActive(int id, int isActive) async {
    final db = await database;
    await db.update('words', {'is_active': isActive},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchWords(String queryText) async {
    final db = await database;
    return db.query(
      'words',
      where: 'word LIKE ? AND is_active = ?',
      whereArgs: ['%$queryText%', 1],
    );
  }

  Future<void> updateWordStatus(int id, int status) async {
    await update('words', {'is_active': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteWord(int id) async {
    await updateWordStatus(id, 0);
  }

  // ---------- Jokers ----------
  Future<List<Map<String, dynamic>>> getJokers() async => query('jokers');

  Future<List<Map<String, dynamic>>> getActiveJokers() async {
    return query('jokers', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<void> addJoker(String message) async {
    final db = await database;
    await db.insert(
      'jokers',
      {'message': message.trim(), 'is_active': 1, 'created_by': '2'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> updateJokerStatus(int id, int status) async {
    final db = await database;
    await db.update('jokers', {'is_active': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateJoker(int id, String message) async {
    final db = await database;
    await db.update(
      'jokers',
      {'message': message.trim(), 'created_by': '0'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteJoker(int id) async {
    final db = await database;
    await db.update('jokers', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Records ----------
  Future<int> addGameRecord(String team1Name, String team2Name, int team1Score,
      int team2Score) async {
    return insert('game_records', {
      'team1_name': team1Name,
      'team2_name': team2Name,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getGameRecords() async {
    return query('game_records', orderBy: 'date DESC');
  }

  Future<void> addPlayerPerformance(
    int gameId,
    String teamName,
    String playerName,
    int correctCount,
    int tabooCount,
    int passCount,
  ) async {
    await insert('player_performances', {
      'game_id': gameId,
      'team_name': teamName,
      'player_name': playerName,
      'correct_count': correctCount,
      'taboo_count': tabooCount,
      'pass_count': passCount,
    });
  }

  Future<List<Map<String, dynamic>>> getPlayerPerformances(int gameId) async {
    return query('player_performances',
        where: 'game_id = ?', whereArgs: [gameId]);
  }

  // ---------- Debug / Info ----------
  Future<int> getWordCount() async {
    final db = await database;
    final res = await db.rawQuery("SELECT COUNT(*) as cnt FROM words");
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ---------- Category Management ----------
  /// Belirtilen kategori içindeki tüm kelimeleri getirir
  Future<List<Map<String, dynamic>>> getWordsInCategory(
      String categoryName) async {
    final db = await database;
    return db.query(
      'words',
      where: 'is_active = ? AND TRIM(category) = ?',
      whereArgs: [1, categoryName.trim()],
      orderBy: 'word ASC',
    );
  }

  /// Kategori ismi değiştirir
  Future<void> updateCategoryName(String oldName, String newName) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE words SET category = ? WHERE TRIM(category) = ? AND is_active = ?',
      [newName.trim(), oldName.trim(), 1],
    );
  }

  // ---------- Version ----------
  Future<int> getLocalPackVersion() async {
    final db = await database;
    final rows = await db
        .rawQuery("SELECT version FROM version_info WHERE id=1 LIMIT 1");
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['version']?.toString() ?? '0') ?? 0;
  }

  Future<void> setLocalPackVersion(int version) async {
    final db = await database;
    await db.rawInsert(
      "INSERT OR REPLACE INTO version_info(id, version, description) VALUES(1, ?, ?)",
      [version.toString(), "remote words pack"],
    );
  }
}
