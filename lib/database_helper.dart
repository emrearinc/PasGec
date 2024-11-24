import 'dart:async';
import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart'; // Şifrelenmiş veritabanı
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
    final dbName = 'words_database_encrypted.db';
    String path = join(await getDatabasesPath(), dbName);

    // Veritabanını kopyala (eğer yoksa) ve güncelle
    await _copyDatabaseIfNotExists(dbName);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Veritabanını assets klasöründen kopyalar
  Future<void> _copyDatabaseIfNotExists(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);

    // Eğer veritabanı yoksa assets'ten kopyala
    if (!await databaseExists(path)) {
      ByteData data = await rootBundle.load('assets/database/$dbName');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
  }

  /// Veritabanını oluşturma işlemleri
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        forbidden_words TEXT NOT NULL,
        category TEXT DEFAULT 'General',
        difficulty TEXT DEFAULT 'easy'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS jokers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL
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
  }

  /// Veritabanı güncellemeleri
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS jokers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          message TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE words ADD COLUMN category TEXT DEFAULT 'General'
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE words ADD COLUMN difficulty TEXT DEFAULT 'easy'
      ''');
    }
  }

  /// Yeni jokerleri mevcut verilerle birleştirir
  Future<void> mergeJokers(List<Map<String, dynamic>> newJokers) async {
    final db = await database;

    // Mevcut jokerleri kontrol et
    final existingJokers = await db.query('jokers');
    final existingMessages = existingJokers.map((joker) => joker['message']).toSet();

    // Yeni jokerlerden sadece olmayanları ekle
    for (final joker in newJokers) {
      if (!existingMessages.contains(joker['message'])) {
        await db.insert(
          'jokers',
          {'message': joker['message']},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Kelimeleri getirir
  Future<List<Map<String, dynamic>>> getWords() async {
    final db = await database;
    return await db.query('words');
  }

  /// Belirli bir kelimeyi arar
  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    final db = await database;
    return await db.query(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  /// Yeni bir kelime ekler
  Future<void> addWord(String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.insert(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Bir kelimeyi günceller
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

  /// Bir kelimeyi siler
  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  /// Yeni bir joker ekler
  Future<void> addJoker(String message) async {
    final db = await database;
    await db.insert(
      'jokers',
      {'message': message},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Tüm jokerleri getirir
  Future<List<Map<String, dynamic>>> getJokers() async {
    final db = await database;
    return await db.query('jokers');
  }

  /// Bir jokeri günceller
  Future<void> updateJoker(int id, String message) async {
    final db = await database;
    await db.update(
      'jokers',
      {'message': message},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Bir jokeri siler
  Future<void> deleteJoker(int id) async {
    final db = await database;
    await db.delete('jokers', where: 'id = ?', whereArgs: [id]);
  }

  /// Yeni bir oyun kaydı ekler
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

  /// Oyun kayıtlarını getirir
  Future<List<Map<String, dynamic>>> getGameRecords() async {
    final db = await database;
    return await db.query('game_records', orderBy: 'date DESC');
  }

  /// Oyuncu performansı ekler
  Future<void> addPlayerPerformance(
      int gameId, String teamName, String playerName, int correctCount, int tabooCount, int passCount) async {
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

  /// Oyuncu performanslarını getirir
  Future<List<Map<String, dynamic>>> getPlayerPerformances(int gameId) async {
    final db = await database;
    return await db.query(
      'player_performances',
      where: 'game_id = ?',
      whereArgs: [gameId],
    );
  }
}
