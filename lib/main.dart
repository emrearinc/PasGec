// File: lib/main.dart
// Screen: App startup
// Purpose: Firebase'i doğru opsiyonlarla başlatır, kelime paketini Firestore+GitHub RAW üzerinden indirip SQLite'a merge eder, sonra uygulamayı açar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

import 'home_screen.dart';
import 'firebase_options.dart';
import 'words_pack_updater.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Navigasyon çubuğunu gizle (System UI)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ✅ Status bar ve navigation bar stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ✅ ImageCache optimize
  imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100 MB
  imageCache.maximumSize = 1000; // 1000 resim

  // Firebase başlat (FlutterFire CLI config ile)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Connectivity Service'i başlat
  await ConnectivityService().init();

  // Kelime paketini senkronla (uygulamayı düşürmesin)
  try {
    await WordsPackUpdater().syncIfNeeded();
  } catch (e) {
    // ignore: avoid_print
    print('Words pack sync failed: $e');
  }

  // Awesome Notifications'ı başlat (temporarily disabled for APK build)
  // AwesomeNotifications().initialize(
  //   'resource://drawable/res_notification_app_icon',
  //   [
  //     NotificationChannel(
  //       channelKey: 'basic_channel',
  //       channelName: 'Temel Bildirimler',
  //       channelDescription: 'Genel bildirimler için kanal',
  //       defaultColor: const Color(0xFF9D50DD),
  //       ledColor: Colors.white,
  //       importance: NotificationImportance.High,
  //     ),
  //   ],
  // );

  // Bildirim izni (temporarily disabled for APK build)
  // final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  // if (!isAllowed) {
  //   await AwesomeNotifications().requestPermissionToSendNotifications();
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PasGeç',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'ComicSans',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          titleTextStyle: TextStyle(
            fontFamily: 'ComicSans',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomeScreen(),
    );
  }
}
