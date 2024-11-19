import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _gameScore = 25;
  int _gameTime = 60;
  int _passLimit = 3;
  int _tabooPenalty = 1;
  bool _showJokers = true;
  double _jokerProbability = 0.3;

  bool _isInitialized = false; // İlk yükleme kontrolü

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Ayarları yükle
  }

  /// Ayarları SharedPreferences'dan yükleme
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _gameScore = prefs.getInt('gameScore') ?? _gameScore;
      _gameTime = prefs.getInt('gameTime') ?? _gameTime;
      _passLimit = prefs.getInt('passLimit') ?? _passLimit;
      _tabooPenalty = prefs.getInt('tabooPenalty') ?? _tabooPenalty;
      _showJokers = prefs.getBool('showJokers') ?? _showJokers;
      _jokerProbability = prefs.getDouble('jokerProbability') ?? _jokerProbability;
      _isInitialized = true; // İlk yükleme tamamlandı
    });
  }

  /// Ayarları SharedPreferences'a kaydetme
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gameScore', _gameScore);
    await prefs.setInt('gameTime', _gameTime);
    await prefs.setInt('passLimit', _passLimit);
    await prefs.setInt('tabooPenalty', _tabooPenalty);
    await prefs.setBool('showJokers', _showJokers);
    await prefs.setDouble('jokerProbability', _jokerProbability);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Ayarlar'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: _isInitialized
            ? SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Oyun Skoru'),
                _buildCustomCard(
                  child: Slider(
                    value: _gameScore.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: _gameScore.toString(),
                    activeColor: Colors.deepPurple,
                    onChanged: (double value) {
                      setState(() {
                        _gameScore = value.toInt();
                      });
                    },
                  ),
                  label: 'Seçilen Oyun Skoru: $_gameScore',
                ),
                const SizedBox(height: 10),
                _buildSectionTitle('Oyun Zamanı (saniye)'),
                _buildCustomCard(
                  child: Slider(
                    value: _gameTime.toDouble(),
                    min: 10,
                    max: 180,
                    divisions: 17,
                    label: _gameTime.toString(),
                    activeColor: Colors.deepPurple,
                    onChanged: (double value) {
                      setState(() {
                        _gameTime = value.toInt();
                      });
                    },
                  ),
                  label: 'Seçilen Oyun Zamanı: $_gameTime saniye',
                ),
                const SizedBox(height: 10),
                _buildSectionTitle('Pas Hakkı'),
                _buildCustomCard(
                  child: Slider(
                    value: _passLimit.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _passLimit.toString(),
                    activeColor: Colors.deepPurple,
                    onChanged: (double value) {
                      setState(() {
                        _passLimit = value.toInt();
                      });
                    },
                  ),
                  label: 'Seçilen Pas Hakkı: $_passLimit',
                ),
                const SizedBox(height: 10),
                _buildSectionTitle('Tabu Cezası Puanı'),
                _buildCustomCard(
                  child: Slider(
                    value: _tabooPenalty.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _tabooPenalty.toString(),
                    activeColor: Colors.deepPurple,
                    onChanged: (double value) {
                      setState(() {
                        _tabooPenalty = value.toInt();
                      });
                    },
                  ),
                  label: 'Seçilen Tabu Cezası: $_tabooPenalty puan',
                ),
                const SizedBox(height: 10),
                _buildSectionTitle('Joker Ayarları'),
                _buildCustomCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jokerler Gösterilsin', style: TextStyle(fontSize: 16)),
                          Switch(
                            value: _showJokers,
                            onChanged: (bool value) {
                              setState(() {
                                _showJokers = value;
                              });
                            },
                            activeColor: Colors.deepPurple,
                          ),
                        ],
                      ),
                      if (_showJokers) ...[
                        const SizedBox(height: 10),
                        Slider(
                          value: _jokerProbability,
                          min: 0,
                          max: 1,
                          divisions: 10,
                          label: '${(_jokerProbability * 100).toInt()}%',
                          activeColor: Colors.deepPurple,
                          onChanged: (double value) {
                            setState(() {
                              _jokerProbability = value;
                            });
                          },
                        ),
                        Text(
                          'Gösterim İhtimali: ${(_jokerProbability * 100).toInt()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                  label: 'Joker Gösterim Ayarları',
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveSettings(); // Ayarları kaydet
                      Navigator.pop(context, true); // Ana ekrana dön ve başarı bilgisi gönder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text('Ayarları Kaydet ve Çık'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCustomCard({required Widget child, required String label}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      shadowColor: Colors.deepPurple.withOpacity(0.4),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              const SizedBox(height: 10),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 0.8,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
