package com.tevineighdesigns.ispeedscan1

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine

object FlutterPluginRegistrant {
    fun registerPlugins(flutterEngine: FlutterEngine, context: Context) {
        // Register our scanner locale plugin
        ScannerLocalePlugin.registerWith(flutterEngine, context)
    }
}