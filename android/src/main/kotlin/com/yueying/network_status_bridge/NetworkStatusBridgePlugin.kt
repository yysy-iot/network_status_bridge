package com.yueying.network_status_bridge

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** NetworkStatusBridgePlugin */
class NetworkStatusBridgePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var eventToken: String? = null
    private val scope = MainScope()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel =
            MethodChannel(flutterPluginBinding.binaryMessenger, "network_status_bridge/method")
        methodChannel.setMethodCallHandler(this)
        //
        eventChannel =
            EventChannel(flutterPluginBinding.binaryMessenger, "network_status_bridge/event")
        eventChannel.setStreamHandler(this)
        //
        flutterPluginBinding.applicationContext.let(NetworkMonitor::startMonitoring)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
    }


    override fun onMethodCall(call: MethodCall, result: Result) = when (call.method) {
        "getCurrentType" ->
            result.success(NetworkMonitor.type.value)

        else -> result.notImplemented()
    }


    override fun onListen(arguments: Any?, events: EventSink?) {
        // 先注册监听，确保不丢失任何变化
        eventToken = NetworkMonitor.addObserver {
            scope.launch {
                events?.success(it.value)
            }
        }
        // 再发送当前网络状态作为初始值（注册后读取，保证是最新的）
        events?.success(NetworkMonitor.type.value)
    }

    override fun onCancel(arguments: Any?) {
        eventToken?.let(NetworkMonitor::removeObserver)
        eventToken = null
    }
}
