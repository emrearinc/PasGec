import 'package:flutter/material.dart';

class ScoreCardWidget extends StatelessWidget {
  final String teamName; // Takım adı
  final int score; // Skor

  const ScoreCardWidget({
    Key? key,
    required this.teamName,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Takım Adı Gösterimi
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            teamName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 5),
        // Skor Kartı
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          color: Colors.white.withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$score', // Skoru Göster
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
