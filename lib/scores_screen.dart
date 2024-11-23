import 'package:flutter/material.dart';
import 'package:tabu_oyunu/database_helper.dart';
import 'player_performance_screen.dart'; // Performans detayları için

class ScoresScreen extends StatefulWidget {
  const ScoresScreen({super.key});

  @override
  ScoresScreenState createState() => ScoresScreenState();
}

class ScoresScreenState extends State<ScoresScreen> {
  List<Map<String, dynamic>> scores = [];

  @override
  void initState() {
    super.initState();
    fetchScores();
  }

  Future<void> fetchScores() async {
    final db = DatabaseHelper();
    final data = await db.getGameRecords(); // Veritabanından oyun kayıtlarını getir
    setState(() {
      scores = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // AppBar'ın içerikten bağımsız görünmesini sağlar
      appBar: AppBar(
        title: const Text(
          'Skorlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Şeffaf AppBar
        foregroundColor: Colors.white,
        elevation: 0, // Ayrım çizgisini kaldırır
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: scores.isEmpty
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : ListView.builder(
          padding: const EdgeInsets.only(
            top: kToolbarHeight + 16.0, // AppBar'ı dikkate alarak padding ekledik
            left: 16.0,
            right: 16.0,
          ),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  '${score['team1_name']} vs ${score['team2_name']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                    'Skor: ${score['team1_score']} - ${score['team2_score']}'),
                trailing:
                const Icon(Icons.arrow_forward, color: Colors.blueAccent),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerPerformanceScreen(
                        gameId: score['id'],
                        team1Name: score['team1_name'],
                        team2Name: score['team2_name'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
