# Game Screen Modüler Yapı - Dokümantasyon

## 📋 Genel Bakış

`game_screen.dart` dosyası, aşağıdaki modüler bileşenlere bölünmüştür. Bu yapı, kodun bakımını, test edilebilirliğini ve genişletilmesini kolaylaştırır.

## 📁 Dosya Yapısı

```
lib/
├── game_screen.dart                 # Ana oyun ekranı (UI ve kontroller)
├── widgets/
│   ├── game_state_manager.dart     # Oyun durumu ve mantığı
│   ├── game_audio_manager.dart     # Ses yönetimi
│   ├── game_dialogs.dart           # Diyalog pencereleri
│   ├── game_word_card.dart         # Kelime kartı widget'ı
│   ├── game_button_widget.dart     # (Var olan)
│   ├── score_card_widget.dart      # (Var olan)
│   ├── timer_widget.dart           # (Var olan)
│   └── turn_indicator_widget.dart  # (Var olan)
```

---

## 🔧 Modüller

### 1. **game_state_manager.dart**
Oyunun tüm durumunu ve iş mantığını yönetir.

**Ana Sorumlulukluk:**
- Oyun durumu (skorlar, sıra, timer vb.)
- Oyuncu performans takibi
- Kelime yönetimi
- Tur değişimi
- Puan hesaplaması

**Temel Sınıflar:**
```dart
class Word {
  final int id;
  final String word;
  final List<String> forbiddenWords;
}

class GameStateManager {
  // Oyun durumu özellikleri
  List<Word> words;
  int currentTeam;
  int team1Score, team2Score;
  
  // Temel metotlar
  void incrementCorrect()
  void incrementTaboo()
  void incrementPass()
  void switchTurn()
  Future<void> nextWord()
}
```

---

### 2. **game_audio_manager.dart**
Tüm ses yönetimini merkezileştirir.

**Ana Sorumlulukluk:**
- Doğru/yanlış/pas seslerinin oynatılması
- Timer sesinin kontrolü
- Ses kaynaklarının yönetimi

**Temel Metotlar:**
```dart
Future<void> playSound(String assetPath)
Future<void> playTimerSound()
void stopTimerSound()
Future<void> playCorrectSound()
Future<void> playTabooSound()
Future<void> playPassSound()
void dispose()
```

---

### 3. **game_dialogs.dart**
Tüm diyalog ve pop-up pencereleri içerir.

**Ana Sorumlulukluk:**
- Oyun duraklama diyaloğu
- Çıkış onayı diyaloğu
- Pas hakkı bitme uyarısı
- Joker mesajı gösterimi
- Kelime yükleme hatası uyarısı

**Temel Metotlar:**
```dart
static Future<void> showPauseDialog(...)
static Future<void> showExitConfirmDialog(...)
static Future<void> showPassLimitDialog(...)
static Future<void> showJokerDialog(...)
static Future<void> showNoWordsDialog(...)
static Future<bool> showExitConfirmationDialog(...)
```

---

### 4. **game_word_card.dart**
Kelime kartını gösteran widget.

**Ana Sorumlulukluk:**
- Kelime gösterimi
- Yasak kelimeleri görüntüleme
- Card tasarımı ve animasyonları

```dart
class GameWordCard extends StatelessWidget {
  final Word word;
  // Widget oluşturma
}
```

---

### 5. **game_screen.dart** (Ana Ekran)
Tüm modülleri bir araya getiren ana ekrandır.

**Ana Sorumlulukluk:**
- UI düzeni ve AppBar
- Kullanıcı etkileşimleri
- Modüller arasında koordinasyon
- Veritabanından veri yükleme

**Temel Metotlar:**
```dart
class GameScreenState extends State<GameScreen> {
  late GameStateManager gameState;
  late GameAudioManager audioManager;
  
  void _handleCorrect()
  void _handleTaboo()
  void _handlePass()
  void _pauseGame()
  void _confirmExit()
  void _checkWinCondition()
}
```

---

## 🔄 Veri Akışı

```
GameScreen (UI)
    ↓
GameStateManager (Durum) ← → GameAudioManager (Ses)
    ↓                              ↓
GameDialogs (Diyaloglar)    GameWordCard (Widget)
```

---

## 📊 Örnek Kullanım: Doğru Cevap

```dart
// Kullanıcı "Doğru" butonuna tıkladı
void _handleCorrect() async {
  // 1. Durumu güncelle
  gameState.incrementCorrect();
  setState(() {});
  
  // 2. Ses çal
  await audioManager.playCorrectSound();
  
  // 3. Kazanma koşulunu kontrol et
  _checkWinCondition();
  
  // 4. Sonraki kelimeye geç
  await gameState.nextWord();
  setState(() {});
}
```

---

## 🎮 Temel Akışlar

### Oyun Başlangıcı
```
1. GameStateManager oluştur
2. GameAudioManager oluştur
3. Kelimeleri veritabanından yükle
4. Timer'ı başlat (_startGame)
```

### Tur Sonu
```
1. NextTeamScreen'e git
2. resetCounts() çağır
3. switchTurn() çağır
4. nextWord() çağır
5. Timer'ı sıfırla
```

### Oyun Sonunda
```
1. WinnerScreen'e git
2. Performans verilerini ilet
3. onPlayAgain: _resetAndPlay() çağırıldığında sıfırla
```

---

## ✨ Avantajları

### ✅ Modülerlik
- Her modül tek bir sorumluluğa sahiptir
- Bağımlılıklar minimal

### ✅ Bakım Kolaylığı
- Ses sistemi değiştiğinde sadece `game_audio_manager.dart` düzenlenir
- Diyalog tasarımı değiştiğinde sadece `game_dialogs.dart` düzenlenir

### ✅ Test Edilebilirlik
- Her modülü izole olarak test edebilirsiniz
- Mock'ları kolayca oluşturabilirsiniz

### ✅ Yeniden Kullanılabilirlik
- `GameStateManager`'ı başka ekranlarda da kullanabilirsiniz
- `GameAudioManager` bağımsızdır

### ✅ Genişletme Kolaylığı
- Yeni bir diyalog eklemek? → `game_dialogs.dart`'a ekle
- Vibration eklemek? → `game_audio_manager.dart`'ı genişlet
- Yeni oyun modu? → `GameStateManager`'a ekle

---

## 🔧 Gelecek Geliştirmeler

1. **gameState.resetTimer()** içinde `startTimer`'ı otomatik çağır
2. **Joker sistemi** için ayrı bir `game_joker_manager.dart` oluştur
3. **Performans analizi** için ayrı bir modül ekle
4. **İstatistikler** için `GameStatsManager` oluştur
5. **Ses ayarları** için `GameAudioSettings` sınıfı ekle

---

## 📝 Notlar

- `Word` sınıfı `game_state_manager.dart` içinde tanımlanmıştır
- Tüm callback'ler `Function` türünde oper (VoidCallback yerine)
- `setState()` çağrıları ana ekranda gerçekleşir
- Timer yönetimi `GameStateManager` tarafından yapılır

