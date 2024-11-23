import 'package:flutter/material.dart';
import 'dart:developer';
import 'database_helper.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key}); // Modern key kullanımı

  @override
  State<WordsScreen> createState() => _WordsScreenState(); // Doğru konumlandırma
}

class _WordsScreenState extends State<WordsScreen> {
  List<Map<String, dynamic>> _words = [];
  List<Map<String, dynamic>> _filteredWords = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWords();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWords() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final words = await DatabaseHelper().getWords();

      if (!mounted) return; // Widget kaldırılmışsa işlemi durdur

      setState(() {
        _words = words;
        _filteredWords = words;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Widget kaldırılmışsa işlemi durdur

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelimeler alınırken hata oluştu: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onSearchChanged() async {
    try {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() {
          _filteredWords = _words;
        });
      } else {
        final results = await DatabaseHelper().searchWords(query);

        if (!mounted) return; // Widget kaldırılmışsa işlemi durdur

        setState(() {
          _filteredWords = results;
        });
      }
    } catch (e) {
      if (!mounted) return; // Widget kaldırılmışsa işlemi durdur

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
        title: const Text('Kelimeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWordDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Kelime Ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildWordList(),
    );
  }

  Widget _buildWordList() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Toplam Kelime Sayısı: ${_filteredWords.length}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredWords.length,
              itemBuilder: (context, index) {
                final word = _filteredWords[index];
                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Text(
                      "${index + 1}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    title: Text(
                      word['word'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                        "Yasaklı Kelimeler: ${word['forbidden_words']}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteWord(word['id']),
                    ),
                    onTap: () => _showEditWordDialog(
                      word['id'],
                      word['word'],
                      word['forbidden_words']?.split(', ') ?? [],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWordDialog() {
    final TextEditingController wordController = TextEditingController();
    final List<TextEditingController> forbiddenControllers =
    List.generate(5, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  _addWord(word, forbiddenWords);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
  void _showEditWordDialog(int id, String initialWord, List<String> initialForbiddenWords) {
    final TextEditingController wordController = TextEditingController(text: initialWord);
    final List<TextEditingController> forbiddenControllers = List.generate(
      5,
          (i) => TextEditingController(
          text: i < initialForbiddenWords.length ? initialForbiddenWords[i] : ''),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
              child: const Text('Güncelle', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _updateWord(int id, String word, List<String> forbiddenWords) async {
    try {
      await DatabaseHelper().updateWord(id, word, forbiddenWords);
      if (!mounted) return; // Eğer widget kaldırılmışsa işlem iptal edilir
      _fetchWords();
      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelime başarıyla güncellendi!')),
      );
    } catch (e) {
      if (!mounted) return; // Eğer widget kaldırılmışsa işlem iptal edilir
      // Hata mesajını göstermek
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

  void _addWord(String word, List<String> forbiddenWords) async {
    try {
      await DatabaseHelper().addWord(word, forbiddenWords);
      if (!mounted) return; // Widget kaldırılmışsa işlemi durdur

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
        if (!mounted) return; // Widget kaldırılmışsa işlemi durdur

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
