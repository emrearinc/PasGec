import 'package:flutter/material.dart';
import 'team_selection_screen.dart';
import 'settings_screen.dart';
import 'words_screen.dart'; // WordsScreen'i ekliyoruz

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _gameScore = 25;
  int _gameTime = 60;
  int _passLimit = 3;
  int _tabooPenalty = 1; // Varsayılan tabu cezası
  bool _showJokers = true; // Varsayılan joker gösterimi
  double _jokerProbability = 0.3; // Varsayılan joker gösterim ihtimali

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset(
                'assets/images/logo.png',
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              _buildHomeButton(
                label: 'Oyuna Başla',
                icon: Icons.play_arrow,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamSelectionScreen(
                        gameScore: _gameScore,
                        gameTime: _gameTime,
                        passLimit: _passLimit,
                        tabooPenalty: _tabooPenalty, // Tabu cezasını ekledik
                        showJokers: _showJokers,
                        jokerProbability: _jokerProbability,

                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildHomeButton(
                label: 'Ayarlar',
                icon: Icons.settings,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );

                  if (result != null) {
                    setState(() {
                      _gameScore = result['gameScore'];
                      _gameTime = result['gameTime'];
                      _passLimit = result['passLimit'];
                      _tabooPenalty = result['tabooPenalty']; // Tabu cezasını aldık
                      _showJokers = result['showJokers'];
                      _jokerProbability = result['jokerProbability'];

                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildHomeButton(
                label: 'Kelimeleri Yönet',
                icon: Icons.list,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WordsScreen()),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 30,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        shadowColor: Colors.black54,
        textStyle: const TextStyle(
          fontSize: 18,
        ),
      ),
    );
  }
}
