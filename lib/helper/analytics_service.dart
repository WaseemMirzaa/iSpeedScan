
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Initialize analytics with debug mode
  static Future<void> initialize() async {
    // Enable debug mode to see analytics events in the console
    await _analytics.setAnalyticsCollectionEnabled(true);

    // Log initialization
    print('Analytics service initialized');
  }

  // Log a custom event
  static Future<void> logEvent(
      String name, Map<String, dynamic> parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      print('Analytics event logged: $name with parameters: $parameters');
    } catch (e) {
      print('Failed to log analytics event: $e');
    }
  }

  // Log when a screen is viewed
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Log when a PDF is created
  static Future<void> logPdfCreated(int pageCount, String source) async {
    await _analytics.logEvent(
      name: 'pdf_created',
      parameters: {
        'page_count': pageCount,
        'source': source,
      },
    );
  }

  // Log when a language is changed
  static Future<void> logLanguageChanged(String language) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {
        'language': language,
      },
    );
  }

  // Log when a purchase is made
  static Future<void> logPurchase(
      String productId, double price, String currency) async {
    await _analytics.logPurchase(
      currency: currency,
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productId,
          price: price,
        ),
      ],
    );
  }

  // Log when a user shares a PDF
  static Future<void> logShare(String contentType, String itemId) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: 'app',
    );
  }
}
