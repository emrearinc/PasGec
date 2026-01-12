// File: lib/words_pack_updater.dart
// Screen: App startup / manual sync
// Purpose: Firestore'daki meta/words_pack versiyonunu kontrol eder, .json.gz pack indirir/açar,
//          SQLite'a category + is_active dahil merge eder, local version_info günceller.

import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fb;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class WordsPackUpdater {
  final fb.FirebaseFirestore _fs = fb.FirebaseFirestore.instance;
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> forceSync() async => _syncInternal(force: true);

  Future<void> syncIfNeeded() async => _syncInternal(force: false);

  Future<void> _syncInternal({required bool force}) async {
    // 1) meta oku
    final metaSnap = await _fs.collection('meta').doc('words_pack').get();
    if (!metaSnap.exists) {
      throw Exception('meta/words_pack yok');
    }

    final meta = metaSnap.data() ?? {};
    final int remoteVersion = (meta['version'] is int)
        ? meta['version'] as int
        : int.tryParse(meta['version']?.toString() ?? '0') ?? 0;
    final String downloadUrl = (meta['downloadUrl'] ?? '').toString().trim();

    if (remoteVersion <= 0) {
      throw Exception('remote version hatalı: $remoteVersion');
    }
    if (downloadUrl.isEmpty) {
      throw Exception('downloadUrl boş');
    }

    // 2) local version check
    final int localVersion = await _db.getLocalPackVersion();
    if (!force && remoteVersion <= localVersion) return;

    // 3) indir
    final resp = await http.get(Uri.parse(downloadUrl));
    if (resp.statusCode != 200) {
      throw Exception('Pack download failed: ${resp.statusCode}');
    }

    // 4) gunzip + json parse
    final decodedBytes = GZipDecoder().decodeBytes(resp.bodyBytes);
    final Map<String, dynamic> payload =
        jsonDecode(utf8.decode(decodedBytes)) as Map<String, dynamic>;

    final int payloadVersion = (payload['version'] is int)
        ? payload['version'] as int
        : int.tryParse(payload['version']?.toString() ?? '0') ?? 0;

    if (payloadVersion != remoteVersion) {
      throw Exception(
          'Pack version mismatch meta=$remoteVersion file=$payloadVersion');
    }

    final List<dynamic> rawList = (payload['words'] as List?) ?? const [];
    final List<Map<String, dynamic>> list = rawList
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .cast<Map<String, dynamic>>()
        .toList();

    // 5) DB merge (category + is_active dahil)
    final Database db = await _db.database;

    await db.transaction((txn) async {
      // Schema/index garanti (assets DB kopyasında onCreate çalışmayabiliyor)
      await _ensureSchemaAndIndexes(txn);

      // Upsert statement: word unique => tek satır, update ile overwrite
      // Not: created_by sadece ilk insert'te 1 (pack). Sonraki güncellemeler created_by'ı bozmaz.
      const upsertSql = '''
        INSERT INTO words(word, forbidden_words, category, is_active, created_by)
        VALUES(?,?,?,?,?)
        ON CONFLICT(word) DO UPDATE SET
          forbidden_words=excluded.forbidden_words,
          category=excluded.category,
          is_active=excluded.is_active
        WHERE (words.created_by='1' OR words.created_by=1);
      ''';

      for (final w in list) {
        final String word = (w['word'] ?? '').toString().trim();
        if (word.isEmpty) continue;

        final List<String> forbidden = (w['forbidden'] as List?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];

        if (forbidden.length < 3) continue;

        final String forbiddenStr = forbidden.take(5).join(', ');

        final String category =
            (w['category'] ?? 'Genel').toString().trim().isEmpty
                ? 'Genel'
                : (w['category'] ?? 'Genel').toString().trim();

        final int isActive = _asInt(w['is_active'], fallback: 1);

        // 1) Insert yoksa ekler
        // 2) Varsa sadece pack kelimesiyse (created_by=1) günceller
        await txn.rawInsert(
          upsertSql,
          [word, forbiddenStr, category, isActive, '1'],
        );
      }

      // Local version set
      await txn.rawInsert(
        "INSERT OR REPLACE INTO version_info(id, version, description) VALUES(1, ?, ?)",
        [remoteVersion.toString(), "remote words pack"],
      );
    });
  }

  Future<void> _ensureSchemaAndIndexes(Transaction txn) async {
    // words tablosu (category alanı dahil)
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        forbidden_words TEXT NOT NULL,
        category TEXT DEFAULT 'Genel',
        is_active INTEGER DEFAULT 1,
        created_by TEXT DEFAULT '1'
      )
    ''');

    // version_info
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS version_info (
        id INTEGER PRIMARY KEY,
        version TEXT NOT NULL,
        description TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // unique + index
    await txn.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS ux_words_word ON words(word);');
    await txn.execute(
        'CREATE INDEX IF NOT EXISTS ix_words_category_active ON words(category, is_active);');
  }

  int _asInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}
