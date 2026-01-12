import 'package:flutter/material.dart';

class NextTeamScreen extends StatelessWidget {
  final String currentTeam;
  final String nextTeam;
  final String currentPlayer;
  final String nextPlayer;

  // Tur istatistikleri (mevcut turun)
  final int correctCount;
  final int tabooCount;
  final int passCount;

  // Yeni: Takımların toplam skorları (o ana kadar)
  final int currentTeamScore;
  final int nextTeamScore;

  const NextTeamScreen({
    super.key,
    required this.currentTeam,
    required this.nextTeam,
    required this.currentPlayer,
    required this.nextPlayer,
    required this.correctCount,
    required this.tabooCount,
    required this.passCount,
    required this.currentTeamScore,
    required this.nextTeamScore,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Sıradaki Takım'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 10),
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent, Colors.white],
                  radius: 2,
                  center: Alignment(-0.8, -0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScoreboardCard(), // <-- Yeni: Güncel skorlar
                    const SizedBox(height: 14),
                    _buildInfoCard(),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('Devam Et'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yeni: Güncel skor kartı
  Widget _buildScoreboardCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      shadowColor: Colors.black45,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white.withOpacity(0.9),
        ),
        child: Column(
          children: [
            Text(
              'Güncel Skorlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildScoreBox(
                    title: currentTeam,
                    score: currentTeamScore,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScoreBox(
                    title: nextTeam,
                    score: nextTeamScore,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBox({
    required String title,
    required int score,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Mevcut: Bilgi kartı
  Widget _buildInfoCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      shadowColor: Colors.black45,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.white.withOpacity(0.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTeamInfo(
              title: 'Mevcut Takım ve Oyuncu',
              team: currentTeam,
              player: currentPlayer,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildTeamInfo(
              title: 'Sıradaki Takım ve Oyuncu',
              team: nextTeam,
              player: nextPlayer,
              color: Colors.blueAccent,
            ),
            const Divider(
              color: Colors.teal,
              thickness: 1.5,
              height: 30,
            ),
            _buildInfoRow('Doğru Sayısı', correctCount.toString()),
            const SizedBox(height: 8),
            _buildInfoRow('Tabu Sayısı', tabooCount.toString()),
            const SizedBox(height: 8),
            _buildInfoRow('Pas Sayısı', passCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo({
    required String title,
    required String team,
    required String player,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.7),
          ),
        ),
        Text(
          '$team - $player',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
      ],
    );
  }
}
