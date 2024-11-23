import 'package:flutter/material.dart';

class TurnIndicatorWidget extends StatelessWidget {
  final String currentTeamName;
  final String currentPlayerName; // Yeni parametre: Sıradaki oyuncunun adı

  const TurnIndicatorWidget({
    super.key, // Modern `key` kullanımı
    required this.currentTeamName,
    required this.currentPlayerName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Mevcut Takım: ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber, // Koyu turuncu
                  ),
                ),
                TextSpan(
                  text: currentTeamName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Beyaz renk
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5), // Biraz boşluk ekleyin
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Mevcut Oyuncu: ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber, // Koyu turuncu
                  ),
                ),
                TextSpan(
                  text: currentPlayerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Beyaz renk
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
