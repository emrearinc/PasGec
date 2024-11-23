import 'package:flutter/material.dart';

class GameButtonWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const GameButtonWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 35, color: color), // İkon rengi
        label: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Colors.transparent, // Arka plan şeffaf
          foregroundColor: color,
          elevation: 0,
        ),
      ),
    );
  }
}
