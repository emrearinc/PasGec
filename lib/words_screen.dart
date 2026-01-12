import 'package:flutter/material.dart';
import 'dart:developer';
import 'database_helper.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  List<Map<String, dynamic>> _words = [];
  List<Map<String, dynamic>> _filteredWords = [];
  final List<Map<String, dynamic>> _displayedWords = []; // Lazy loading için
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final List<int> _selectedWordIds = []; // Seçilen kelimelerin ID'lerini tutar
  bool _isSelectionMode = false;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  String _selectedCategory = 'Genel'; // Varsayılan kategori

  // ✅ Lazy Loading Parameters
  static const int _pageSize = 50; // Her sayfada 50 kelime
  int _currentPage = 0;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchWords();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll); // Lazy loading listener
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // ✅ Memory leak fix
    super.dispose();
  }

  // ✅ Lazy loading: Scroll sonuna gelince daha fazla yükle
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreWords();
      }
    }
  }

  void _loadMoreWords() {
    setState(() {
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _filteredWords.length);

      if (startIndex < _filteredWords.length) {
        _displayedWords.addAll(_filteredWords.sublist(startIndex, endIndex));
        _currentPage++;
        _hasMoreData = endIndex < _filteredWords.length;
      }
    });
  }

  Future<void> _fetchWords() async {
    log("Kelimeler yükleniyor...");
    try {
      setState(() {
        _isLoading = true;
      });

      final List<Map<String, dynamic>> words = await DatabaseHelper()
          .getWords(where: 'is_active = ?', whereArgs: [1]);

      log("Kelimeler başarıyla alındı. Kelime sayısı: ${words.length}");

      if (words.isEmpty) {
        log("Veritabanında aktif kelime bulunamadı.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veritabanında aktif kelime bulunamadı!'),
            ),
          );
        }
      }

      setState(() {
        _words = words;
        _filteredWords = words;
        _isLoading = false;
        _currentPage = 0; // ✅ Reset page
        _displayedWords.clear();
        _loadMoreWords(); // ✅ İlk sayfayı yükle
      });
    } catch (e, stackTrace) {
      log("Kelimeler alınırken hata oluştu: $e", stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kelimeler alınırken hata oluştu: $e'),
          ),
        );
      }
    }
  }

  void _onSearchChanged() async {
    try {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {
          _filteredWords = _words;
          _currentPage = 0; // ✅ Reset page
          _displayedWords.clear();
          _loadMoreWords();
          _hasMoreData = true;
        });
      } else {
        final results = await DatabaseHelper().searchWords(query);

        if (!mounted) return;

        setState(() {
          _filteredWords = results;
          _currentPage = 0; // ✅ Reset page
          _displayedWords.clear();
          _loadMoreWords();
          _hasMoreData = _filteredWords.length > _pageSize;
        });
      }
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Hata"),
            content: Text("Arama yapılırken hata oluştu: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Tamam"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? "${_selectedWordIds.length} Seçildi" : 'Kelimeler',
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedWordIds.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _selectedWordIds.isEmpty
                      ? null
                      : () async {
                          await _deleteSelectedWords();
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedWordIds.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showAddWordDialog,
                ),
              ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Kelime Ara...',
                  prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildWordList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Toplam Kelime Sayısı: ${_filteredWords.length} (Gösterilen: ${_displayedWords.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _displayedWords.length + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the end
                if (index == _displayedWords.length && _hasMoreData) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.deepPurple.shade300,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final word = _displayedWords[index];
                final isSelected = _selectedWordIds
                    .contains(word['id']); // Seçili olup olmadığını kontrol et
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedWordIds.add(word['id']);
                                } else {
                                  _selectedWordIds.remove(word['id']);
                                }
                              });
                            },
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    title: Text(
                      word['word'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Yasaklı Kelimeler: ${word['forbidden_words']}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Kategori: ${word['category'] ?? 'Genel'}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: _isSelectionMode
                        ? null // Seçim modunda silme butonunu gösterme
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteWord(word['id']),
                          ),
                    onTap: () {
                      if (_isSelectionMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedWordIds.remove(word['id']);
                          } else {
                            _selectedWordIds.add(word['id']);
                          }
                        });
                      } else {
                        _showEditWordDialog(
                          word['id'],
                          word['word'],
                          word['forbidden_words']?.split(', ') ?? [],
                        );
                      }
                    },
                    onLongPress: () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedWordIds.add(
                            word['id']); // Uzun basılan kelimeyi seçili yap
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedWords() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content:
            const Text('Seçilen kelimeleri silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    // Eğer işlem onaylanmadıysa çık
    if (confirm != true) return;

    try {
      // Seçilen kelimeleri sil
      for (int id in _selectedWordIds) {
        await DatabaseHelper().updateWordIsActive(id, 0); // is_active = 0 yap
      }

      // Kelimeleri yeniden yükle
      await _fetchWords();

      if (!mounted) return;
      setState(() {
        _isSelectionMode = false;
        _selectedWordIds.clear(); // Seçim listesini temizle
      });

      // Kullanıcıya başarı mesajı göster
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçilen kelimeler başarıyla silindi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu, tekrar deneyin.')),
      );
    }
  }

  void _showAddWordDialog() {
    final TextEditingController wordController = TextEditingController();
    final List<TextEditingController> forbiddenControllers =
        List.generate(5, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Center(
                child: Text(
                  'Yeni Kelime Ekle',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: wordController,
                      decoration: const InputDecoration(
                        labelText: 'Kelime',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Kategori seçimi
                    FutureBuilder<List<String>>(
                      future: DatabaseHelper().getCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Hata: ${snapshot.error}');
                        }

                        List<String> categories = snapshot.data ?? ['Genel'];
                        if (!categories.contains('Genel')) {
                          categories.insert(0, 'Genel');
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kategori',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue ?? 'Genel';
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Yasaklı Kelimeler',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: forbiddenControllers[i],
                          decoration: InputDecoration(
                            labelText: 'Yasaklı Kelime ${i + 1}',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final word = wordController.text;
                    final forbiddenWords = forbiddenControllers
                        .map((c) => c.text)
                        .where((text) => text.isNotEmpty)
                        .toList();
                    if (word.isNotEmpty && forbiddenWords.isNotEmpty) {
                      _addWord(word, forbiddenWords, _selectedCategory);
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditWordDialog(
      int id, String initialWord, List<String> initialForbiddenWords) {
    final TextEditingController wordController =
        TextEditingController(text: initialWord);
    final List<TextEditingController> forbiddenControllers = List.generate(
      5,
      (i) => TextEditingController(
          text:
              i < initialForbiddenWords.length ? initialForbiddenWords[i] : ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text(
              'Kelimeyi Düzenle',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: wordController,
                  decoration: const InputDecoration(
                    labelText: 'Kelime',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: forbiddenControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Yasaklı Kelime ${i + 1}',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final word = wordController.text;
                final forbiddenWords = forbiddenControllers
                    .map((c) => c.text)
                    .where((text) => text.isNotEmpty)
                    .toList();
                if (word.isNotEmpty && forbiddenWords.isNotEmpty) {
                  _updateWord(id, word, forbiddenWords);
                  Navigator.of(context).pop();
                }
              },
              child:
                  const Text('Güncelle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _updateWord(int id, String word, List<String> forbiddenWords) async {
    try {
      await DatabaseHelper().updateWord(id, word, forbiddenWords);
      if (!mounted) return;

      // Firebase Analytics olayı
      await _analytics.logEvent(
        name: 'word_updated',
        parameters: {
          'word_id': id,
          'word': word,
          'forbidden_words': forbiddenWords.join(', '),
        },
      );

      _fetchWords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelime başarıyla güncellendi!')),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hata'),
            content: Text('Kelime güncellenirken hata oluştu: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    }
  }

  void _addWord(
      String word, List<String> forbiddenWords, String category) async {
    try {
      await DatabaseHelper().addWord(word, forbiddenWords, category: category);
      if (!mounted) return;

      // Firebase Analytics olayı
      await _analytics.logEvent(
        name: 'word_added',
        parameters: {
          'word': word,
          'forbidden_words': forbiddenWords.join(', '),
          'category': category,
        },
      );

      _fetchWords();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelime başarıyla eklendi!')),
      );
    } catch (e) {
      log("Kelime eklenirken hata oluştu: $e");
    }
  }

  void _deleteWord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kelime Sil'),
        content: const Text('Bu kelimeyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper().deleteWord(id);
        if (!mounted) return;

        // Firebase Analytics olayı
        await _analytics.logEvent(
          name: 'word_deleted',
          parameters: {
            'word_id': id,
          },
        );

        _fetchWords();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelime başarıyla silindi!')),
        );
      } catch (e) {
        log("Kelime silinirken hata oluştu: $e");
      }
    }
  }
}
