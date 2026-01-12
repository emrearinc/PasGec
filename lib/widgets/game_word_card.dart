import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'game_state_manager.dart';

class GameWordCard extends StatelessWidget {
  final Word word;

  const GameWordCard({
    super.key,
    required this.word,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white.withValues(alpha: 0.9),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AutoSizeText(
                  word.word,
                  style: const TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(
                  height: 5,
                  color: Colors.deepPurple,
                  thickness: 1.5,
                ),
                Column(
                  children: word.forbiddenWords.map((forbiddenWord) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Center(
                            child: AutoSizeText(
                              forbiddenWord,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
