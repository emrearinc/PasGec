import 'dart:math';
import 'database_helper.dart';

class Joker {
  /// Veritabanından rastgele aktif joker mesajı döndürür.
  static Future<String?> getRandomJoker() async {
    final dbHelper = DatabaseHelper();

    // Sadece aktif jokerleri getir
    final activeJokers = await dbHelper.getActiveJokers();

    if (activeJokers.isNotEmpty) {
      int index = Random().nextInt(activeJokers.length);
      return activeJokers[index]['message'];
    }
    return null; // Joker gösterilmez
  }

}
