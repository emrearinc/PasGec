# 🎮 Game Screen Modüler Yapı - Hızlı Referans

## 📂 Dosya Yapısı

```
lib/
├── game_screen.dart (399 satır) ⭐ ANA EKRAN
│   ├─ GameScreen (StatefulWidget)
│   └─ GameScreenState (State)
│
├── widgets/
│   ├── game_state_manager.dart (257 satır) 🎯 DURUM
│   │   ├─ Word (Model)
│   │   └─ GameStateManager (Oyun Mantığı)
│   │
│   ├── game_audio_manager.dart (88 satır) 🔊 SES
│   │   └─ GameAudioManager (Ses Kontrol)
│   │
│   ├── game_dialogs.dart (425 satır) 💬 DİYALOGLAR
│   │   └─ GameDialogs (Statik Metodlar)
│   │
│   ├── game_word_card.dart (76 satır) 📝 WIDGET
│   │   └─ GameWordCard (Kelime Gösterim)
│   │
│   ├── game_button_widget.dart ✅ Var olan
│   ├── score_card_widget.dart ✅ Var olan
│   ├── timer_widget.dart ✅ Var olan
│   └── turn_indicator_widget.dart ✅ Var olan
│
└── DOKÜMANTASYON/
    ├── GAME_SCREEN_MODULAR_GUIDE.md 📖 Kullanıcı Kılavuzu
    ├── GAME_SCREEN_ARCHITECTURE.md 🏗️ Teknik Mimari
    ├── MODULAR_REFACTORING_SUMMARY.md 📊 Özet
    └── TESLIM_OZETI.md ✨ Teslim Belgesi
```

---

## 🎯 Her Modülün Sorumluluğu

### 1️⃣ game_state_manager.dart

**Ne yapıyor?**
- Oyun durumunu yönetir (skorlar, sıra vb.)
- Oyuncu performansını takip eder
- Kelimeleri yönetir
- Tur değişimini kontrol eder

**Temel Sınıflar:**
```dart
class Word {
  final int id;
  final String word;
  final List<String> forbiddenWords;
}

class GameStateManager {
  int team1Score, team2Score;
  int currentTeam;
  List<Word> words;
  Timer? timer;
  // ... 20+ metod
}
```

---

### 2️⃣ game_audio_manager.dart

**Ne yapıyor?**
- Doğru/tabu/pas seslerini çalar
- Timer sesini kontrol eder
- Ses kaynaklarını yönetir

**Örnek Kullanım:**
```dart
audioManager.playCorrectSound();    // 🎵 Doğru sesi
audioManager.playTabooSound();      // 🔴 Tabu sesi
audioManager.playPassSound();       // ⏭️ Pas sesi
audioManager.stopTimerSound();      // ⏹️ Timer sesini durdur
```

---

### 3️⃣ game_dialogs.dart

**Ne yapıyor?**
- Oyun duraklama diyaloğunu gösterir
- Çıkış onayı diyaloglarını yönetir
- Joker mesajlarını gösterir
- Hata uyarılarını gösterir

**Örnek Kullanım:**
```dart
GameDialogs.showPauseDialog(context, onResume, onExit);
GameDialogs.showJokerDialog(context, onClose);
GameDialogs.showPassLimitDialog(context, onClose);
```

---

### 4️⃣ game_word_card.dart

**Ne yapıyor?**
- Kelimeyi büyük yazı ile gösterir
- Yasak kelimeleri listeleyerek gösterir
- Güzel tasarımlı kart gösterir

**Örnek:**
```
┌─────────────────────────┐
│    SELAMLA... (kelime)  │
├─────────────────────────┤
│  ❌ İçeri Girme         │
│  ❌ Dış Mekan           │
│  ❌ Kapı                │
└─────────────────────────┘
```

---

### 5️⃣ game_screen.dart

**Ne yapıyor?**
- UI düzenini oluşturur
- Modüller arasında koordinasyon sağlar
- Kullanıcı etkileşimlerini işler
- Veritabanından veri yükler

**Butonlar:**
- ⏭️ **Pas** - Kelimeyi pas et
- 🔴 **Tabu** - Tabu kelimesi söylendi
- ✅ **Doğru** - Doğru cevap

---

## 🔄 Veri Akışı

```
Kullanıcı ------→ GameScreen
                     ↓
              (Hangi butona tıklandı?)
              ↙        ↓        ↘
         Doğru      Tabu        Pas
           ↓         ↓          ↓
    GameStateManager (Durum güncelle)
           ↓
    GameAudioManager (Ses çal)
           ↓
       setState() (UI güncelle)
```

---

## 💡 Hızlı Kullanım Örnekleri

### Doğru Cevap Yakıtkenla
```dart
// Ana ekrada çalışır
void _handleCorrect() async {
  gameState.incrementCorrect();           // Puan +1
  setState(() {});
  await audioManager.playCorrectSound();  // Ses çal
  _checkWinCondition();                   // Kontrol et
  await gameState.nextWord();             // Sonraki kelime
  setState(() {});
}
```

### Yeni Diyalog Eklemek
```dart
// game_dialogs.dart'a ekle
static Future<void> showMyDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Başlık'),
        // ... içerik
      );
    },
  );
}

// game_screen.dart'da kullan
GameDialogs.showMyDialog(context);
```

### Yeni Ses Eklemek
```dart
// game_audio_manager.dart'a ekle
Future<void> playNewSound() async {
  await playSound('sound/newsound.MP3');
}

// game_screen.dart'da kullan
await audioManager.playNewSound();
```

---

## ✨ Avantajları Bir Bakışta

| Avantaj | Açıklama |
|---------|----------|
| **🔧 Bakım Kolaylığı** | Ses değişecekse sadece game_audio_manager.dart |
| **🧪 Test Edilebilir** | Her modülü izole olarak test edebilirsiniz |
| **♻️ Yeniden Kullanılabilir** | GameStateManager başka ekranlarda da çalışabilir |
| **🚀 Genişletilebilir** | Yeni özellikler eklemeyi kolaylaştırır |
| **📚 Okunabilir** | Maksimum 425 satır, temiz ve anlaşılır |

---

## 🔍 Debug İpuçları

### Timer Durumu Kontrol
```dart
print('Timer: ${gameState.timerValue}s');
print('Ses çalıyor: ${audioManager.isTimerSoundPlaying}');
```

### Mevcut Oyuncu
```dart
print('Oyuncu: ${gameState.getCurrentPlayer()}');
print('Takım: ${gameState.currentTeam}');
```

### Skor Kontrolü
```dart
print('Skor: ${gameState.team1Score}-${gameState.team2Score}');
```

### Kelime Kontrolü
```dart
print('Kelime: ${gameState.words[gameState.currentWordIndex].word}');
print('Yasak: ${gameState.words[gameState.currentWordIndex].forbiddenWords}');
```

---

## 📊 İstatistikler

| Metrik | Değer |
|--------|-------|
| **Toplam Kod** | 1245 satır |
| **Ortalama Modül** | 249 satır |
| **En Büyük Modül** | 425 satır (dialogs) |
| **En Küçük Modül** | 76 satır (word_card) |
| **Dokümantasyon** | 4 detaylı dosya |

---

## 🎓 Öğrenilen Patterns

✅ **Single Responsibility** - Her sınıf bir şey yapar
✅ **Dependency Injection** - Bağımlılıklar enjekte edilir
✅ **Separation of Concerns** - Endişeler ayrılmıştır
✅ **DRY (Don't Repeat Yourself)** - Tekrar yok

---

## 🚀 Gelecek İyileştirmeler

1. **GameJokerManager** - Joker sistemi
2. **GameStatisticsManager** - İstatistikler
3. **GameAnimationManager** - Animasyonlar
4. **Provider/Riverpod** - State management
5. **GetIt** - Service Locator

---

## 📞 Sorunuz Mu Var?

- **Modülleri anlamak mı istersiniz?** → GAME_SCREEN_MODULAR_GUIDE.md
- **Teknik detaylar mı arıyorsunuz?** → GAME_SCREEN_ARCHITECTURE.md
- **Özet mi lazım?** → MODULAR_REFACTORING_SUMMARY.md

---

**Hepsi Hazır! 🎉**

