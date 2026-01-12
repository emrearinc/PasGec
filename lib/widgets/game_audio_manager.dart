import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;

class GameAudioManager {
  late AudioPlayer audioPlayer;
  late AudioPlayer timerAudioPlayer;
  bool isTimerSoundPlaying = false;
  Duration? currentSoundPosition;
  bool isPlayingSound = false;

  GameAudioManager() {
    audioPlayer = AudioPlayer();
    timerAudioPlayer = AudioPlayer();
  }

  /// Genel ses dosyasını çal
  Future<void> playSound(String assetPath) async {
    try {
      developer.log('Ses dosyası çalınmaya çalışılıyor: $assetPath');
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      developer.log('Ses çalınırken hata oluştu: $e');
    }
  }

  /// Timer sesini çal (5 saniyede)
  Future<void> playTimerSound() async {
    if (!isTimerSoundPlaying) {
      isTimerSoundPlaying = true;
      try {
        await timerAudioPlayer.setSource(AssetSource('sound/timer.MP3'));
        await timerAudioPlayer.setReleaseMode(ReleaseMode.stop);
        await timerAudioPlayer.resume();
      } catch (e, stackTrace) {
        developer.log(
          'Timer sesi başlatılırken hata oluştu',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Timer sesini durdur
  void stopTimerSound() {
    if (isTimerSoundPlaying) {
      try {
        timerAudioPlayer.stop();
        isTimerSoundPlaying = false;
      } catch (e, stackTrace) {
        developer.log(
          'Timer sesi durdurulurken hata oluştu',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Doğru cevap sesi
  Future<void> playCorrectSound() async {
    await playSound('sound/dogru.MP3');
  }

  /// Tabu cezası sesi
  Future<void> playTabooSound() async {
    await playSound('sound/tabu.MP3');
  }

  /// Pas sesi
  Future<void> playPassSound() async {
    await playSound('sound/pas.MP3');
  }

  /// Sesi yeniden başlat
  Future<void> resumeTimerSound() async {
    try {
      if (currentSoundPosition != null) {
        await audioPlayer.seek(currentSoundPosition!);
        await audioPlayer.resume();
        isPlayingSound = true;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Ses yeniden başlatılırken hata oluştu',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Kaynakları temizle
  void dispose() {
    audioPlayer.dispose();
    timerAudioPlayer.dispose();
  }
}
