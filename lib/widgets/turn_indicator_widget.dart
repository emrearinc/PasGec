import 'package:flutter/material.dart';

class TurnIndicatorWidget extends StatelessWidget {
  final String currentTeamName;

  const TurnIndicatorWidget({
    Key? key,
    required this.currentTeamName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sıra: $currentTeamName',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
        ),
      ),
    );
  }
}
