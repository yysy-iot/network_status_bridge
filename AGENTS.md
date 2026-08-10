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
- **iOS 同时支持 SwiftPM 与 CocoaPods**（Flutter 3.44+ 默认 SwiftPM，CocoaPods 2026-12 转只读）。SPM 包在 `ios/network_status_bridge/`，因 SwiftPM 不允许 target 混语言，拆为两个 target：`network_status_bridge`（Swift，pluginClass）+ `network_status_bridge_objc`（ObjC 监听核心）。CocoaPods 下 Swift 通过模块 umbrella 自动访问 ObjC 头（不用 bridging header，framework target 不支持）

## 坑

- iOS 源文件位于 `ios/network_status_bridge/Sources/`：Swift 入口在 `network_status_bridge/`，ObjC 核心在 `network_status_bridge_objc/`（公开头在 `include/network_status_bridge/`）。**不要**把文件移回 `ios/Classes/`（已删除）
- iOS podspec 版本需与 pubspec 同步（当前 0.0.4）。改 podspec 的 `source_files` 时需同时含 `Sources/network_status_bridge` 与 `Sources/network_status_bridge_objc` 两目录
- `YYINetworkMonitor.h` 必须 `#import <Foundation/Foundation.h>`（独立 SPM target 下无 umbrella 头自动导入）
- `flutter build ios` 会触发 SPM 迁移并修改 `example/ios/` 工程文件（最低 iOS 13.0、UIScene 等），这些改动需一并提交
- `example/lib/main.dart` 是粗糙的最小示例（缩进混乱），不要把它当作 API 用法标准