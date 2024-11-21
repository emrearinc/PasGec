import 'dart:async';
import 'package:flutter/material.dart';
import 'joker.dart'; // joker.dart dosyasını import ediyoruz
import 'dart:math';
import 'next_team_screen.dart'; // Yeni ekranı import edin
import 'package:auto_size_text/auto_size_text.dart';
import 'widgets/game_button_widget.dart';
import 'widgets/score_card_widget.dart';
import 'widgets/timer_widget.dart';
import 'widgets/turn_indicator_widget.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'database_helper.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:tabu_oyunu/models/player_performance.dart';
import 'package:tabu_oyunu/winner_screen.dart';

late AudioPlayer audioPlayer;

class GameScreen extends StatefulWidget {
  final List<String> team1Players;
  final List<String> team2Players;
  final String team1Name;
  final String team2Name;
  final int gameTime;
  final int gameScore;
  final int passLimit;
  final int tabooPenalty; // Tabu cezasını ekledik
  final bool showJokers;
  final double jokerProbability;


  const GameScreen({
    super.key,
    required this.team1Players,
    required this.team2Players,
    required this.team1Name,
    required this.team2Name,
    required this.gameTime,
    required this.gameScore,
    required this.passLimit,
    required this.tabooPenalty,
    required this.showJokers,
    required this.jokerProbability,
  });


  @override
  _GameScreenState createState() => _GameScreenState();
}

// Veritabanından alınan kelimeleri saklamak için model sınıfı
class Word {
  final int id;
  final String word;
  final List<String> forbiddenWords;

  Word({required this.id, required this.word, required this.forbiddenWords});

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      word: map['word'],
      forbiddenWords: (map['forbidden_words'] as String).split(', '),
    );
  }
}

class _GameScreenState extends State<GameScreen> {
  List<Word> words = [];
  int currentWordIndex = 0;
  late int timerValue;
  int team1Score = 0;
  int team2Score = 0;
  int currentTeam = 1;
  int currentPassCount = 0;
  Timer? timer;
  bool isPaused = false;
  bool isPassButtonDisabled = false;
  bool isGameOver = false;
  int correctCount = 0;
  int tabooCount = 0;
  int passCount = 0;
  List<String> remainingJokers = []; // Kullanılabilir jokerlerin listesi
  Set<String> usedJokers = {}; // Kullanılmış jokerlerin listesi
  Duration? currentSoundPosition; // Sesin mevcut oynatma konumu
  bool isPlayingSound = false; // Sesin çalıp çalmadığını kontrol etmek için
  int currentPlayerIndexTeam1 = 0;
  int currentPlayerIndexTeam2 = 0;

  List<PlayerPerformance> team1Performances = [];
  List<PlayerPerformance> team2Performances = [];

  @override
  void initState() {
    super.initState();

    // Performans listelerini oluştur ve sıfır değerlerle başlat
    team1Performances = widget.team1Players
        .map((player) => PlayerPerformance(
      playerName: player,
      correctCount: 0,
      tabooCount: 0,
      passCount: 0,
    ))
        .toList();

    team2Performances = widget.team2Players
        .map((player) => PlayerPerformance(
      playerName: player,
      correctCount: 0,
      tabooCount: 0,
      passCount: 0,
    ))
        .toList();

    // Zamanlayıcı ve diğer başlangıç değerlerini ayarla
    timerValue = widget.gameTime;
    currentPassCount = widget.passLimit;
    isPassButtonDisabled = currentPassCount == 0;

    // Veritabanından kelimeleri yükle
    fetchWordsFromDatabase();

    // Zamanlayıcıyı başlat
    startTimer();

    // Jokerleri sıfırla
    _resetJokers();

    // Ses oynatıcısını başlat
    audioPlayer = AudioPlayer();
  }


  Future<void> fetchWordsFromDatabase() async {
    try {
      final dbWords = await DatabaseHelper().getWords();

      if (dbWords.isEmpty) {
        // Veritabanında kelime bulunamadı mesajı
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veritabanında kelime bulunamadı!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      List<Word> loadedWords = dbWords.map((map) => Word.fromMap(map)).toList();
      loadedWords.shuffle(); // Kelimeleri karıştırıyoruz

      setState(() {
        words = loadedWords;
      });
    } catch (e) {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelimeler yüklenirken hata oluştu: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }




  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose(); // AudioPlayer'ı temizle
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timerValue > 0 && !isPaused) {
          timerValue--;

          // 10 saniye kaldığında sesi başlat
          if (timerValue == 10) {
            playTimerSound();
          }
        } else if (timerValue == 0 && !isGameOver) {
          timer.cancel();
          showTimeUpScreen();
        }
      });
    });
  }


  String getCurrentPlayer() {
    return currentTeam == 1
        ? widget.team1Players[currentPlayerIndexTeam1]
        : widget.team2Players[currentPlayerIndexTeam2];
  }

  String getNextPlayer() {
    if (currentTeam == 1) {
      // Eğer mevcut takım 1 ise, sıradaki takım 2'nin oyuncusunu döndür
      int nextIndex = (currentPlayerIndexTeam2 + 1) % widget.team2Players.length;
      return widget.team2Players[nextIndex];
    } else {
      // Eğer mevcut takım 2 ise, sıradaki takım 1'in oyuncusunu döndür
      int nextIndex = (currentPlayerIndexTeam1 + 1) % widget.team1Players.length;
      return widget.team1Players[nextIndex];
    }
  }
  void updatePlayerPerformance(String playerName, {int correct = 0, int taboo = 0, int pass = 0}) {
    setState(() {
      List<PlayerPerformance> currentTeamPerformances = currentTeam == 1 ? team1Performances : team2Performances;

      for (var performance in currentTeamPerformances) {
        if (performance.playerName == playerName) {
          performance.correctCount += correct;
          performance.tabooCount += taboo;
          performance.passCount += pass;
          break;
        }
      }
    });

    // Güncellemeden sonra listeyi kontrol et
    print("Updated Team 1 Performances: $team1Performances");
    print("Updated Team 2 Performances: $team2Performances");
  }

  void updatePlayerIndex() {
    setState(() {
      if (currentTeam == 1) {
        currentPlayerIndexTeam1 = (currentPlayerIndexTeam1 + 1) % widget.team1Players.length;
      } else {
        currentPlayerIndexTeam2 = (currentPlayerIndexTeam2 + 1) % widget.team2Players.length;
      }
    });
  }


  void playTimerSound() async {
    if (!isPlayingSound) {
      isPlayingSound = true;
      try {
        await audioPlayer.play(AssetSource('sound/timer.MP3'));
      } catch (e) {
        print('Ses çalma sırasında hata oluştu: $e');
      }
    }
  }



  void incrementCorrect() {
    updatePlayerPerformance(getCurrentPlayer(), correct: 1);
    setState(() {
      correctCount++;
      if (currentTeam == 1) {
        team1Score++;
      } else {
        team2Score++;
      }
      checkWinCondition();
      nextWord();
    });
  }

  void incrementTaboo() {
    updatePlayerPerformance(getCurrentPlayer(), taboo: 1);

    setState(() {
      tabooCount++;
      if (currentTeam == 1) {
        team1Score -= widget.tabooPenalty; // Seçilen tabu cezası kadar puan düş
      } else {
        team2Score -= widget.tabooPenalty; // Seçilen tabu cezası kadar puan düş
      }

      // Titreşim ekle
      Vibration.vibrate(duration: 500); // 500ms titreşim

      nextWord(); // Bir sonraki kelimeye geç
    });
  }



  void incrementPass() {
    updatePlayerPerformance(getCurrentPlayer(), pass: 1);

    setState(() {
      if (currentPassCount > 0) {
        passCount++;
        currentPassCount--;
        isPassButtonDisabled = currentPassCount == 0; // Pas hakkı biterse butonu devre dışı bırak

        nextWord(); // Bir sonraki kelimeye geç
      } else {
        // Pop-up gösterme ve timer'ın devam etmesini sağlama
        showDialog(
          context: context,
          barrierDismissible: true, // Kullanıcı boşluğa tıklarsa pop-up kapanır
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Pas Hakkınız Bitti!'),
              content: const Text('Pas hakkınız kalmadı. Oyuna devam edebilirsiniz.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Pop-up'ı kapat
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        ).then((_) {
          // Pop-up kapandıktan sonra timer devam etsin
          resumeTimer();
        });
      }
    });
  }


  void resetCounts() {
    correctCount = 0;
    tabooCount = 0;
    passCount = 0;
    isGameOver = false; // Yeni tur için isGameOver'ı sıfırlıyoruz
  }


  void showTimeUpScreen() {
    if (isGameOver) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NextTeamScreen(
          currentTeam: currentTeam == 1 ? widget.team1Name : widget.team2Name,
          nextTeam: currentTeam == 1 ? widget.team2Name : widget.team1Name,
          currentPlayer: getCurrentPlayer(),
          nextPlayer: getNextPlayer(),
          correctCount: correctCount,
          tabooCount: tabooCount,
          passCount: passCount,
        ),
      ),
    ).then((result) {
      if (result == true) {
        resetCounts();
        switchTurn();
        nextWord();
      }
    });
  }


  void switchTurn() {
    setState(() {
      currentTeam = currentTeam == 1 ? 2 : 1;

      if (currentTeam == 1) {
        currentPlayerIndexTeam1 = (currentPlayerIndexTeam1 + 1) % widget.team1Players.length;
      } else {
        currentPlayerIndexTeam2 = (currentPlayerIndexTeam2 + 1) % widget.team2Players.length;
      }

      currentPassCount = widget.passLimit;
      isPassButtonDisabled = currentPassCount == 0;
      resetTimer();
      showJokerMessage();
    });
  }

  void resetTimer() {
    setState(() {
      timerValue = widget.gameTime;
    });
    startTimer();
  }

  void pauseTimer() {
    if (!isPaused) {
      setState(() {
        isPaused = true;
      });
      timer?.cancel(); // Mevcut zamanlayıcıyı durdur
      timer = null; // Zamanlayıcı referansını sıfırla

      // Ses çalıyorsa durdur
      if (timerValue <= 10) {
        stopTimerSound();
      }
    }
  }


  void resumeTimer() {
    if (isPaused) {
      setState(() {
        isPaused = false;
      });
      if (timer == null) {
        startTimer(); // Zamanlayıcıyı yeniden başlat
      }

      // 10 saniye kaldıysa sesi yeniden başlat
      if (timerValue <= 10) {
        playTimerSound();
      }
    }
  }


  void stopTimerSound() async {
    if (isPlayingSound) {
      await audioPlayer.stop(); // Sesi durdur
      isPlayingSound = false;
    }
  }

  void resumeTimerSound() async {
    try {
      if (currentSoundPosition != null) {
        await audioPlayer.seek(currentSoundPosition!); // Kaldığı yerden devam et
        await audioPlayer.resume();
        isPlayingSound = true;
      }
    } catch (e) {
      print('Ses yeniden başlatılırken hata oluştu: $e');
    }
  }


  bool shouldShowJoker() {
    if (!widget.showJokers) return false; // Bu kontrol zaten `showJokerMessage` içinde yapılıyor.
    Random random = Random();
    return random.nextDouble() < widget.jokerProbability;
  }



  // Jokerleri sıfırlar ve kullanılabilir joker listesine atar
  void _resetJokers() {
    if (!widget.showJokers || Random().nextDouble() >= widget.jokerProbability) return;

  }

  void showJokerMessage() {
    // Joker gösterim seçeneğini kontrol et
    if (!widget.showJokers) return; // Joker gösterimi kapalıysa çık

    // Joker gösterim ihtimaline göre kontrol et
    Random random = Random();
    if (random.nextDouble() >= widget.jokerProbability) return; // Joker gösterilmeyecekse çık

    // Joker mesajını getir
    String? jokerMessage = Joker.getRandomJoker(probability: widget.jokerProbability);
    if (jokerMessage != null) {
      pauseTimer();

      // Rastgele animasyon, ikon ve diyalog tipi seçimi
      final List<AnimType> animations = [
        AnimType.scale,
        AnimType.leftSlide,
        AnimType.bottomSlide,
      ];
      final List<DialogType> dialogTypes = [
        DialogType.info,
        DialogType.warning,
        DialogType.noHeader,
      ];
      final List<IconData> icons = [
        Icons.casino,
        Icons.star,
        Icons.card_giftcard,
      ];

      final AnimType selectedAnimation = animations[random.nextInt(animations.length)];
      final DialogType selectedDialog = dialogTypes[random.nextInt(dialogTypes.length)];
      final IconData selectedIcon = icons[random.nextInt(icons.length)];

      // Joker mesajını göster
      AwesomeDialog(
        context: context,
        dialogType: selectedDialog,
        animType: selectedAnimation,
        customHeader: Icon(
          selectedIcon,
          color: Colors.orange,
          size: 50,
        ),
        title: 'Joker!',
        desc: jokerMessage, // Joker mesajını ekle
        btnOkText: 'Devam Et',
        btnOkOnPress: () {
          resumeTimer();
        },
      ).show();
    }
  }


  void resetGame() {
    setState(() {
      team1Score = 0;
      team2Score = 0;
      currentWordIndex = 0;
      currentTeam = 1;
      timerValue = widget.gameTime;
      currentPassCount = widget.passLimit;
      isPassButtonDisabled = currentPassCount == 0;
      correctCount = 0;
      tabooCount = 0;
      passCount = 0;
      isGameOver = false;
      _resetJokers(); // Jokerleri sıfırla

      // Performansları sıfırla
      resetPerformances();
    });

    timer?.cancel();
    startTimer();
    Navigator.pop(context); // Kazanan ekranından çıkış
  }

  void incrementScore(int teamNumber) {
    setState(() {
      if (teamNumber == 1) {
        team1Score++;
      } else {
        team2Score++;
      }
      checkWinCondition();
      nextWord();
    });
  }

  void decrementScore(int teamNumber) {
    setState(() {
      if (teamNumber == 1) {
        team1Score--; // 1. takımın skoru negatif değerlere düşebilir
      } else if (teamNumber == 2) {
        team2Score--; // 2. takımın skoru negatif değerlere düşebilir
      }
      nextWord();
    });
  }

  Set<int> usedWordIndexes = {};

    void nextWord() {
      setState(() {
        if (usedWordIndexes.length == words.length) {
          usedWordIndexes.clear();
        }
        do {
          currentWordIndex = Random().nextInt(words.length);
        } while (usedWordIndexes.contains(currentWordIndex));
        usedWordIndexes.add(currentWordIndex);
      });
    }




  void checkWinCondition() {
    if (team1Score >= widget.gameScore || team2Score >= widget.gameScore) {
      String winningTeam = team1Score >= widget.gameScore ? widget.team1Name : widget.team2Name;
      isGameOver = true;
      timer?.cancel();
      // Performans listelerini konsolda kontrol et
      print("Team 1 Performances: $team1Performances");
      print("Team 2 Performances: $team2Performances");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WinnerScreen(
            winningTeam: winningTeam,
            team1Name: widget.team1Name, // Takım 1 adı gönderiliyor
            team2Name: widget.team2Name, // Takım 2 adı gönderiliyor
            team1Performances: team1Performances,
            team2Performances: team2Performances,

            onPlayAgain: resetGame, // Yeniden oyun başlatma
            onSettings: () {
              Navigator.pop(context); // Ayarlar ekranına dönmek için
            },
            onMainMenu: () {
              Navigator.popUntil(context, (route) => route.isFirst); // Ana menüye dönmek için
            },
          ),
        ),
      );
    }
  }

  void resetPerformances() {
    setState(() {
      // Performans listelerini sıfırla
      team1Performances = widget.team1Players
          .map((player) => PlayerPerformance(
        playerName: player,
        correctCount: 0,
        tabooCount: 0,
        passCount: 0,
      ))
          .toList();

      team2Performances = widget.team2Players
          .map((player) => PlayerPerformance(
        playerName: player,
        correctCount: 0,
        tabooCount: 0,
        passCount: 0,
      ))
          .toList();
    });
  }



  void showWinningDialog(String winningTeam) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('$winningTeam Kazandı!'),
        content: const Text('Tebrikler, kazanan takım belli oldu. Oyun başa dönecek.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }



  void showPauseScreen() {
    if (!isPaused) {
      pauseTimer(); // Timer'ı durdur
    }

    showDialog(
      context: context,
      barrierDismissible: true, // Kullanıcı arka plana tıklarsa kapatılabilir
      barrierColor: Colors.black.withOpacity(0.9), // Karanlık arka plan
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // Yuvarlatılmış köşeler
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled,
                  size: 60,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oyun Durduruldu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Oyun şu an duraklatıldı. Devam etmek ister misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Diyalog kapat
                        resumeTimer(); // Timer'ı yeniden başlat
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Devam!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Diyalog kapat
                        confirmExit(); // Çıkış ekranını aç
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.home,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Menüye Dön',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      // Diyalog kapandığında ve oyun duraklatıldıysa süreyi yeniden başlat
      if (isPaused) {
        resumeTimer();
      }
    });
  }

  void confirmExit() {
    pauseTimer(); // Timer'ı durdur

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ana Menüye Dön',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Ana menüye dönmek istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Diyalog kapat
                        resumeTimer(); // Timer'ı yeniden başlat
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Hayır',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        stopTimerSound(); // Ses çalmayı durdur
                        Navigator.of(context).popUntil((route) => route.isFirst); // Ana menüye dön
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Evet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Diyalog kapandığında ve oyun duraklatılmışsa timer yeniden başlatılır
      if (isPaused) {
        resumeTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kullanıcı geri tuşuna bastığında çalışacak onay diyaloğu
        bool? shouldExit = await showDialog(
          context: context,
          barrierDismissible: true, // Kullanıcı arka plana tıklarsa diyalog kapansın
          barrierColor: Colors.black.withOpacity(0.7), // Arka plan karartma
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // Yumuşak köşeler
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Takım Seçimine Dön',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center, // Yazıları yatayda ortalar

                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Takım Seçimi Ekranına Dönmek İstediğinize Emin Misiniz?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(false); // Diyalog kapat, çıkışı engelle
                          },
                          icon: const Icon(Icons.close, color: Colors.black),
                          label: const Text(
                            'Hayır',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[300],
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(true); // Diyalog kapat, çıkışı onayla
                            resumeTimer(); // Timer'ı yeniden başlat

                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Evet',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return shouldExit ?? false; // Kullanıcı "Evet" dediyse çıkışa izin ver
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Oyun Ekranı'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.pinkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () {
                pauseTimer();
                showPauseScreen();
              },
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (words.isEmpty) {
              // Eğer kelimeler yüklenmediyse yükleniyor ekranı göster
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              );
            } else {
              // Kelimeler yüklendiğinde oyun ekranını göster
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.pinkAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
                        child: ListView(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: ScoreCardWidget(
                                    teamName: widget.team1Name,
                                    score: team1Score,
                                  ),
                                ),
                                Expanded(
                                  child: ScoreCardWidget(
                                    teamName: widget.team2Name,
                                    score: team2Score,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            TurnIndicatorWidget(
                              currentTeamName: currentTeam == 1 ? widget.team1Name : widget.team2Name,
                              currentPlayerName: getCurrentPlayer(), // Oyuncu adını gönderiyoruz
                            ),
                            const SizedBox(height: 0),
                            TimerWidget(timerValue: timerValue),
                            const SizedBox(height: 1),
                            _buildWordCard(words[currentWordIndex]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: GameButtonWidget(
                            label: 'Pas',
                            icon: Icons.skip_next,
                            color: isPassButtonDisabled ? Colors.grey : Colors.blue,
                            onPressed: isPassButtonDisabled ? () {} : incrementPass,
                          ),
                        ),
                        Expanded(
                          child: GameButtonWidget(
                            label: 'Tabu',
                            icon: Icons.cancel,
                            color: Colors.red,
                            onPressed: incrementTaboo,
                          ),
                        ),
                        Expanded(
                          child: GameButtonWidget(
                            label: 'Doğru',
                            icon: Icons.check_circle,
                            color: Colors.green,
                            onPressed: incrementCorrect,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }


  Widget _buildWordCard(Word word) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white.withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  word.word,
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(
                  height: 5,
                  color: Colors.deepPurple,
                  thickness: 1.5,
                ),
                Column(
                  children: word.forbiddenWords.map((forbiddenWord) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Center(
                            child: AutoSizeText(
                              forbiddenWord,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}