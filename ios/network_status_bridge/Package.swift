// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "network_status_bridge",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "network-status-bridge", targets: ["network_status_bridge"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // ObjC target：网络监听核心（NWPathMonitor 封装）
        // SwiftPM 不允许同一 target 混合 .swift 与 .m 源文件，故拆分为独立 target
        .target(
            name: "network_status_bridge_objc",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            path: "Sources/network_status_bridge_objc",
            publicHeadersPath: "include/network_status_bridge",
            cSettings: [
                .headerSearchPath("include/network_status_bridge")
            ]
        ),
        // Swift target：Flutter 插件入口（pluginClass）
        .target(
            name: "network_status_bridge",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .target(name: "network_status_bridge_objc")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)