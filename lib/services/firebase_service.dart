import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  static FirebaseService get instance => _instance;

  FirebaseService._internal();

  // Remove late keyword to avoid initialization errors
  FirebaseAnalytics? _analytics;
  FirebaseAnalytics get analytics {
    if (_analytics == null) {
      throw Exception('Firebase Analytics not initialized. Call initialize() first.');
    }
    return _analytics!;
  }

  FirebaseAnalyticsObserver getObserver() {
    return FirebaseAnalyticsObserver(analytics: analytics);
  }

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        // For Android, initialize with manual options
        if (Platform.isAndroid) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'AIzaSyCjdvnpDIYnLUHIGh94j4nsLXmqsbkGXsY',
              appId: '1:695369766912:android:3c84020514c056b80760e5',
              messagingSenderId: '695369766912',
              projectId: 'ispeedscan-4edc4',
              storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
            ),
          );
        } else if (Platform.isIOS) {
          // For iOS, use manual options as well
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: 'AIzaSyAHUsS5Wj9C7BFE6h2T3D3epCBtWu5nahM',
              appId: '1:695369766912:ios:c14507644b575c110760e5',
              messagingSenderId: '695369766912',
              projectId: 'ispeedscan-4edc4',
              storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
            ),
          );
        }
      }
      
      // Initialize analytics after Firebase is initialized
      _analytics = FirebaseAnalytics.instance;
      
      // Set analytics collection enabled
      await _analytics!.setAnalyticsCollectionEnabled(true);
      
      print('Firebase initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      // Ensure all parameter values are either String or num
      final validParameters = parameters?.map((key, value) {
        if (value is bool) {
          return MapEntry(key, value ? "true" : "false");
        } else if (value is String || value is num) {
          return MapEntry(key, value);
        } else {
          return MapEntry(key, value.toString());
        }
      });
      
      await _analytics!.logEvent(
        name: name,
        parameters: validParameters,
      );
      print('Event logged: $name');
    } catch (e) {
      print('Failed to log event: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      print('Screen view logged: $screenName');
    } catch (e) {
      print('Failed to log screen view: $e');
    }
  }

  /// Log app open event with additional metadata
  Future<void> logAppOpen() async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      // Log basic app_open event
      await _analytics!.logAppOpen();
      
      // Get additional information for enhanced app_opened event
      final prefs = await SharedPreferences.getInstance();
      final isFirstOpen = !prefs.containsKey('last_open_time');
      final lastOpenTime = prefs.getInt('last_open_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      
      // Calculate time since last open in hours
      final hoursSinceLastOpen = isFirstOpen 
          ? 0 
          : (currentTime - lastOpenTime) / (1000 * 60 * 60);
      
      // Log enhanced app_opened event with additional metadata
      await _analytics!.logEvent(
        name: 'app_opened',
        parameters: {
          'platform': Platform.isIOS ? 'iOS' : 'Android',
          'os_version': Platform.operatingSystemVersion,
          'is_first_open': isFirstOpen ? "true" : "false", // Convert boolean to string
          'hours_since_last_open': hoursSinceLastOpen.round(),
        },
      );
      
      // Save current time as last open time
      await prefs.setInt('last_open_time', currentTime);
      
      print('App open event logged successfully');
    } catch (e) {
      print('Failed to log app open event: $e');
    }
  }

  /// Log scan completed event
  Future<void> logScanCompleted(int pageCount) async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      await _analytics!.logEvent(
        name: 'scan_completed',
        parameters: {
          'page_count': pageCount,
        },
      );
      print('Scan completed event logged');
    } catch (e) {
      print('Failed to log scan completed event: $e');
    }
  }

  /// Log PDF created event
  Future<void> logPdfCreated(String quality, int pageCount) async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      await _analytics!.logEvent(
        name: 'pdf_created',
        parameters: {
          'quality': quality,
          'page_count': pageCount,
        },
      );
    } catch (e) {
      print('Failed to log PDF created event: $e');
    }
  }

  /// Log subscription purchase event
  Future<void> logSubscriptionPurchased() async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      await _analytics!.logEvent(
        name: 'subscription_purchased',
      );
    } catch (e) {
      print('Failed to log subscription purchased event: $e');
    }
  }

  /// Log subscription restore event
  Future<void> logSubscriptionRestored(bool success) async {
    try {
      // Ensure analytics is initialized
      if (_analytics == null) {
        await initialize();
      }
      
      await _analytics!.logEvent(
        name: 'subscription_restored',
        parameters: {
          'success': success ? "true" : "false",
        },
      );
    } catch (e) {
      print('Failed to log subscription restored event: $e');
    }
  }
}
