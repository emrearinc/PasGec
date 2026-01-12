import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'next_team_screen.dart';
import 'widgets/game_button_widget.dart';
import 'widgets/score_card_widget.dart';
import 'widgets/timer_widget.dart';
import 'widgets/turn_indicator_widget.dart';
import 'widgets/game_state_manager.dart';
import 'widgets/game_audio_manager.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_word_card.dart';
import 'database_helper.dart';
import 'package:vibration/vibration.dart';
import 'package:tabu_oyunu/winner_screen.dart';
import 'services/connectivity_service.dart';
import 'services/offline_sync_service.dart';

class GameScreen extends StatefulWidget {
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
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> {
  late GameStateManager gameState;
  late GameAudioManager audioManager;
  List<Word> words = [];
  late StreamSubscription<bool> _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();

    // Connectivity dinleyicisini başlat
    _initConnectivityListener();

    // GameStateManager'ı oluştur
    gameState = GameStateManager(
      team1Players: widget.team1Players,
      team2Players: widget.team2Players,
      team1Name: widget.team1Name,
      team2Name: widget.team2Name,
      gameTime: widget.gameTime,
      gameScore: widget.gameScore,
      passLimit: widget.passLimit,
      tabooPenalty: widget.tabooPenalty,
      showJokers: widget.showJokers,
      jokerProbability: widget.jokerProbability,
    );

    // AudioManager'ı oluştur
    audioManager = GameAudioManager();

    // Veritabanından kelimeleri yükle
    fetchWordsFromDatabase();

    // Timer'ı başlat
    _startGame();
  }

  void _initConnectivityListener() {
    _connectivitySubscription =
        ConnectivityService().isOnlineStream.listen((isOnline) {
      setState(() => _isOnline = isOnline);

      if (!_isOnline) {
        // Offline moda geç
        OfflineSyncService().setOfflineMode(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📡 Bağlantı kesildi - Offline modda çalışıyor'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Online'a dön ve senkronize et
        OfflineSyncService().setOfflineMode(false);
        _syncOfflineData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bağlantı kuruıldı - Senkronize ediliyor'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _syncOfflineData() async {
    try {
      await OfflineSyncService().syncWithConflictResolution();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Veriler senkronize edildi'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Senkronizasyon hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchWordsFromDatabase() async {
    try {
      // SharedPreferences'tan seçili kategorileri al
      final prefs = await SharedPreferences.getInstance();
      final selectedCategories =
          prefs.getStringList('selectedCategories') ?? [];

      // null veya boş => tüm kategoriler
      final dbWords = await DatabaseHelper().getActiveWordsByCategories(
          selectedCategories.isEmpty ? null : selectedCategories);

      if (dbWords.isEmpty && mounted) {
        await GameDialogs.showNoWordsDialog(context);
      }

      List<Word> loadedWords = dbWords.map((map) => Word.fromMap(map)).toList();
      loadedWords.shuffle();

      if (mounted) {
        setState(() {
          words = loadedWords;
          gameState.words = loadedWords;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kelimeler yüklenirken hata oluştu: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startGame() {
    gameState.startTimer(_onTimerTick, _onTimeUp);
  }

  void _onTimerTick() {
    setState(() {
      // 5 saniye kaldığında timer sesini çal
      if (gameState.timerValue == 5 && !audioManager.isTimerSoundPlaying) {
        audioManager.playTimerSound();
      }
    });
  }

  void _onTimeUp() {
    if (!gameState.isGameOver) {
      _showTimeUpScreen();
    }
  }

  void _showTimeUpScreen() {
    if (gameState.isGameOver) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NextTeamScreen(
          currentTeam:
              gameState.currentTeam == 1 ? widget.team1Name : widget.team2Name,
          nextTeam:
              gameState.currentTeam == 1 ? widget.team2Name : widget.team1Name,
          currentPlayer: gameState.getCurrentPlayer(),
          nextPlayer: gameState.getNextPlayer(),
          correctCount: gameState.correctCount,
          tabooCount: gameState.tabooCount,
          passCount: gameState.passCount,
          currentTeamScore: gameState.team1Score,
          nextTeamScore: gameState.team2Score,
        ),
      ),
    ).then((result) {
      if (result == true) {
        gameState.resetCounts();
        gameState.switchTurn();
        gameState.nextWord();
        gameState.resetTimer();
        _startGame();
        setState(() {});
        _showJokerIfNeeded();
      }
    });
  }

  void _showJokerIfNeeded() {
    if (gameState.shouldShowJoker()) {
      gameState.pauseTimer();
      GameDialogs.showJokerDialog(
        context,
        onClose: () {
          gameState.resumeTimer(_onTimerTick, _onTimeUp);
        },
      );
    }
  }

  void _handleCorrect() async {
    gameState.incrementCorrect();
    setState(() {});
    await audioManager.playCorrectSound();
    _checkWinCondition();
    await gameState.nextWord();
    setState(() {});
  }

  void _handleTaboo() async {
    gameState.incrementTaboo();
    setState(() {});
    await audioManager.playTabooSound();
    Vibration.vibrate(duration: 200);
    await gameState.nextWord();
    setState(() {});
  }

  void _handlePass() async {
    if (gameState.currentPassCount > 0) {
      gameState.incrementPass();
      setState(() {});
      await audioManager.playPassSound();
      await gameState.nextWord();
      setState(() {});
    } else {
      gameState.pauseTimer();
      await GameDialogs.showPassLimitDialog(context, () {
        gameState.resumeTimer(_onTimerTick, _onTimeUp);
      });
    }
  }

  void _checkWinCondition() {
    if (gameState.team1Score >= widget.gameScore ||
        gameState.team2Score >= widget.gameScore) {
      String winningTeam = gameState.team1Score >= widget.gameScore
          ? widget.team1Name
          : widget.team2Name;
      gameState.isGameOver = true;
      gameState.timer?.cancel();
      audioManager.stopTimerSound();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WinnerScreen(
            winningTeam: winningTeam,
            team1Name: widget.team1Name,
            team2Name: widget.team2Name,
            team1Performances: gameState.team1Performances,
            team2Performances: gameState.team2Performances,
            onPlayAgain: _resetAndPlay,
            onMainMenu: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }

  void _resetAndPlay() {
    gameState.resetGame();
    _startGame();
    setState(() {});
    Navigator.pop(context);
  }

  void _pauseGame() {
    gameState.pauseTimer();
    GameDialogs.showPauseDialog(
      context,
      onResume: () {
        gameState.resumeTimer(_onTimerTick, _onTimeUp);
      },
      onExit: _confirmExit,
    ).then((_) {
      if (gameState.isPaused) {
        gameState.resumeTimer(_onTimerTick, _onTimeUp);
      }
    });
  }

  void _confirmExit() {
    gameState.pauseTimer();
    GameDialogs.showExitConfirmDialog(
      context,
      onConfirm: () {
        audioManager.stopTimerSound();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      onCancel: () {
        gameState.resumeTimer(_onTimerTick, _onTimeUp);
      },
    ).then((_) {
      if (gameState.isPaused) {
        gameState.resumeTimer(_onTimerTick, _onTimeUp);
      }
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.yellow, Colors.orange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: const Text(
          'PasGeç',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 35,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.pause),
          onPressed: _pauseGame,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (words.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ScoreCardWidget(
                          teamName: widget.team1Name,
                          score: gameState.team1Score,
                        ),
                      ),
                      Expanded(
                        child: ScoreCardWidget(
                          teamName: widget.team2Name,
                          score: gameState.team2Score,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  TurnIndicatorWidget(
                    currentTeamName: gameState.currentTeam == 1
                        ? widget.team1Name
                        : widget.team2Name,
                    currentPlayerName: gameState.getCurrentPlayer(),
                  ),
                  const SizedBox(height: 0),
                  TimerWidget(timerValue: gameState.timerValue),
                  const SizedBox(height: 1),
                  GameWordCard(word: words[gameState.currentWordIndex]),
                ],
              ),
            ),
          ),
        ),
        _buildFooterButtons(),
      ],
    );
  }

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GameButtonWidget(
              label: 'Pas',
              icon: Icons.skip_next,
              color: gameState.isPassButtonDisabled ? Colors.grey : Colors.blue,
              onPressed: gameState.isPassButtonDisabled ? () {} : _handlePass,
            ),
          ),
          Expanded(
            child: GameButtonWidget(
              label: 'Tabu',
              icon: Icons.cancel,
              color: Colors.red,
              onPressed: _handleTaboo,
            ),
          ),
          Expanded(
            child: GameButtonWidget(
              label: 'Doğru',
              icon: Icons.check_circle,
              color: Colors.green,
              onPressed: _handleCorrect,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    gameState.dispose();
    audioManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await GameDialogs.showExitConfirmationDialog(context);
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          top: true,
          bottom: true,
          child: Stack(
            children: [
              _buildBody(),
              // Offline göstergesi
              if (!_isOnline)
                Positioned(
                  top: 80,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
