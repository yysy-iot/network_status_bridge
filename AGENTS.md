# AGENTS.md

Flutter 插件：iOS/Android 实时网络状态监听（iOS `NWPathMonitor` / Android `ConnectivityManager`）。Dart API 集中在 `lib/network_status_bridge.dart`，仓库无任何测试。

## 关键命令

- `flutter analyze`（根目录 + `example/`）— 唯一可用的验证手段，仓库没有测试文件
- `flutter pub get` — 改依赖后执行；`pubspec.lock` 被 gitignore（库包不提交）
- `flutter run`（在 `example/` 下）— 真机/模拟器验证
- `pod lib lint network_status_bridge.podspec` — 发布前校验 iOS podspec

## 架构与约定

- 通道名固定：`network_status_bridge/method`、`network_status_bridge/event`，Dart / Android / iOS 三端必须一致
- **`NetworkType` 枚举序号是跨端契约**：Dart 端 `NetworkType.values[event as int]` 直接按索引取值，Android `NetworkType.kt` 与 iOS `YYINetworkType` 的 Int 值必须与 Dart 枚举顺序严格一致（0=none, 1=wifi, 2=cellular, 3=wired, 4=other）。改动顺序会静默错乱，三端需同步修改
- 事件回调必须派发到主线程再调 `eventSink`（Android 用 `MainScope().launch`，iOS 用 `DispatchQueue.main.async`）。0.0.3 曾因主线程问题崩溃，勿回退该模式
- Android 端 `NetworkMonitor` 是单例 `object`，在 `onAttachedToEngine` 启动监听后**永不注销**（`onDetachedFromEngine` 只清 handler，未调 `unregisterNetworkCallback`）；`NetworkRequest.Builder().build()` 注册全部网络
- iOS 端 `YYINetworkMonitor` 用 `nw_path_monitor`（Network.framework），要求 iOS 12+（podspec `platform :ios, '12.0'`）；Android minSdk 23 / compileSdk 35 / Java 17

## 坑

- **iOS ObjC 源文件名为 ` YYINetworkMonitor.m`（带前导空格）**，podspec 靠 `Classes/**/*` 通配符收录。重命名/重构时勿误删或改坏
- iOS podspec `s.version` 是 0.0.1，与 pubspec 的 0.0.3 不一致，发布前需同步
- `example/lib/main.dart` 是粗糙的最小示例（缩进混乱），不要把它当作 API 用法标准