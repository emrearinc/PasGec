import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'team_selection_screen.dart';
import 'settings_screen.dart';
import 'words_screen.dart';
import 'how_to_play_screen.dart';
import 'scores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _gameScore = 25;
  int _gameTime = 60;
  int _passLimit = 3;
  int _tabooPenalty = 1;
  bool _showJokers = true;
  double _jokerProbability = 0.3;

  @override
  void initState() {
    super.initState();

    // Sistem çubuğunu gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gameScore = prefs.getInt('gameScore') ?? 25;
      _gameTime = prefs.getInt('gameTime') ?? 60;
      _passLimit = prefs.getInt('passLimit') ?? 3;
      _tabooPenalty = prefs.getInt('tabooPenalty') ?? 1;
      _showJokers = prefs.getBool('showJokers') ?? true;
      _jokerProbability = prefs.getDouble('jokerProbability') ?? 0.3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.3,
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildHomeCard(
                      label: 'Oyuna Başla',
                      icon: Icons.play_arrow,
                      color: Colors.green,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamSelectionScreen(
                              gameScore: _gameScore,
                              gameTime: _gameTime,
                              passLimit: _passLimit,
                              tabooPenalty: _tabooPenalty,
                              showJokers: _showJokers,
                              jokerProbability: _jokerProbability,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildHomeCard(
                      label: 'Ayarlar',
                      icon: Icons.settings,
                      color: Colors.blue,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                        if (result != null) {
                          _loadSettings();
                        }
                      },
                    ),
                    _buildHomeCard(
                      label: 'Kelimeleri Yönet',
                      icon: Icons.list,
                      color: Colors.orange,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WordsScreen()),
                        );
                      },
                    ),
                    _buildHomeCard(
                      label: 'Nasıl Oynanır',
                      icon: Icons.info_outline,
                      color: Colors.pink,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HowToPlayScreen()),
                        );
                      },
                    ),
                    _buildHomeCard(
                      label: 'Skorlar',
                      icon: Icons.score,
                      color: Colors.red,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScoresScreen(
                              scores: [
                                {'team': 'Takım 1', 'score': 120},
                                {'team': 'Takım 2', 'score': 85},
                                {'team': 'Takım 3', 'score': 140},
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: color.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: MediaQuery.of(context).size.width * 0.08,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
