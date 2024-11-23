import 'package:flutter/material.dart';
import 'package:tabu_oyunu/models/player_performance.dart';
import 'package:tabu_oyunu/database_helper.dart';

class WinnerScreen extends StatefulWidget {
  final String winningTeam;
  final String team1Name;
  final String team2Name;
  final List<PlayerPerformance> team1Performances;
  final List<PlayerPerformance> team2Performances;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const WinnerScreen({
    super.key,
    required this.winningTeam,
    required this.team1Name,
    required this.team2Name,
    required this.team1Performances,
    required this.team2Performances,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  State<WinnerScreen> createState() => _WinnerScreenState();
}

class _WinnerScreenState extends State<WinnerScreen> {
  bool _isSaved = false; // Kaydın yalnızca bir kez yapılmasını sağlamak için flag

  @override
  void initState() {
    super.initState();
    _saveGameData(); // Ekran açıldığında otomatik olarak kaydediliyor
  }

  Future<void> _saveGameData() async {
    if (_isSaved) return; // Daha önce kaydedildiyse tekrar kaydetmesin
    final dbHelper = DatabaseHelper();

    try {
      // Oyun kayıtlarını kaydet
      int gameId = await dbHelper.addGameRecord(
        widget.team1Name,
        widget.team2Name,
        widget.team1Performances.fold(0, (sum, player) => sum + player.correctCount),
        widget.team2Performances.fold(0, (sum, player) => sum + player.correctCount),
      );

      // Oyuncu performanslarını kaydet
      for (var player in widget.team1Performances) {
        await dbHelper.addPlayerPerformance(
          gameId,
          widget.team1Name,
          player.playerName,
          player.correctCount,
          player.tabooCount,
          player.passCount,
        );
      }

      for (var player in widget.team2Performances) {
        await dbHelper.addPlayerPerformance(
          gameId,
          widget.team2Name,
          player.playerName,
          player.correctCount,
          player.tabooCount,
          player.passCount,
        );
      }

      // Başarı mesajı
      await _showSaveGameResult("Oyun bilgileri başarıyla kaydedildi!");
      setState(() {
        _isSaved = true; // Kaydın tamamlandığını işaretle
      });
    } catch (e) {
      // Hata mesajı
      await _showSaveGameResult("Veritabanına kaydedilirken hata oluştu: $e", isSuccess: false);
    }
  }

  Future<void> _showSaveGameResult(String message, {bool isSuccess = true}) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isSuccess ? "Başarılı" : "Hata",
            style: TextStyle(
              color: isSuccess ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tamam"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Kazanan Takım"),
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
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${widget.winningTeam} Kazandı!",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildPerformanceCard(widget.team1Name, widget.team1Performances),
                const SizedBox(height: 20),
                _buildPerformanceCard(widget.team2Name, widget.team2Performances),
                const SizedBox(height: 30),
                _buildButton("Yeniden Oyna", Colors.green, widget.onPlayAgain),
                const SizedBox(height: 15),
                _buildButton("Ana Menü", Colors.red, widget.onMainMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(String teamName, List<PlayerPerformance> performances) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...performances.map((performance) { // `toList` kaldırıldı
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          performance.playerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(),
                            Text(
                              "Doğru: ${performance.correctCount}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Tabu: ${performance.tabooCount}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Pas: ${performance.passCount}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }


  Widget _buildButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 6,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
