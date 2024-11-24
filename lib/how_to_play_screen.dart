import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Nasıl Oynanır?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7F50), Color(0xFFFF4500), Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildSectionTitle('🎯 Tabu Oyunu Nedir?'),
              _buildText(
                'Tabu, kelime tahmini ve ekip oyunu üzerine kurulu, eğlenceli bir grup oyunudur. Amacınız, takım arkadaşlarınıza belirli bir kelimeyi yasaklı kelimeleri kullanmadan tahmin ettirmek.',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('👥 Oyuncu Sayısı'),
              _buildText(
                'En az 4 kişi ile oynanır. Oyuncular iki veya daha fazla takıma ayrılır. Her takımda eşit sayıda kişi olmasına dikkat edin.',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('📱 Ekran Özellikleri'),
              _buildText(
                '1. Takımların skorları ekranın üst kısmında görüntülenir.\n'
                    '2. Süre, ekranın ortasındaki sayaçla takip edilir.\n'
                    '3. Kelime kartında ana kelime ve yasaklı kelimeler gösterilir.\n'
                    '4. Pas, tabu ve doğru tahmin için özel butonlar bulunur.',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('📜 Kurallar ve Skorlama'),
              _buildText(
                '✔ **Doğru Tahmin**: +1 puan\n'
                    '❌ **Yasaklı Kelime Kullanımı**: -1 puan\n'
                    '⏭ **Pas Geçme**: -1 puan\n\n'
                    'Süre dolduğunda sıra diğer takıma geçer. Oyuncular, tahminleri hızlı ve yaratıcı bir şekilde yapmaya çalışmalıdır.',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('🏆 Oyun Nasıl Kazanılır?'),
              _buildText(
                'Belirlenen hedef puana ilk ulaşan takım oyunu kazanır. Eğer takımlar eşit puana sahipse, kazananı belirlemek için ek bir tur oynatılabilir.',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('💡 İpuçları ve Taktikler'),
              _buildText(
                '1. Soyut ifadelerle kelimeyi anlatmaya çalışın. Örneğin, "Kedi" kelimesi için "Evcil, bağımsız bir hayvan" diyebilirsiniz.\n'
                    '2. Takım üyeleri dikkatlice dinlemeli ve hızlı tahmin yapmalıdır.\n'
                    '3. Rahat bir ortamda oynayın ve eğlenmeye odaklanın!',
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    'Ana Menüye Dön',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 4.0,
              color: Colors.black54,
              offset: Offset(1.5, 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        height: 1.5,
      ),
    );
  }
}
