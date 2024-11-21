class PlayerPerformance {
  final String playerName;
  int correctCount;
  int tabooCount;
  int passCount;

  PlayerPerformance({
    required this.playerName,
    this.correctCount = 0,
    this.tabooCount = 0,
    this.passCount = 0,
  });

  @override
  String toString() {
    return 'Player: $playerName, Correct: $correctCount, Taboo: $tabooCount, Pass: $passCount';
  }
}
