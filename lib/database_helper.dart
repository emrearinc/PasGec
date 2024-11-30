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
    final dbName = 'words_database.db'; // Veritabanı adı
    String path = join(await getDatabasesPath(), dbName);

    // Eğer veritabanı yoksa, assets'den kopyala
    await _copyDatabaseIfNotExists(dbName);

    return await openDatabase(
      path,
      version: 1, // Version 1 olarak başlıyor
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Veritabanını assets klasöründen kopyalar
  Future<void> _copyDatabaseIfNotExists(String dbName) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, dbName);

    if (!await databaseExists(path)) {
      ByteData data = await rootBundle.load('assets/database/$dbName');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
  }

  /// Veritabanını oluşturma işlemleri
  Future<void> _onCreate(Database db, int version) async {
    // Kelimeler tablosu
    await db.execute(''' 
  CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        forbidden_words TEXT NOT NULL,
        category TEXT DEFAULT 'Genel',
        is_active INTEGER DEFAULT 1,
        created_by TEXT DEFAULT 1
      )
    ''');

    // Jokerler tablosu
    await db.execute(''' 
      CREATE TABLE IF NOT EXISTS jokers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_by TEXT DEFAULT 1
      )
    ''');

    // Oyun kayıtları tablosu
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

    // Oyuncu performansları tablosu
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
    // Yeni versiyonlara geçişte yapılacak işlemler
    if (oldVersion < 2) {
      // Gelecek versiyon güncellemeleri buraya eklenir
    }
  }

  /// Genel CRUD işlemleri (Tablo bazlı)
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// Kelimeler ile ilgili işlemler
  Future<List<Map<String, dynamic>>> getWords({String? where, List<Object?>? whereArgs}) async {
    return await query('words', where: where, whereArgs: whereArgs);
  }

  Future<void> addWord(String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.insert(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
        'created_by': 2, // Yeni eklenen kelime için created_by alanını 2 yap
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Aynı kelime eklenirse hata vermez
    );
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

  Future<void> updateWord(int id, String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.update(
      'words',
      {
        'word': word.trim(),
        'forbidden_words': forbiddenWords.join(', '),
        'created_by': 0, // created_by alanını 0 yap
      },
      where: 'id = ?', // Güncelleme koşulu
      whereArgs: [id],
    );
  }


  Future<void> updateWordStatus(int id, int status) async {
    await update('words', {'is_active': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteWord(int id) async {
    await updateWordStatus(id, 0); // Sadece is_active'i 0 yapar
  }

  /// Jokerler ile ilgili işlemler
  Future<List<Map<String, dynamic>>> getJokers() async {
    return await query('jokers');
  }

  /// Sadece aktif jokerleri döndürür
  Future<List<Map<String, dynamic>>> getActiveJokers() async {
    return await query('jokers', where: 'is_active = ?', whereArgs: [1]);
  }
  /// Yeni bir joker ekler

  Future<void> addJoker(String message) async {
    final db = await database;
    await db.insert(
      'jokers',
      {
        'message': message.trim(),
        'is_active': 1, // Yeni joker varsayılan olarak aktif
        'created_by': 2, // Yeni eklenen joker için created_by = 2
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Joker günceller
  Future<void> updateJoker(int id, String message) async {
    final db = await database;
    await db.update(
      'jokers',
      {
        'message': message.trim(),
        'created_by': 0, // Güncellenen joker için created_by = 1
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Joker siler (is_active alanını 0 yapar)
  Future<void> deleteJoker(int id) async {
    final db = await database;
    await db.update(
      'jokers',
      {'is_active': 0}, // Sadece is_active değerini 0 yap
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Oyun kayıtları ile ilgili işlemler
  Future<int> addGameRecord(String team1Name, String team2Name, int team1Score, int team2Score) async {
    return await insert('game_records', {
      'team1_name': team1Name,
      'team2_name': team2Name,
      'team1_score': team1Score,
      'team2_score': team2Score,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getGameRecords() async {
    return await query('game_records', orderBy: 'date DESC');
  }

  /// Oyuncu performansı ile ilgili işlemler
  Future<void> addPlayerPerformance(int gameId, String teamName, String playerName, int correctCount, int tabooCount, int passCount) async {
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
    return await query('player_performances', where: 'game_id = ?', whereArgs: [gameId]);
  }
}
