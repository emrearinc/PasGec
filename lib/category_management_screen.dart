import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'database_helper.dart';
import 'dart:developer';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Map<String, dynamic>> _categoryData = []; // {kategori, sayı}
  bool _isLoading = true;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final counts = await DatabaseHelper().getCategoryCounts();

      List<Map<String, dynamic>> data = counts.entries
          .map((e) => {'category': e.key, 'count': e.value})
          .toList();

      // Sayıya göre azalan sırada sırala
      data.sort((a, b) => b['count'].compareTo(a['count']));

      setState(() {
        _categoryData = data;
        _isLoading = false;
      });
    } catch (e) {
      log("Kategoriler yüklenirken hata: $e");
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Yönetimi'),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categoryData.isEmpty
                ? const Center(
                    child: Text(
                      'Kategori bulunamadı',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _categoryData.length,
                    itemBuilder: (context, index) {
                      final categoryName = _categoryData[index]['category'];
                      final wordCount = _categoryData[index]['count'];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '$wordCount kelime',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.list, color: Colors.blue),
                                tooltip: 'Kelimeleri Göster',
                                onPressed: () =>
                                    _showWordsInCategory(categoryName),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange),
                                tooltip: 'Kategori İsmi Değiştir',
                                onPressed: () =>
                                    _showRenameCategoryDialog(categoryName),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _showWordsInCategory(String categoryName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '$categoryName Kategorisinin Kelimeleri',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getWordsInCategory(categoryName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Hata: ${snapshot.error}');
              }

              final words = snapshot.data ?? [];

              if (words.isEmpty) {
                return const Text('Bu kategoride kelime yok');
              }

              return SizedBox(
                height: 300,
                width: 400,
                child: ListView.builder(
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        words[index]['word'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Yasaklı: ${words[index]['forbidden_words'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getWordsInCategory(
      String categoryName) async {
    try {
      return await DatabaseHelper().getWordsInCategory(categoryName);
    } catch (e) {
      log("Kategorideki kelimeler alınırken hata: $e");
      rethrow;
    }
  }

  void _showRenameCategoryDialog(String oldCategoryName) {
    final TextEditingController controller =
        TextEditingController(text: oldCategoryName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Kategori İsmini Değiştir'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Yeni Kategori İsmi',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != oldCategoryName) {
                  _renameCategory(oldCategoryName, newName);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameCategory(String oldName, String newName) async {
    try {
      await DatabaseHelper().updateCategoryName(oldName, newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$oldName → $newName olarak değiştirildi'),
          ),
        );
      }

      // Firebase Analytics
      await _analytics.logEvent(
        name: 'category_renamed',
        parameters: {
          'old_name': oldName,
          'new_name': newName,
        },
      );

      _loadCategories();
    } catch (e) {
      log("Kategori ismi değiştirilirken hata: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
