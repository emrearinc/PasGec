import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Versiyon bilgisi için
import 'team_selection_screen.dart';
import 'settings_screen.dart';
import 'words_screen.dart';
import 'how_to_play_screen.dart';
import 'scores_screen.dart';
import 'joker_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _gameScore = 25;
  int _gameTime = 60;
  int _passLimit = 3;
  int _tabooPenalty = 1;
  bool _showJokers = true;
  double _jokerProbability = 0.3;

  String _appVersion = ''; // Versiyon bilgisi

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
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

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4A148C), // Daha koyu mor
                    Color(0xFFCE93D8), // Açık mor
                    Color(0xFFBA68C8), // Orta mor tonu
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return _buildHomeCard(
                            label: _getCardLabel(index),
                            icon: _getCardIcon(index),
                            color: _getCardColor(index),
                            onPressed: () {
                              _navigateToScreen(index);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _appVersion, // Versiyon bilgisi
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCardLabel(int index) {
    switch (index) {
      case 0:
        return 'Oyuna Başla';
      case 1:
        return 'Ayarlar';
      case 2:
        return 'Kelimeleri Yönet';
      case 3:
        return 'Nasıl Oynanır';
      case 4:
        return 'Skorlar';
      case 5:
        return 'Jokerleri Yönet';
      default:
        return '';
    }
  }

  IconData _getCardIcon(int index) {
    switch (index) {
      case 0:
        return Icons.play_arrow;
      case 1:
        return Icons.settings;
      case 2:
        return Icons.list;
      case 3:
        return Icons.info_outline;
      case 4:
        return Icons.score;
      case 5:
        return Icons.extension;
      default:
        return Icons.help;
    }
  }

  Color _getCardColor(int index) {
    switch (index) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.pink;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
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
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WordsScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HowToPlayScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ScoresScreen()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JokerManagementScreen()),
        );
        break;
    }
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
