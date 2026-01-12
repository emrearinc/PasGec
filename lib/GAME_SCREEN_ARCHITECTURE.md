# Game Screen Modüler Mimarisi - Teknik Referans

## 📐 Mimari Diyagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GameScreen (Main Widget)                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                GameScreenState                           │  │
│  │                                                          │  │
│  │  - gameState: GameStateManager                          │  │
│  │  - audioManager: GameAudioManager                       │  │
│  │  - words: List<Word>                                    │  │
│  │                                                          │  │
│  │  Methods:                                               │  │
│  │  - _handleCorrect()    ─────┐                          │  │
│  │  - _handleTaboo()      ─────┼─→ Modüller              │  │
│  │  - _handlePass()       ─────┤                          │  │
│  │  - _pauseGame()        ─────┤                          │  │
│  │  - _confirmExit()      ─────┘                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
        │                    │                    │
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│GameStateManager  │ │GameAudioManager  │ │ GameDialogs      │
│                  │ │                  │ │                  │
│Properties:       │ │Properties:       │ │Static Methods:   │
│- words[]         │ │- audioPlayer     │ │- showPause()     │
│- timerValue      │ │- timerAudioPlayer│ │- showExit()      │
│- team1Score      │ │- isPlayingSound  │ │- showPassLimit() │
│- team2Score      │ │                  │ │- showJoker()     │
│- currentTeam     │ │Methods:          │ │- showNoWords()   │
│- passCount       │ │- playSound()     │ │                  │
│- timer           │ │- playTimerSound()│ │                  │
│                  │ │- stopTimer()     │ │                  │
│Methods:          │ │- dispose()       │ │                  │
│- incrementXXX()  │ │                  │ │                  │
│- nextWord()      │ │                  │ │                  │
│- switchTurn()    │ │                  │ │                  │
│- resetGame()     │ │                  │ │                  │
│- startTimer()    │ │                  │ │                  │
│- dispose()       │ │                  │ │                  │
└──────────────────┘ └──────────────────┘ └──────────────────┘
        │                    │
        │                    │
        └────────┬───────────┘
                 ▼
        ┌──────────────────────┐
        │  GameWordCard        │
        │  (Display Widget)    │
        │                      │
        │  - word: Word        │
        │  - forbiddenWords[]  │
        └──────────────────────┘
```

---

## 🔗 Sınıf İlişkileri

### GameStateManager

```dart
class GameStateManager {
  // === Oyun Parametreleri ===
  final List<String> team1Players;
  final List<String> team2Players;
  final String team1Name;
  final String team2Name;
  final int gameTime;
  final int gameScore;
  final int passLimit;
  final int tabooPenalty;
  final bool showJokers;
  final double jokerProbability;

  // === Oyun Durumu ===
  List<Word> words;
  int currentWordIndex;
  int timerValue;
  int team1Score;
  int team2Score;
  int currentTeam;
  int currentPassCount;
  bool isPaused;
  bool isPassButtonDisabled;
  bool isGameOver;

  // === Sayaçlar ===
  int correctCount;
  int tabooCount;
  int passCount;

  // === Oyuncu Takibi ===
  int currentPlayerIndexTeam1;
  int currentPlayerIndexTeam2;
  List<PlayerPerformance> team1Performances;
  List<PlayerPerformance> team2Performances;

  // === Timer ===
  Timer? timer;
  Set<int> usedWordIndexes;
}
```

### GameAudioManager

```dart
class GameAudioManager {
  // === Ses Çalarlar ===
  late AudioPlayer audioPlayer;        // Genel sesler (doğru, tabu, pas)
  late AudioPlayer timerAudioPlayer;   // Timer sesi

  // === Durum ===
  bool isTimerSoundPlaying;
  Duration? currentSoundPosition;
  bool isPlayingSound;

  // === Metotlar ===
  Future<void> playSound(String assetPath)
  Future<void> playTimerSound()
  void stopTimerSound()
  Future<void> playCorrectSound()      // → sound/dogru.MP3
  Future<void> playTabooSound()        // → sound/tabu.MP3
  Future<void> playPassSound()         // → sound/pas.MP3
  Future<void> resumeTimerSound()
  void dispose()
}
```

### GameDialogs

```dart
class GameDialogs {
  // === Statik Diyalog Metotları ===
  static Future<void> showPauseDialog(...)
  static Future<void> showExitConfirmDialog(...)
  static Future<void> showPassLimitDialog(...)
  static Future<void> showJokerDialog(...)
  static Future<void> showNoWordsDialog(...)
  static Future<bool> showExitConfirmationDialog(...)
}
```

### GameWordCard

```dart
class GameWordCard extends StatelessWidget {
  final Word word;
  
  @override
  Widget build(BuildContext context) {
    // Kelime kartını görüntüle
    // - Ana kelime (büyük yazı)
    // - Yasak kelimeler (daha küçük)
    // - Card animasyonları
  }
}
```

---

## 🔄 Durum Geçişleri

### Doğru Cevap Akışı

```
User Taps "Doğru"
    ↓
_handleCorrect()
    ├→ gameState.incrementCorrect()      [Puan +1]
    ├→ setState()                         [UI güncelle]
    ├→ audioManager.playCorrectSound()   [Ses çal: dogru.MP3]
    ├→ _checkWinCondition()              [Kazanma kontrolü]
    ├→ gameState.nextWord()              [Sonraki kelime]
    └→ setState()                         [UI güncelle]
```

### Tabu Cezası Akışı

```
User Taps "Tabu"
    ↓
_handleTaboo()
    ├→ gameState.incrementTaboo()        [Puan -tabooPenalty]
    ├→ setState()                         [UI güncelle]
    ├→ audioManager.playTabooSound()     [Ses çal: tabu.MP3]
    ├→ Vibration.vibrate()               [Titreşim]
    ├→ gameState.nextWord()              [Sonraki kelime]
    └→ setState()                         [UI güncelle]
```

### Pas Akışı

```
User Taps "Pas"
    ↓
_handlePass()
    ├→ if (passCount > 0)
    │   ├→ gameState.incrementPass()
    │   ├→ setState()
    │   ├→ audioManager.playPassSound()
    │   ├→ gameState.nextWord()
    │   └→ setState()
    └→ else
        └→ showPassLimitDialog()
```

### Tur Sonu Akışı

```
Timer Reaches 0
    ↓
_onTimeUp()
    ↓
_showTimeUpScreen()
    ├→ Navigator.push(NextTeamScreen)
    └→ Sonuç = true
        ├→ gameState.resetCounts()
        ├→ gameState.switchTurn()
        │   ├→ currentTeam değiştir
        │   ├→ playerIndex güncelle
        │   └→ passLimit sıfırla
        ├→ gameState.nextWord()
        ├→ gameState.resetTimer()
        ├→ _startGame()              [Timer yeniden başla]
        ├→ setState()
        └→ _showJokerIfNeeded()
```

---

## 💾 Veri Kaynakları

### Word Modeli

```dart
class Word {
  final int id;
  final String word;
  final List<String> forbiddenWords;
  
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      word: map['word'],
      forbiddenWords: (map['forbidden_words'] as String).split(', '),
    );
  }
}
```

**Veritabanından Yükleme:**
```dart
final dbWords = await DatabaseHelper().getWords(
  where: 'is_active = ?',
  whereArgs: [1]
);
List<Word> loadedWords = dbWords.map((map) => Word.fromMap(map)).toList();
```

---

## 🎯 İşletme Noktaları (Entry Points)

| Metot | Açıklama |
|-------|----------|
| `_handleCorrect()` | Doğru cevap butonuna tıklandı |
| `_handleTaboo()` | Tabu butonuna tıklandı |
| `_handlePass()` | Pas butonuna tıklandı |
| `_pauseGame()` | Pause ikonuna tıklandı |
| `_confirmExit()` | Çıkış onaylandı |
| `_onTimerTick()` | Her saniye çağrılır |
| `_onTimeUp()` | Timer bitti |
| `fetchWordsFromDatabase()` | initState'te çağrılır |

---

## 🔌 Bağımlılıklar

| Modül | Bağımlı | Nedeni |
|-------|--------|-------|
| GameScreen | GameStateManager | Oyun durumu yönetimi |
| GameScreen | GameAudioManager | Ses çalma |
| GameScreen | GameDialogs | Diyalogları gösterme |
| GameScreen | GameWordCard | Kelime görüntüleme |
| GameStateManager | Word | Kelime modeli |
| GameScreen | DatabaseHelper | Veri yükleme |
| GameScreen | Vibration | Titreşim |
| GameScreen | WinnerScreen | Kazanan gösterme |

---

## 🐛 Debug Noktaları

```dart
// Timer durumunu kontrol et
print('Timer: ${gameState.timerValue}');
print('Ses Çalıyor: ${audioManager.isTimerSoundPlaying}');

// Oyuncu performansını kontrol et
for (var perf in gameState.team1Performances) {
  print('${perf.playerName}: ${perf.correctCount}');
}

// Mevcut kelimeyi kontrol et
print('Kelime: ${words[gameState.currentWordIndex].word}');

// Durum göster
print('Takım: ${gameState.currentTeam}');
print('Skor: ${gameState.team1Score} - ${gameState.team2Score}');
```

---

## ✅ Testleme Stratejisi

### Unit Tests

```dart
// GameStateManager testi
test('incrementCorrect should increase score', () {
  var state = GameStateManager(...);
  state.incrementCorrect();
  expect(state.team1Score, 1);
});

// GameAudioManager testi
test('playSound should not throw exception', () async {
  var audio = GameAudioManager();
  await audio.playCorrectSound();
  // Assertion
});
```

### Widget Tests

```dart
// GameScreen testi
testWidgets('Should show word card', (tester) async {
  await tester.pumpWidget(GameScreen(...));
  expect(find.byType(GameWordCard), findsOneWidget);
});
```

---

## 🚀 Performans Optimizasyonları

1. **Kelime Karıştırma**: `loadedWords.shuffle()` - Performans iyidir
2. **Set Kullanımı**: `usedWordIndexes` - O(1) lookup
3. **Lazy Loading**: Kelimeler sadece başlangıçta yüklenir
4. **Ses Cacheleme**: AudioPlayer reuse edilir
5. **Timer Optimize**: Tek bir Timer kullanılır

