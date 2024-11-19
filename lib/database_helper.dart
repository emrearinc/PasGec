// database_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart'; // rootBundle icin

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
    String path = join(await getDatabasesPath(), 'words_database.db');

    // Eğer dosya yoksa asset'ten kopyala
    if (!(await databaseExists(path))) {
      ByteData data = await rootBundle.load('assets/database/words_database.db');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS words (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      word TEXT NOT NULL,
      forbidden_words TEXT NOT NULL,
      category TEXT DEFAULT "General"
    )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE words ADD COLUMN category TEXT DEFAULT "General"');
    }
  }

  Future<List<Map<String, dynamic>>> getWords() async {
    final db = await database;
    return await db.query('words');
  }

  Future<List<Map<String, dynamic>>> searchWords(String query) async {
    final db = await database;
    return await db.query(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  Future<void> addWord(String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.insert(
      'words',
      {'word': word.trim(), 'forbidden_words': forbiddenWords.join(', ')},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateWord(int id, String word, List<String> forbiddenWords) async {
    final db = await database;
    await db.update(
      'words',
      {'word': word.trim(), 'forbidden_words': forbiddenWords.join(', ')},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWord(int id) async {
    final db = await database;
    await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }
}