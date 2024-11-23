import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter başlatılıyor
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
