import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log a basic event
  static Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // Log screen view
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
    );
  }

  // Log scan completed
  static Future<void> logScanCompleted(int pageCount) async {
    await _analytics.logEvent(
      name: 'scan_completed',
      parameters: {
        'page_count': pageCount,
      },
    );
  }

  // Log PDF created
  static Future<void> logPdfCreated(String quality, int pageCount) async {
    await _analytics.logEvent(
      name: 'pdf_created',
      parameters: {
        'quality': quality,
        'page_count': pageCount,
      },
    );
  }

  // Log subscription purchased
  static Future<void> logSubscriptionPurchased() async {
    await _analytics.logEvent(
      name: 'subscription_purchased',
    );
  }
}