package com.yueying.network_status_bridge

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.launch

/** NetworkStatusBridgePlugin */
class NetworkStatusBridgePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var eventSink: EventSink? = null
    private var eventToken: String? = null

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
    }


    override fun onMethodCall(call: MethodCall, result: Result) = when (call.method) {
        "getCurrentType" ->
            result.success(NetworkMonitor.type.value)

        else -> result.notImplemented()
    }


    override fun onListen(arguments: Any?, events: EventSink?) {
        eventSink = events
        eventToken = NetworkMonitor.addObserver {
            MainScope().launch {
                events?.success(it.value)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventToken?.let(NetworkMonitor::removeObserver)
        eventToken = null
        eventSink = null
    }
}
