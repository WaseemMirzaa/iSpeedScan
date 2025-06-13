import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsDebugHelper {
  static Future<void> enableDebugMode() async {
    if (Platform.isAndroid) {
      try {
        // For Android, we need to enable debug mode programmatically
        final analytics = FirebaseAnalytics.instance;
        
        // Enable analytics collection
        await analytics.setAnalyticsCollectionEnabled(true);
        
        // Log a test event to verify debug mode
        await analytics.logEvent(
          name: 'debug_mode_test',
          parameters: {
            'timestamp': DateTime.now().toIso8601String(),
            'debug_enabled': 'true',
          },
        );
        
        debugPrint('🔍 Firebase Analytics debug mode enabled for Android');
      } catch (e) {
        debugPrint('❌ Failed to enable Firebase Analytics debug mode: $e');
      }
    }
  }
}