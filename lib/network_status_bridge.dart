import 'dart:async';
import 'package:flutter/services.dart';

enum NetworkType {
  none,
  wifi,
  cellular,
  wired,
  other,
}

class NetworkStatusBridge {
  static const MethodChannel _methodChannel = MethodChannel('network_status_bridge/method');
  static const EventChannel _eventChannel = EventChannel('network_status_bridge/event');

  static Stream<NetworkType>? _onChanged;

  static Stream<NetworkType> get onNetworkChanged {
    _onChanged ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => NetworkType.values[event as int]);
    return _onChanged!;
  }

  static Future<NetworkType> getCurrentType() async {
    final int result = await _methodChannel.invokeMethod('getCurrentType');
    return NetworkType.values[result];
  }
}