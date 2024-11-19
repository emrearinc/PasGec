import 'package:flutter/material.dart';
import 'game_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  final int gameScore;
  final int gameTime;
  final int passLimit;
  final int tabooPenalty;
  final bool showJokers;
  final double jokerProbability;

  const TeamSelectionScreen({
    super.key,
    required this.gameScore,
    required this.gameTime,
    required this.passLimit,
    required this.tabooPenalty,
    required this.showJokers,
    required this.jokerProbability,
  });

  @override
  _TeamSelectionScreenState createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final List<TextEditingController> _team1PlayersControllers =
  List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _team2PlayersControllers =
  List.generate(4, (_) => TextEditingController());

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
    String team1Name = _team1Controller.text.trim();
    String team2Name = _team2Controller.text.trim();
    String team1Player1 = _team1PlayersControllers[0].text.trim();
    String team2Player1 = _team2PlayersControllers[0].text.trim();

    if (team1Name.isNotEmpty &&
        team2Name.isNotEmpty &&
        team1Player1.isNotEmpty &&
        team2Player1.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            team1Name: team1Name,
            team2Name: team2Name,
            gameTime: widget.gameTime,
            gameScore: widget.gameScore,
            passLimit: widget.passLimit,
            tabooPenalty: widget.tabooPenalty,
            showJokers: widget.showJokers,
            jokerProbability: widget.jokerProbability,
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
      appBar: AppBar(
        title: const Text('Takım Seçimi'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.pinkAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Takım ve Oyuncu Bilgileri',
                    style: TextStyle(
                      fontSize: 24,
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
                const SizedBox(height: 20),
                _buildTeamCard('1. Takım', _team1Controller, _team1PlayersControllers),
                const SizedBox(height: 20),
                _buildTeamCard('2. Takım', _team2Controller, _team2PlayersControllers),
                const SizedBox(height: 30),
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
                      elevation: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(
      String title, TextEditingController teamController, List<TextEditingController> playerControllers) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.black38,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            _buildTeamNameInput('Takım Adı', teamController),
            const SizedBox(height: 10),
            ..._buildPlayerInputs('Oyuncu ', playerControllers),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamNameInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.deepPurple,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.deepPurple.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildPlayerInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.deepPurple),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.deepPurple.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlayerInputs(String labelPrefix, List<TextEditingController> controllers) {
    return controllers
        .asMap()
        .entries
        .map((entry) => _buildPlayerInput('$labelPrefix ${entry.key + 1}', entry.value))
        .toList();
  }
}
