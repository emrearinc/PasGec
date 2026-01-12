import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:math';
import 'package:tabu_oyunu/joker.dart';

class GameDialogs {
  /// Pas hakkı bittiğinde diyalog göster
  static Future<void> showPassLimitDialog(
      BuildContext context, VoidCallback onClose) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pas Hakkınız Bitti!'),
          content:
              const Text('Pas hakkınız kalmadı. Oyuna devam edebilirsiniz.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  /// Veritabanında kelime bulunamadığında diyalog
  static Future<void> showNoWordsDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uyarı'),
          content: const Text('Veritabanında aktif kelime bulunamadı!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  /// Joker mesajını göster
  static Future<void> showJokerDialog(
    BuildContext context, {
    required VoidCallback onClose,
  }) async {
    String? jokerMessage = await Joker.getRandomJoker();

    if (context.mounted && jokerMessage != null) {
      final List<AnimType> animations = [
        AnimType.scale,
        AnimType.leftSlide,
        AnimType.bottomSlide,
      ];
      final List<DialogType> dialogTypes = [
        DialogType.info,
        DialogType.warning,
        DialogType.noHeader,
      ];
      final List<IconData> icons = [
        Icons.casino,
        Icons.star,
        Icons.card_giftcard,
      ];

      final random = Random();
      final selectedAnimation = animations[random.nextInt(animations.length)];
      final selectedDialog = dialogTypes[random.nextInt(dialogTypes.length)];
      final selectedIcon = icons[random.nextInt(icons.length)];

      AwesomeDialog(
        context: context,
        dialogType: selectedDialog,
        animType: selectedAnimation,
        customHeader: Icon(
          selectedIcon,
          color: Colors.orange,
          size: 50,
        ),
        title: 'Joker!',
        desc: jokerMessage,
        btnOkText: 'Devam Et',
        btnOkOnPress: onClose,
      ).show();
    }
  }

  /// Oyun duraklat diyaloğu
  static Future<void> showPauseDialog(
    BuildContext context, {
    required VoidCallback onResume,
    required VoidCallback onExit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled,
                  size: 60,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oyun Durduruldu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Oyun şu an duraklatıldı. Devam etmek ister misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onResume();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Devam!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onExit();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.home,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Menüye Dön',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Çıkış onayı diyaloğu (menüye dönmek)
  static Future<void> showExitConfirmDialog(
    BuildContext context, {
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ana Menüye Dön',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Ana menüye dönmek istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 25,
                        ),
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Hayır',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 25,
                        ),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Evet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Takım seçim ekranına geri dönmek için onay diyaloğu
  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Çıkış Onayı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Takım seçimi ekranına dönmek istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 25,
                        ),
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Hayır',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 25,
                        ),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(
                        Icons.check,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Evet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return shouldExit ?? false;
  }
}
