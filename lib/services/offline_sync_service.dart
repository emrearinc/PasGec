import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../database_helper.dart';
import 'dart:developer';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  static const String _pendingUpdatesKey = 'pending_game_updates';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _offlineModeKey = 'offline_mode';

  Future<void> savePendingUpdate(Map<String, dynamic> gameData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingUpdates =
          prefs.getStringList(_pendingUpdatesKey) ?? [];

      // Timestamp ile güncelleme ekle
      gameData['timestamp'] = DateTime.now().toIso8601String();
      pendingUpdates.add(jsonEncode(gameData));

      await prefs.setStringList(_pendingUpdatesKey, pendingUpdates);
      log("Offline güncelleme kaydedildi: ${gameData['id']}");
    } catch (e) {
      log("Pending update kaydedilirken hata: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> pendingUpdates =
          prefs.getStringList(_pendingUpdatesKey) ?? [];

      return pendingUpdates
          .map((update) => jsonDecode(update) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      log("Pending updates alınırken hata: $e");
      return [];
    }
  }

  /// Çakışma çözümü: Last-Write-Wins stratejisi
  Future<void> syncWithConflictResolution() async {
    try {
      final pendingUpdates = await getPendingUpdates();
      if (pendingUpdates.isEmpty) return;

      for (var update in pendingUpdates) {
        try {
          // Çakışma kontrolü: remote'ta daha yeni veri varsa, onu koru
          final remoteTimestamp = update['remote_timestamp'];
          final localTimestamp = update['timestamp'];

          if (remoteTimestamp != null && localTimestamp != null) {
            final remote = DateTime.parse(remoteTimestamp);
            final local = DateTime.parse(localTimestamp);

            // Remote daha yeni ise, local güncellemeyi atla
            if (remote.isAfter(local)) {
              log("Çakışma: Remote daha yeni, local atlanıyor: ${update['id']}");
              continue;
            }
          }

          // Local güncellemeyi uygula
          await _applyUpdate(update);
          log("Offline güncelleme senkronize edildi: ${update['id']}");
        } catch (e) {
          log("Güncelleme uygulanırken hata: $e");
        }
      }

      // Başarılı güncellemeleri temizle
      await clearPendingUpdates();
      await setLastSyncTime();
    } catch (e) {
      log("Sync hatası: $e");
    }
  }

  Future<void> _applyUpdate(Map<String, dynamic> update) async {
    // Firebase'e yükle veya local DB'ye yazma işlemini gerçekleştir
    // Bu örnek GameScreen'den gelen oyun verilerini işler
    if (update['type'] == 'game_result') {
      // Oyun sonuçlarını kaydet
      await DatabaseHelper().insertGameResult(update);
    } else if (update['type'] == 'word_update') {
      // Kelime güncellemelerini kaydet
      // await DatabaseHelper().updateWord(...);
    }
  }

  Future<void> clearPendingUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingUpdatesKey);
      log("Pending updates temizlendi");
    } catch (e) {
      log("Pending updates temizlenirken hata: $e");
    }
  }

  Future<void> setLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastSyncKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      log("Sync zamanı kaydedilirken hata: $e");
    }
  }

  Future<String?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastSyncKey);
    } catch (e) {
      log("Sync zamanı alınırken hata: $e");
      return null;
    }
  }

  Future<void> setOfflineMode(bool isOffline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineModeKey, isOffline);
    } catch (e) {
      log("Offline modu ayarlanırken hata: $e");
    }
  }

  Future<bool> isOfflineMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_offlineModeKey) ?? false;
    } catch (e) {
      log("Offline modu kontrolü hatası: $e");
      return false;
    }
  }

  /// Senkronizasyon durumunu kontrol et
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final pendingUpdates = await getPendingUpdates();
      final lastSync = await getLastSyncTime();
      final isOffline = await isOfflineMode();

      return {
        'pending_updates': pendingUpdates.length,
        'last_sync': lastSync,
        'is_offline': isOffline,
        'status': isOffline ? 'Offline Mod' : 'Online',
      };
    } catch (e) {
      log("Sync durumu alınırken hata: $e");
      return {'status': 'Hata', 'error': e.toString()};
    }
  }
}
