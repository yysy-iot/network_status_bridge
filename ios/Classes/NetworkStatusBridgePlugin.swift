import Flutter

public final class NetworkStatusBridgePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    private var token: String?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let methodChannel =  FlutterMethodChannel(name: "network_status_bridge/method", binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "network_status_bridge/event", binaryMessenger: messenger)
        //
        let instance = NetworkStatusBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
        //
        YYINetworkMonitor.shared.startMonitoring()
    }
    
    ///
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCurrentType":
            result(YYINetworkMonitor.shared.currentType.rawValue)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    ///
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        token = YYINetworkMonitor.shared.addObserver(networkObserver)
        return nil;
    }
    
    ///
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let token = token {
            YYINetworkMonitor.shared.removeObserver(token)
            self.token = nil
        }
        eventSink = nil
        return nil;
    }
    
    ///
    private func networkObserver(_ type: YYINetworkType) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(type.rawValue)
        }
    }
}
