## 0.0.5
### Changed
- SPM 支持完善：iOS 最低部署版本统一为 13.0（podspec 与 Package.swift 对齐，满足 Flutter 3.44+ SPM 要求）
- podspec 修复：补充 license type（MIT）、`source_files` 精确匹配 `*.{h,m,swift}`，避免 `PrivacyInfo.xcprivacy` 被当作源文件编译
- iOS `YYINetworkMonitor.h`：修复 `init` 声明 nullability 冲突（`_Nullable` → `_Nonnull`），消除编译警告
- 根 `.gitignore` 排除 `ios/FlutterFramework/`（Flutter SPM 自动生成的本地包，不应入库）
- 移除 example 遗留的 `.flutter-plugins` 旧路径文件（Flutter 3.44+ 已废弃，改用 `.flutter-plugins-dependencies`）

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
