import 'dart:async';
import 'package:flutter/material.dart';
import 'joker.dart'; // joker.dart dosyasını import ediyoruz
import 'dart:math';
import 'next_team_screen.dart'; // Yeni ekranı import edin
import 'package:auto_size_text/auto_size_text.dart';
import 'winner_screen.dart';
import 'widgets/game_button_widget.dart';
import 'widgets/score_card_widget.dart';
import 'widgets/timer_widget.dart';
import 'widgets/turn_indicator_widget.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'database_helper.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
late AudioPlayer audioPlayer;

class GameScreen extends StatefulWidget {
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
    required this.team1Name,
    required this.team2Name,
    required this.gameTime,
    required this.gameScore,
    required this.passLimit, // Yapıcıya (constructor) ekledik
    required this.tabooPenalty, // Parametre olarak yapıcıya ekledik
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


  @override
  void initState() {
    super.initState();
    timerValue = widget.gameTime;
    currentPassCount = widget.passLimit;
    isPassButtonDisabled = currentPassCount == 0;
    //addSampleWords();
    fetchWordsFromDatabase();
    startTimer();
    _resetJokers(); // Oyun başladığında jokerleri sıfırla
    audioPlayer = AudioPlayer(); // AudioPlayer'ı başlatıyoruz

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

          // 10 saniye kaldığında sesi çal
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
  void playTimerSound() async {
    try {
      await audioPlayer.play(AssetSource('sound/timer.MP3'));
    } catch (e) {
      print('Ses çalma sırasında hata oluştu: $e');
    }
  }


  void incrementCorrect() {
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
    setState(() {
      tabooCount++;
      if (currentTeam == 1) {
        team1Score -= widget.tabooPenalty; // Seçilen tabu cezası kadar puan düş
      } else {
        team2Score -= widget.tabooPenalty; // Seçilen tabu cezası kadar puan düş
      }

      // Titreşim ekle
      if (Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 500); // 500ms titreşim
      }

      nextWord(); // Bir sonraki kelimeye geç
    });
  }



  void incrementPass() {
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
          correctCount: correctCount,
          tabooCount: tabooCount,
          passCount: passCount,
        ),
      ),
    ).then((result) {
      // Eğer NextTeamScreen'den true dönerse kelimeyi yenile
      if (result == true) {
        resetCounts(); // Skor sayacı sıfırla
        switchTurn(); // Takım değiştir
        nextWord(); // Yeni kelime seç
      }
    });
  }




  void switchTurn() {
    setState(() {
      currentTeam = currentTeam == 1 ? 2 : 1;
      currentPassCount = widget.passLimit; // Yeni turda pas hakları sıfırlanır
      isPassButtonDisabled = currentPassCount == 0; // Yeni turda pas butonunun durumunu güncelle
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
    setState(() {
      isPaused = true;
    });
    timer?.cancel();
  }

  void resumeTimer() {
    setState(() {
      isPaused = false;
    });
    startTimer();
  }

  bool shouldShowJoker() {
    if (!widget.showJokers) return false; // Bu kontrol zaten `showJokerMessage` içinde yapılıyor.
    Random random = Random();
    return random.nextDouble() < widget.jokerProbability;
  }



  // Jokerleri sıfırlar ve kullanılabilir joker listesine atar
  void _resetJokers() {
    remainingJokers = List.from(Joker.jokerMessages);
    usedJokers.clear();
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


  // Oyun sıfırlandığında jokerleri de sıfırla
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
        // Tüm kelimeler gösterildiyse resetlenir.
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
      isGameOver = true;  // Oyun kazanan ekranına geçerken isGameOver'ı true yapıyoruz
      timer?.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WinnerScreen(
            winningTeam: winningTeam,
            onPlayAgain: resetGame,
            onSettings: () {
              Navigator.pop(context);
            },
            onMainMenu: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
      );
    }
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
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Durduruldu'),
        content: const Text('Oyun şu an duraklatıldı. Devam etmek ister misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resumeTimer(); // Ekrana geri dönülürse timer tekrar başlatılır
            },
            child: const Text('Devam Et'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              confirmExit(); // Çıkış ekranı açılır
            },
            child: const Text('Ana Menüye Dön'),
          ),
        ],
      ),
    ).then((value) {
      // Kullanıcı diyaloğu kapattıysa ve "Devam Et" seçilmediyse timer yeniden başlatılır
      if (isPaused) {
        resumeTimer(); // Timer'ı tekrar başlat
      }
    });
  }

  void confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ana Menüye Dön'),
        content: const Text('Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kullanıcı geri tuşuna bastığında çalışacak onay diyaloğu
        bool? shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ana Menüye Dön'),
            content: const Text('Ana menüye dönmek istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Diyaloğu kapat, çıkışı engelle
                },
                child: const Text('Hayır'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Diyaloğu kapat, çıkışı onayla
                },
                child: const Text('Evet'),
              ),
            ],
          ),
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