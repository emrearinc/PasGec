import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  final int timerValue;

  const TimerWidget({
    super.key, // Modern `key` kullanımı
    required this.timerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Süre: $timerValue',
        style: const TextStyle(
          fontSize: 35,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
