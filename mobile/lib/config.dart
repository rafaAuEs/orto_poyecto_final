import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Config {
  // Cambia esto por tu IP local si usas dispositivo físico: 'http://192.168.1.35:8000'
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; // Web siempre es localhost
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
