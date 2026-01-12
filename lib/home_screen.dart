// File: lib/home_screen.dart
// Screen: Home
// Purpose: Ana ekran + sağ altta versiyon/pack/kelime sayısı. Yazıya dokununca force sync yapar.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'team_selection_screen.dart';
import 'settings_screen.dart';
import 'words_screen.dart';
import 'how_to_play_screen.dart';
import 'scores_screen.dart';
import 'joker_management_screen.dart';
import 'database_helper.dart';
import 'words_pack_updater.dart';

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

  String _appVersion = '';

  int _wordCount = 0;
  int _packVersion = 0;
  bool _dbInfoLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
    _loadDbInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  Future<void> _loadDbInfo() async {
    try {
      final db = DatabaseHelper();
      final count = await db.getWordCount();
      final v = await db.getLocalPackVersion();
      if (!mounted) return;
      setState(() {
        _wordCount = count;
        _packVersion = v;
        _dbInfoLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dbInfoLoading = false;
      });
    }
  }

  Future<void> _forceSyncPack() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kelime paketi kontrol ediliyor...')),
    );

    try {
      await WordsPackUpdater().forceSync();
      await _loadDbInfo();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Tamam. pack:$_packVersion • words:$_wordCount')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final int crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: true,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4A148C),
                    Color(0xFFCE93D8),
                    Color(0xFFBA68C8),
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
                            onPressed: () => _navigateToScreen(index),
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
                child: GestureDetector(
                  onTap: _forceSyncPack,
                  child: Text(
                    _dbInfoLoading
                        ? '$_appVersion • sync...'
                        : '$_appVersion • pack:$_packVersion • words:$_wordCount (dokun)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
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
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()))
            .then((_) => _loadSettings());
        break;

      case 2:
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => const WordsScreen()))
            .then((_) => _loadDbInfo());
        break;

      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HowToPlayScreen()));
        break;

      case 4:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ScoresScreen()));
        break;

      case 5:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const JokerManagementScreen()));
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
              Icon(icon,
                  size: MediaQuery.of(context).size.width * 0.08,
                  color: Colors.white),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
