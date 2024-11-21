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

    // 1. Takım oyuncularını listeye aktar
    List<String> team1Players = _team1PlayersControllers
        .map((controller) => controller.text.trim())
        .where((player) => player.isNotEmpty)
        .toList();

    // 2. Takım oyuncularını listeye aktar
    List<String> team2Players = _team2PlayersControllers
        .map((controller) => controller.text.trim())
        .where((player) => player.isNotEmpty)
        .toList();

    // Takım ve oyuncu kontrolü
    if (team1Name.isNotEmpty &&
        team2Name.isNotEmpty &&
        team1Players.isNotEmpty &&
        team2Players.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            team1Name: team1Name,
            team2Name: team2Name,
            team1Players: team1Players,
            team2Players: team2Players,
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
      showAlertDialog('Lütfen takım adlarını ve her iki takım için en az bir oyuncu girin!');
    }
  }

  void showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Eksik Bilgi',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tamam',
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takım Seçimi'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                _buildTeamCard('1. Takım Bilgileri', _team1Controller, _team1PlayersControllers),
                const SizedBox(height: 20),
                _buildTeamCard('2. Takım Bilgileri', _team2Controller, _team2PlayersControllers),
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
