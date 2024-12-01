import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase başlatılıyor

  // Awesome Notifications'ı başlat
  AwesomeNotifications().initialize(
    'resource://drawable/res_notification_app_icon', // İkon yolu
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Temel Bildirimler',
        channelDescription: 'Genel bildirimler için kanal',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );
  // Kullanıcıdan bildirim izni isteyin
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PasGeç',
      debugShowCheckedModeBanner: false, // Debug banner kaldırıldı
      theme: ThemeData(
        fontFamily: 'ComicSans', // Tüm proje için varsayılan font
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple, // AppBar arka plan rengi
          titleTextStyle: TextStyle(
            fontFamily: 'ComicSans', // AppBar başlığı için özel font
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        primarySwatch: Colors.deepPurple, // Ana tema rengi
      ),
      home: const HomeScreen(),
    );
  }
}
