import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.devnest/service_channel');

  static Future<bool> startServerService() async {
    try {
      final bool result = await _channel.invokeMethod('startService');
      return result;
    } on PlatformException catch (e) {
      print("Failed to start service: '${e.message}'.");
      return false;
    }
  }

  static Future<bool> stopServerService() async {
    try {
      final bool result = await _channel.invokeMethod('stopService');
      return result;
    } on PlatformException catch (e) {
      print("Failed to stop service: '${e.message}'.");
      return false;
    }
  }
}
