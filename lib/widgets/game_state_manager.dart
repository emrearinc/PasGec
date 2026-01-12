import 'dart:async';
import 'dart:math';
import 'package:tabu_oyunu/models/player_performance.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

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

class GameStateManager {
  // Oyun Durumu Değişkenleri
  List<Word> words = [];
  int currentWordIndex = 0;
  int timerValue = 0;
  int team1Score = 0;
  int team2Score = 0;
  int currentTeam = 1;
  int currentPassCount = 0;
  bool isPaused = false;
  bool isPassButtonDisabled = false;
  bool isGameOver = false;
  int correctCount = 0;
  int tabooCount = 0;
  int passCount = 0;
  int currentPlayerIndexTeam1 = 0;
  int currentPlayerIndexTeam2 = 0;

  List<PlayerPerformance> team1Performances = [];
  List<PlayerPerformance> team2Performances = [];

  // Oyun Parametreleri
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

  // Timer
  Timer? timer;
  Set<int> usedWordIndexes = {};

  GameStateManager({
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
  }) {
    _initializeGame();
  }

  void _initializeGame() {
    timerValue = gameTime;
    currentPassCount = passLimit;
    isPassButtonDisabled = currentPassCount == 0;

    // Performans listelerini oluştur
    team1Performances = team1Players
        .map((player) => PlayerPerformance(
              playerName: player,
              correctCount: 0,
              tabooCount: 0,
              passCount: 0,
            ))
        .toList();

    team2Performances = team2Players
        .map((player) => PlayerPerformance(
              playerName: player,
              correctCount: 0,
              tabooCount: 0,
              passCount: 0,
            ))
        .toList();
  }

  String getCurrentPlayer() {
    return currentTeam == 1
        ? team1Players[currentPlayerIndexTeam1]
        : team2Players[currentPlayerIndexTeam2];
  }

  String getNextPlayer() {
    if (currentTeam == 1) {
      int nextIndex = (currentPlayerIndexTeam2 + 1) % team2Players.length;
      return team2Players[nextIndex];
    } else {
      int nextIndex = (currentPlayerIndexTeam1 + 1) % team1Players.length;
      return team1Players[nextIndex];
    }
  }

  void updatePlayerPerformance(String playerName,
      {int correct = 0, int taboo = 0, int pass = 0}) {
    List<PlayerPerformance> currentTeamPerformances =
        currentTeam == 1 ? team1Performances : team2Performances;

    for (var performance in currentTeamPerformances) {
      if (performance.playerName == playerName) {
        performance.correctCount += correct;
        performance.tabooCount += taboo;
        performance.passCount += pass;
        break;
      }
    }
  }

  void updatePlayerIndex() {
    if (currentTeam == 1) {
      currentPlayerIndexTeam1 =
          (currentPlayerIndexTeam1 + 1) % team1Players.length;
    } else {
      currentPlayerIndexTeam2 =
          (currentPlayerIndexTeam2 + 1) % team2Players.length;
    }
  }

  void incrementCorrect() {
    updatePlayerPerformance(getCurrentPlayer(), correct: 1);
    correctCount++;
    if (currentTeam == 1) {
      team1Score++;
    } else {
      team2Score++;
    }
  }

  void incrementTaboo() {
    updatePlayerPerformance(getCurrentPlayer(), taboo: 1);
    tabooCount++;
    if (currentTeam == 1) {
      team1Score -= tabooPenalty;
    } else {
      team2Score -= tabooPenalty;
    }
  }

  void incrementPass() {
    updatePlayerPerformance(getCurrentPlayer(), pass: 1);
    if (currentPassCount > 0) {
      passCount++;
      currentPassCount--;
      isPassButtonDisabled = currentPassCount == 0;
    }
  }

  void resetCounts() {
    correctCount = 0;
    tabooCount = 0;
    passCount = 0;
    isGameOver = false;
  }

  void resetTimer() {
    timerValue = gameTime;
  }

  void startTimer(Function onTick, Function onTimeUp) {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerValue > 0 && !isPaused) {
        timerValue--;
        onTick();
        if (timerValue == 0) {
          timer.cancel();
          onTimeUp();
        }
      }
    });
  }

  void pauseTimer() {
    if (!isPaused) {
      isPaused = true;
      timer?.cancel();
      timer = null;
    }
  }

  void resumeTimer(Function onTick, Function onTimeUp) {
    if (isPaused) {
      isPaused = false;
      if (timer == null) {
        startTimer(onTick, onTimeUp);
      }
    }
  }

  void switchTurn() {
    currentTeam = currentTeam == 1 ? 2 : 1;

    if (currentTeam == 1) {
      currentPlayerIndexTeam1 =
          (currentPlayerIndexTeam1 + 1) % team1Players.length;
    } else {
      currentPlayerIndexTeam2 =
          (currentPlayerIndexTeam2 + 1) % team2Players.length;
    }

    currentPassCount = passLimit;
    isPassButtonDisabled = currentPassCount == 0;
  }

  Future<void> nextWord() async {
    if (usedWordIndexes.length == words.length) {
      usedWordIndexes.clear();
    }

    int newIndex;
    do {
      newIndex = Random().nextInt(words.length);
    } while (usedWordIndexes.contains(newIndex));

    currentWordIndex = newIndex;
    usedWordIndexes.add(newIndex);

    // Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'word_displayed',
      parameters: {
        'word': words[currentWordIndex].word,
      },
    );
  }

  void resetGame() {
    team1Score = 0;
    team2Score = 0;
    currentWordIndex = 0;
    currentTeam = 1;
    timerValue = gameTime;
    currentPassCount = passLimit;
    isPassButtonDisabled = currentPassCount == 0;
    correctCount = 0;
    tabooCount = 0;
    passCount = 0;
    isGameOver = false;
    usedWordIndexes.clear();

    resetPerformances();
    timer?.cancel();
  }

  void resetPerformances() {
    team1Performances = team1Players
        .map((player) => PlayerPerformance(
              playerName: player,
              correctCount: 0,
              tabooCount: 0,
              passCount: 0,
            ))
        .toList();

    team2Performances = team2Players
        .map((player) => PlayerPerformance(
              playerName: player,
              correctCount: 0,
              tabooCount: 0,
              passCount: 0,
            ))
        .toList();
  }

  bool shouldShowJoker() {
    if (!showJokers) return false;
    Random random = Random();
    return random.nextDouble() < jokerProbability;
  }

  void dispose() {
    timer?.cancel();
  }
}
