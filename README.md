[![pub package](https://img.shields.io/pub/v/network_status_bridge.svg)](https://pub.dev/packages/network_status_bridge)

# network_status_bridge

A cross-platform Flutter plugin to monitor real-time network connectivity changes using iOS `NWPathMonitor` and Android `ConnectivityManager`.

## Features

- 🔄 Real-time network change callback
- 📱 Supports WiFi, Cellular, Ethernet, No Network
- 🧩 Native performance and accuracy

## Getting Started

```dart
NetworkStatusBridge.onNetworkChanged.listen((type) {
  print(\"Network changed: \$type\");
});