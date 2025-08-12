package com.tevineighdesigns.ispeedscan1

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PluginRegistrantReceiver(private val context: Context, private val flutterEngine: FlutterEngine) : MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.tevineighdesigns.ispeedscan1/plugin_registrant"
        
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(PluginRegistrantReceiver(context, flutterEngine))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "registerPlugins" -> {
                try {
                    // Register our scanner locale plugin
                    ScannerLocalePlugin.registerWith(flutterEngine, context)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("REGISTRATION_ERROR", "Failed to register plugins", e.toString())
                }
            }
            else -> result.notImplemented()
        }
    }
}