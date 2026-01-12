import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class JokerManagementScreen extends StatefulWidget {
  const JokerManagementScreen({super.key});

  @override
  JokerManagementScreenState createState() => JokerManagementScreenState();
}

class JokerManagementScreenState extends State<JokerManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jokerController = TextEditingController();
  List<Map<String, dynamic>> _jokers = [];
  List<Map<String, dynamic>> _filteredJokers = [];
  bool _isLoading = true;
  bool _isSelectionMode =
      false; // Seçim modunun aktif olup olmadığını kontrol eder
  final List<int> _selectedJokerIds = []; // Seçilen jokerlerin ID'lerini tutar
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _fetchJokers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchJokers() async {
    setState(() {
      _isLoading = true;
    });

    // Sadece is_active = 1 olan jokerleri getir
    final jokers = await _dbHelper.getActiveJokers();
    setState(() {
      _jokers = jokers;
      _filteredJokers = jokers;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredJokers = query.isEmpty
          ? _jokers
          : _jokers
              .where((joker) =>
                  joker['message'].toString().toLowerCase().contains(query))
              .toList();
    });
  }

  Future<void> _addJoker() async {
    if (_jokerController.text.isNotEmpty) {
      final jokerMessage = _jokerController.text.trim();
      await _dbHelper.addJoker(jokerMessage);
      _jokerController.clear();
      await _fetchJokers();
      if (mounted) {
        _showSnackBar('Joker başarıyla eklendi!');
      }

      // Firebase Analytics olayı
      await _analytics.logEvent(
        name: 'joker_added',
        parameters: {
          'message': jokerMessage,
        },
      );
    } else {
      _showErrorDialog('Lütfen joker mesajını giriniz!');
    }
  }

  Future<void> _updateJoker(int id, String newMessage) async {
    if (newMessage.isNotEmpty) {
      await _dbHelper.updateJoker(id, newMessage.trim());
      await _fetchJokers();
      if (mounted) {
        _showSnackBar('Joker başarıyla güncellendi!');
      }

      // Firebase Analytics olayı
      await _analytics.logEvent(
        name: 'joker_updated',
        parameters: {
          'joker_id': id,
          'new_message': newMessage.trim(),
        },
      );
    } else {
      _showErrorDialog('Joker mesajı boş olamaz!');
    }
  }

  Future<void> _deleteJoker(int id) async {
    final confirm = await _showConfirmationDialog(
        'Bu jokeri silmek istediğinize emin misiniz?');
    if (confirm) {
      await _dbHelper.deleteJoker(id);
      await _fetchJokers();
      if (mounted) {
        _showSnackBar('Joker başarıyla silindi!');
      }

      // Firebase Analytics olayı
      await _analytics.logEvent(
        name: 'joker_deleted',
        parameters: {
          'joker_id': id,
        },
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2), // Daha kısa görünüm süresi
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Onay'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hayır'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Evet'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showEditJokerDialog(int id, String currentMessage) async {
    final TextEditingController editController =
        TextEditingController(text: currentMessage);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Jokeri Düzenle'),
          content: TextField(
            controller: editController,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              labelText: 'Joker Mesajı',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateJoker(id, editController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedJokers() async {
    if (_selectedJokerIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme'),
        content:
            const Text('Seçilen jokerleri silmek istediğinize emin misiniz?'),
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

    if (confirm != true) return;

    try {
      for (int id in _selectedJokerIds) {
        await _dbHelper.updateJokerStatus(id, 0); // is_active = 0 yap
      }

      await _fetchJokers(); // Jokerleri yeniden yükle

      if (!mounted) return;
      setState(() {
        _isSelectionMode = false;
        _selectedJokerIds.clear(); // Seçim listesini temizle
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seçilen jokerler başarıyla silindi!')),
      );

      // Firebase Analytics olayı
      await _analytics.logEvent(
        name: 'jokers_bulk_deleted',
        parameters: {
          'joker_ids': _selectedJokerIds.join(', '),
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? "${_selectedJokerIds.length} Seçildi"
              : 'Jokerleri Yönet',
          style: const TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.deepPurple,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _selectedJokerIds.isEmpty
                      ? null
                      : () async {
                          await _deleteSelectedJokers();
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedJokerIds.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: _showAddJokerDialog,
                ),
              ],
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: true,
        bottom: true,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple,
                Colors.purpleAccent,
                Colors.blueAccent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Joker Ara...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Toplam Joker Sayısı: ${_filteredJokers.length}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(child: _buildJokerList()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildJokerList() {
    if (_filteredJokers.isEmpty) {
      return Center(
        child: Text(
          'Hiç joker bulunamadı.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredJokers.length,
      itemBuilder: (context, index) {
        final joker = _filteredJokers[index];
        final isSelected =
            _selectedJokerIds.contains(joker['id']); // Joker seçili mi?

        return Card(
          margin: const EdgeInsets.all(8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          color: isSelected
              ? Colors.deepPurple
                  .withValues(alpha: 0.2) // Seçili olan jokerin arka planı
              : Colors.white.withValues(alpha: 0.9),
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedJokerIds.add(joker['id']);
                        } else {
                          _selectedJokerIds.remove(joker['id']);
                        }
                      });
                    },
                  )
                : null,
            title: Text(
              joker['message'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: !_isSelectionMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () =>
                            _showEditJokerDialog(joker['id'], joker['message']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteJoker(joker['id']),
                      ),
                    ],
                  )
                : null,
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedJokerIds.remove(joker['id']);
                  } else {
                    _selectedJokerIds.add(joker['id']);
                  }
                });
              }
            },
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _selectedJokerIds.add(joker['id']);
              });
            },
          ),
        );
      },
    );
  }

  void _showAddJokerDialog() {
    _jokerController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Joker Ekle'),
          content: TextField(
            controller: _jokerController,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              labelText: 'Joker Mesajı',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                _addJoker();
                Navigator.of(context).pop();
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
}
