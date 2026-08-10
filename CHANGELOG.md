## 0.0.4
### Fixed
- 订阅 `onNetworkChanged` 时立即发送当前网络状态（iOS/Android）
- iOS 改用 `os_unfair_lock` 替代并发队列 + barrier，消除 getter 与回调间的死锁风险
- Dart 端枚举越界防御（`NetworkType.values` 越界时回退 `other`）
- Android 复用 `MainScope`，移除无用 `eventSink` 字段
- podspec 版本与 pubspec 同步

## 0.0.3
### Fixed
- Call eventSink using the main thread

## 0.0.2
### Fixed
- Fixed iOS crash

## 0.0.1

- ✅ Initial release: iOS + Android network monitor plugin
