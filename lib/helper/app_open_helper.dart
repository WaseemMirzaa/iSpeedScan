import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';

class AppOpenHelper {
  static Future<void> logAppOpen() async {
    try {
      // Make sure Firebase is initialized first
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: Platform.isAndroid
              ? const FirebaseOptions(
                  apiKey: 'AIzaSyCjdvnpDIYnLUHIGh94j4nsLXmqsbkGXsY',
                  appId: '1:695369766912:android:3c84020514c056b80760e5',
                  messagingSenderId: '695369766912',
                  projectId: 'ispeedscan-4edc4',
                  storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
                )
              : const FirebaseOptions(
                  apiKey: 'AIzaSyAHUsS5Wj9C7BFE6h2T3D3epCBtWu5nahM',
                  appId: '1:695369766912:ios:c14507644b575c110760e5',
                  messagingSenderId: '695369766912',
                  projectId: 'ispeedscan-4edc4',
                  storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
                ),
        );
      }
      
      // Get analytics instance after ensuring Firebase is initialized
      final analytics = FirebaseAnalytics.instance;
      
      // Log standard app_open event
      await analytics.logAppOpen();
      
      // Get session information
      final prefs = await SharedPreferences.getInstance();
      final lastOpenTime = prefs.getInt('last_open_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final isFirstOpen = lastOpenTime == 0;
      
      // Calculate hours since last open
      final hoursSinceLastOpen = isFirstOpen 
          ? 0 
          : (currentTime - lastOpenTime) / (1000 * 60 * 60);
      
      // Log custom app_opened event with proper parameter types
      await analytics.logEvent(
        name: 'app_opened',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'os_version': Platform.operatingSystemVersion.toString(),
          'is_first_open': isFirstOpen ? "true" : "false", // String, not boolean
          'hours_since_last_open': hoursSinceLastOpen.round(),
        },
      );
      
      // Update last open time
      await prefs.setInt('last_open_time', currentTime);
      
      print('App open event logged successfully');
    } catch (e) {
      print('Failed to log app open event: $e');
    }
  }
}
