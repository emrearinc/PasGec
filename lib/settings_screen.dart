// File: lib/settings_screen.dart
// Screen: Settings
// Purpose: Kategori seçimi + kategori başına kelime sayısı + SharedPreferences'a kaydetme.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'database_helper.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  int _gameScore = 25;
  int _gameTime = 60;
  int _passLimit = 3;
  int _tabooPenalty = 1;
  bool _showJokers = true;
  double _jokerProbability = 0.3;

  // Kategori
  bool _mixMode = true; // "Genel Karışık"
  List<String> _allCategories = [];
  Map<String, int> _categoryCounts = {};
  final Set<String> _selectedCategories = {};

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // DB’den kategori listesi
    final allCats = await DatabaseHelper().getCategories();
    final counts = await DatabaseHelper().getCategoryCounts();

    final savedSelected = prefs.getStringList('selectedCategories') ?? [];
    // boş liste => karışık
    final mix = savedSelected.isEmpty;

    setState(() {
      _gameScore = prefs.getInt('gameScore') ?? _gameScore;
      _gameTime = prefs.getInt('gameTime') ?? _gameTime;
      _passLimit = prefs.getInt('passLimit') ?? _passLimit;
      _tabooPenalty = prefs.getInt('tabooPenalty') ?? _tabooPenalty;
      _showJokers = prefs.getBool('showJokers') ?? _showJokers;
      _jokerProbability =
          prefs.getDouble('jokerProbability') ?? _jokerProbability;

      _allCategories = allCats;
      _categoryCounts = counts;

      _mixMode = mix;
      _selectedCategories
        ..clear()
        ..addAll(savedSelected);

      _isInitialized = true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Seçim kuralları:
    // - Mix açık => kaydetme boş liste
    // - Hiç seçilmediyse => boş liste
    // - Hepsi seçildiyse => boş liste (mixed)
    List<String> finalSelection = [];
    if (!_mixMode) {
      finalSelection = _selectedCategories.toList();
      if (finalSelection.isEmpty) {
        finalSelection = [];
      } else if (_allCategories.isNotEmpty &&
          finalSelection.length == _allCategories.length) {
        finalSelection = [];
      }
    }

    await prefs.setInt('gameScore', _gameScore);
    await prefs.setInt('gameTime', _gameTime);
    await prefs.setInt('passLimit', _passLimit);
    await prefs.setInt('tabooPenalty', _tabooPenalty);
    await prefs.setBool('showJokers', _showJokers);
    await prefs.setDouble('jokerProbability', _jokerProbability);

    await prefs.setStringList('selectedCategories', finalSelection);
  }

  Future<void> _saveSettingsAndExit() async {
    await _saveSettings();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCats = prefs.getStringList('selectedCategories') ?? [];
      await _analytics.logEvent(
        name: 'settings_saved',
        parameters: {
          'game_score': _gameScore,
          'game_time': _gameTime,
          'pass_limit': _passLimit,
          'taboo_penalty': _tabooPenalty,
          'show_jokers': _showJokers.toString(),
          'joker_probability': _jokerProbability,
          'category_mode': savedCats.isEmpty ? 'mixed' : 'filtered',
          'selected_categories_count': savedCats.length,
        },
      );
    } catch (_) {}

    if (mounted) Navigator.pop(context, true);
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
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveSettingsAndExit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lime,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
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
                      const SizedBox(height: 20),
                      _buildSectionTitle('Kategori Seçimi'),
                      _buildCategoryCard(),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Oyun Skoru'),
                      _buildCustomCard(
                        child: Slider(
                          value: _gameScore.toDouble(),
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: _gameScore.toString(),
                          activeColor: Colors.deepPurple,
                          onChanged: (double value) =>
                              setState(() => _gameScore = value.toInt()),
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
                          onChanged: (double value) =>
                              setState(() => _gameTime = value.toInt()),
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
                          onChanged: (double value) =>
                              setState(() => _passLimit = value.toInt()),
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
                          onChanged: (double value) =>
                              setState(() => _tabooPenalty = value.toInt()),
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
                                const Text('Jokerler Gösterilsin',
                                    style: TextStyle(fontSize: 16)),
                                Switch(
                                  value: _showJokers,
                                  onChanged: (bool value) =>
                                      setState(() => _showJokers = value),
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
                                onChanged: (double value) =>
                                    setState(() => _jokerProbability = value),
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
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildCategoryCard() {
    final totalActive = _categoryCounts.values.fold<int>(0, (a, b) => a + b);

    return _buildCustomCard(
      label: _mixMode
          ? 'Mod: Genel Karışık (Toplam: $totalActive)'
          : 'Seçili: ${_selectedCategories.length} / ${_allCategories.length} (Toplam: $totalActive)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Genel Karışık'),
            subtitle: const Text('Açıksa kategori filtresi uygulanmaz'),
            value: _mixMode,
            onChanged: (v) {
              setState(() {
                _mixMode = v;
                if (v) _selectedCategories.clear();
              });
            },
          ),
          const Divider(),
          if (_allCategories.isEmpty)
            const Text('Henüz kategori bulunamadı (DB boş olabilir).')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCategories.map((cat) {
                final cnt = _categoryCounts[cat] ?? 0;
                final selected = _selectedCategories.contains(cat);

                return FilterChip(
                  label: Text('$cat ($cnt)'),
                  selected: !_mixMode && selected,
                  onSelected: _mixMode
                      ? null
                      : (val) {
                          setState(() {
                            if (val) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Kategori Yönetimi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryManagementScreen(),
                  ),
                ).then((_) {
                  // Kategori yönetim ekranından dönerken verileri yenile
                  _loadSettings();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          if (!_mixMode)
            Text(
              'Not: Hiç seçmezsen veya hepsini seçersen yine karışık gelir.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomCard({required Widget child, required String label}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.deepPurple.withValues(alpha: 0.4),
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
                opacity: 0.85,
                child: Text(label,
                    style:
                        const TextStyle(fontSize: 16, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
