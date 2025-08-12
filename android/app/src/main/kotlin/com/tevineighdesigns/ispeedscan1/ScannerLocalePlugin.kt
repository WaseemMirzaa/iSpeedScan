package com.tevineighdesigns.ispeedscan1

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class ScannerLocalePlugin(private val context: Context) : MethodCallHandler {
    companion object {
        private const val CHANNEL = "com.tevineighdesigns.ispeedscan1/scanner_locale"
        
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(ScannerLocalePlugin(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setScannerLocale" -> {
                val localeString = call.argument<String>("locale") ?: "en-US"
                try {
                    // Store the locale in shared preferences for the scanner to access
                    val sharedPrefs = context.getSharedPreferences("scanner_prefs", Context.MODE_PRIVATE)
                    sharedPrefs.edit().putString("scanner_locale", localeString).apply()
                    
                    // Set system property that the scanner might check
                    System.setProperty("cunning.scanner.locale", localeString)
                    
                    result.success(true)
                } catch (e: Exception) {
                    result.error("LOCALE_ERROR", "Failed to set scanner locale", e.toString())
                }
            }
            else -> result.notImplemented()
        }
    }
}