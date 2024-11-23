import 'dart:math';
import 'database_helper.dart';

class Joker {
  /// Veritabanından rastgele joker mesajı döndürür.
  static Future<String?> getRandomJoker({double probability = 0.3}) async {
    final random = Random();
    if (random.nextDouble() < probability) {
      final dbHelper = DatabaseHelper();
      final jokers = await dbHelper.getJokers();

      if (jokers.isNotEmpty) {
        int index = random.nextInt(jokers.length);
        return jokers[index]['message'];
      }
    }
    return null; // Joker gösterilmez
  }
}
