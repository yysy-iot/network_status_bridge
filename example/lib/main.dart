import 'package:flutter/cupertino.dart';

import 'package:network_status_bridge/network_status_bridge.dart';

void main() {
  runApp(CupertinoApp(home: Container()));
    NetworkStatusBridge.onNetworkChanged.listen((status) {
    print("网络变化：$status");
  });

  NetworkStatusBridge.getCurrentType().then((type) {
    print("当前网络：$type");
  });
}
