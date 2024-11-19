import 'dart:math';

class Joker {
  static final List<String> jokerMessages = [
    "Karşı Takımla 1 Oyuncu Değişikliği Yap!",
    "İlk Kelimeyi Sessiz Sinema Şeklinde Anlat!",
    "Nesne kullanarak anlat! Ama sessiz ol!",
    "2 Kelimeyi Çizerek Anlat!",
    "2 Tane Yasaklı Kelime Kullanabilirsin!",
    "Kendi Takımından 1 Kişi Seç! Bu Tur Bilmeyecek!",
    "Laz Şivesi Yaparak Anlatmanı İstiyorum!",
    "Bu Tur İngilizce Olarak Anlatmaya Çalış!",
    "Bu Kelimede, Anlatırken Her Kelimeden Önce ‘Tabu’ Demek Zorundasın!",
    "Karşı Takımın Verdiği Bir Nesneyi Kullanarak Anlat!",
    "Sessiz Harf Kullanma!",
    "Bozuk Türkçe İle Anlat!",
    "Tebrikler!!! 2 Defa Doğruya Bas.",
    "Yaa Çok Üzüldüm :( 1 Defa Tabuya Bas 1 Defa Pas'a Bas.",
    "2 Defa Pas'a Bas ve Anlatmaya Başla.",
    "1 Defa Tabuya Bas ve Anlat!",
    "1 Tane Yasaklı Kelimeyi Kullanabilirsin.",
    "Karşı Takımdan Birisini Kendi Takımına Transfer Et! (2 Tur)",
    "Takımından Bir Kişiyi Seç ve Onunla Dans Ederek Kelimeyi Anlat!"
  ];

  /// Rastgele joker mesajı döndürür.
  /// `probability` değeri 0 ile 1 arasında bir ihtimal belirtir (örn: 0.5 = %50).
  static String? getRandomJoker({double probability = 0.3}) {
    final random = Random();
    if (random.nextDouble() < probability) {
      int index = random.nextInt(jokerMessages.length);
      return jokerMessages[index]; // Sadece bir mesaj döner
    }
    return null; // Joker gösterilmez
  }

}
