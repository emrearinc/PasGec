import 'dart:async';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _isOnlineController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  late Timer _periodicCheckTimer;

  Stream<bool> get isOnlineStream => _isOnlineController.stream;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    // İlk bağlantı durumunu kontrol et
    await checkInternetConnection();

    // Periyodik olarak bağlantı kontrol et (her 10 saniyede bir)
    _periodicCheckTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await checkInternetConnection();
    });
  }

  Future<bool> checkInternetConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://www.google.com/'),
          )
          .timeout(Duration(seconds: 3));

      final isOnline = response.statusCode == 200;
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        _isOnlineController.add(_isOnline);
      }
      return _isOnline;
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        _isOnlineController.add(_isOnline);
      }
      return false;
    }
  }

  void dispose() {
    _periodicCheckTimer.cancel();
    _isOnlineController.close();
  }
}
