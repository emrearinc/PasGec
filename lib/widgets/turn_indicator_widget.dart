import 'package:flutter/material.dart';

class TurnIndicatorWidget extends StatelessWidget {
  final String currentTeamName;
  final String currentPlayerName; // Yeni parametre: Sıradaki oyuncunun adı

  const TurnIndicatorWidget({
    Key? key,
    required this.currentTeamName,
    required this.currentPlayerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Mevcut Takım: $currentTeamName',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          const SizedBox(height: 5), // Biraz boşluk ekleyin
          Text(
            'Mevcut Oyuncu: $currentPlayerName',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
