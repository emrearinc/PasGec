// File: lib/words_pack_updater.dart
// Screen: App startup / manual sync
// Purpose: Firestore'daki sürümü kontrol eder, downloadUrl'den .json.gz indirir, açar, SQLite'a merge eder.

import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'database_helper.dart';

class WordsPackUpdater {
  final _fs = FirebaseFirestore.instance;
  final _db = DatabaseHelper();

  Future<void> forceSync() async {
    await _syncInternal(force: true);
  }

  Future<void> syncIfNeeded() async {
    await _syncInternal(force: false);
  }

  Future<void> _syncInternal({required bool force}) async {
    final meta = await _fs.collection('meta').doc('words_pack').get();
    if (!meta.exists) {
      throw Exception('meta/words_pack yok');
    }

    final data = meta.data() ?? {};
    final remoteVersion = (data['version'] ?? 0) as int;
    final downloadUrl = (data['downloadUrl'] ?? '') as String;

    if (remoteVersion <= 0) {
      throw Exception('remote version hatalı: $remoteVersion');
    }
    if (downloadUrl.isEmpty) {
      throw Exception('downloadUrl boş');
    }

    final localVersion = await _db.getLocalPackVersion();
    if (!force && remoteVersion <= localVersion) {
      return; // güncel
    }

    final resp = await http.get(Uri.parse(downloadUrl));
    if (resp.statusCode != 200) {
      throw Exception('Pack download failed: ${resp.statusCode}');
    }

    final decoded = GZipDecoder().decodeBytes(resp.bodyBytes);
    final payload = jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;

    final payloadVersion = (payload['version'] ?? 0) as int;
    if (payloadVersion != remoteVersion) {
      throw Exception('Pack version mismatch meta=$remoteVersion file=$payloadVersion');
    }

    final list = (payload['words'] as List).cast<Map<String, dynamic>>();

    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.execute("CREATE UNIQUE INDEX IF NOT EXISTS ux_words_word ON words(word);");
      await txn.execute("""
        CREATE TABLE IF NOT EXISTS version_info (
          id INTEGER PRIMARY KEY,
          version TEXT NOT NULL,
          description TEXT,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
      """);

      for (final w in list) {
        final word = (w['word'] ?? '').toString().trim();
        final forbidden = (w['forbidden'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
            [];
        final category = (w['category'] ?? 'Genel').toString();
        final isActive = (w['is_active'] ?? 1) as int;

        if (word.isEmpty || forbidden.length < 3) continue;

        final forbiddenStr = forbidden.take(5).join(', ');

        // 1) ekle (yoksa)
        await txn.rawInsert("""
          INSERT OR IGNORE INTO words(word, forbidden_words, category, is_active, created_by)
          VALUES(?,?,?,?,?)
        """, [word, forbiddenStr, category, isActive, '1']);

        // 2) varsa ve paket kelimesiyse güncelle (created_by TEXT/INT uyumu)
        await txn.rawUpdate("""
          UPDATE words
          SET forbidden_words=?, category=?, is_active=?
          WHERE word=? AND (created_by='1' OR created_by=1)
        """, [forbiddenStr, category, isActive, word]);
      }

      await txn.rawInsert(
        "INSERT OR REPLACE INTO version_info(id, version, description) VALUES(1, ?, ?)",
        [remoteVersion.toString(), "remote words pack"],
      );
    });
  }
}
