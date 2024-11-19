import 'package:flutter/material.dart';
import 'game_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  final int gameScore;
  final int gameTime;
  final int passLimit;
  final int tabooPenalty; // Yeni eklenen parametre

  const TeamSelectionScreen({super.key,
    required this.gameScore,
    required this.gameTime,
    required this.passLimit,
    required this.tabooPenalty, // Parametre olarak ekledik

  });

  @override
  _TeamSelectionScreenState createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final List<TextEditingController> _team1PlayersControllers = List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _team2PlayersControllers = List.generate(4, (_) => TextEditingController());

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    for (var controller in _team1PlayersControllers) {
      controller.dispose();
    }
    for (var controller in _team2PlayersControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void startGame() {
    String team1Name = _team1Controller.text;
    String team2Name = _team2Controller.text;
    String team1Player1 = _team1PlayersControllers[0].text;
    String team2Player1 = _team2PlayersControllers[0].text;

    if (team1Name.isNotEmpty && team2Name.isNotEmpty && team1Player1.isNotEmpty && team2Player1.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            team1Name: team1Name,
            team2Name: team2Name,
            gameTime: widget.gameTime,
            gameScore: widget.gameScore,
            passLimit: widget.passLimit,
            tabooPenalty: widget.tabooPenalty, // Doğru parametre geçişi

          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen takım adlarını ve her iki takımın ilk oyuncusunu girin!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    'Takım Seçimi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildTeamNameInput('1. Takım Adı', _team1Controller),
                ..._buildPlayerInputs('1. Takım - ', _team1PlayersControllers),
                const SizedBox(height: 30),
                _buildTeamNameInput('2. Takım Adı', _team2Controller),
                ..._buildPlayerInputs('2. Takım - ', _team2PlayersControllers),
                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: startGame,
                    icon: const Icon(Icons.play_arrow, size: 30),
                    label: const Text(
                      'Oyunu Başlat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamNameInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          filled: true,
          fillColor: Colors.deepPurple.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.white70, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          floatingLabelStyle: const TextStyle(fontSize: 14, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlayerInputs(String labelPrefix, List<TextEditingController> controllers) {
    return controllers
        .asMap()
        .entries
        .map((entry) => _buildPlayerInput('$labelPrefix${entry.key + 1}. Oyuncu', entry.value))
        .toList();
  }
}
