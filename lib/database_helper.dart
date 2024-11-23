import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  /// Veritabanı nesnesini döndürür
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Veritabanını başlatır
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'words_database.db');

    // Eğer veritabanı dosyası yoksa assets'ten kopyala
    if (!(await databaseExists(path))) {
      ByteData data = await rootBundle.load('assets/database/words_database.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Veritabanı oluşturma işlemleri
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        forbidden_words TEXT NOT NULL,
        category TEXT DEFAULT "General"
      )
    ''');

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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS jokers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL
      )
    ''');
  }

  /// Veritabanı güncelleme işlemleri
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS jokers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message TEXT NOT NULL
        )
      ''');
    }
  }

  // ---------- Joker İşlemleri ----------

  /// Joker ekler
  Future<void> addJoker(String message) async {
    final db = await database;
    await db.insert(
      'jokers',
      {'message': message},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Jokerleri getirir
  Future<List<Map<String, dynamic>>> getJokers() async {
    final db = await database;
    return await db.query('jokers');
  }

  /// Joker günceller
  Future<void> updateJoker(int id, String message) async {
    final db = await database;
    await db.update(
      'jokers',
      {'message': message},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Joker siler
  Future<void> deleteJoker(int id) async {
    final db = await database;
    await db.delete('jokers', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Kelime İşlemleri ----------

  Future<List<Map<String, dynamic>>> getWords() async {
    final db = await database;
    return await db.query('words');
  }

  Future<void> addWord(String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.insert(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Kelimeler arasında arama yapar
  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    final db = await database;
    return await db.query(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  Future<void> updateWord(int id, String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.update(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Oyun Kayıt İşlemleri ----------

  Future<int> addGameRecord(String team1Name, String team2Name, int team1Score, int team2Score) async {
    final db = await database;
    return await db.insert(
      'game_records',
      {
        'team1_name': team1Name,
        'team2_name': team2Name,
        'team1_score': team1Score,
        'team2_score': team2Score,
        'date': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getGameRecords() async {
    final db = await database;
    return await db.query('game_records', orderBy: 'date DESC');
  }

  // ---------- Oyuncu Performansı İşlemleri ----------

  Future<void> addPlayerPerformance(
      int gameId,
      String teamName,
      String playerName,
      int correctCount,
      int tabooCount,
      int passCount,
      ) async {
    final db = await database;
    await db.insert(
      'player_performances',
      {
        'game_id': gameId,
        'team_name': teamName,
        'player_name': playerName,
        'correct_count': correctCount,
        'taboo_count': tabooCount,
        'pass_count': passCount,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPlayerPerformances(int gameId) async {
    final db = await database;
    return await db.query(
      'player_performances',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }
}
