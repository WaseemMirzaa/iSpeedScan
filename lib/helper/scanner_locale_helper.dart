import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerLocaleHelper {
  static const MethodChannel _channel = MethodChannel('com.tevineighdesigns.ispeedscan1/scanner_locale');
  static const String _localeKey = 'selected_locale';

  /// Apply the current app locale to the Cunning Document Scanner
  static Future<bool> applyScannerLocale() async {
    try {
      // Get current locale from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey) ?? 'en';
      
      // Map app locale to scanner locale code
      final scannerLocale = _mapToScannerLocale(localeCode);
      
      // Call platform-specific method to set scanner locale
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('setScannerLocale', {'locale': scannerLocale});
        print('Scanner locale set to: $scannerLocale, result: $result');
        return result ?? false;
      } else if (Platform.isIOS) {
        final result = await _channel.invokeMethod('setScannerLocale', {'locale': scannerLocale});
        print('Scanner locale set to: $scannerLocale, result: $result');
        return result ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error setting scanner locale: $e');
      return false;
    }
  }
  
  /// Map app locale code to scanner locale code
  /// Cunning Document Scanner might use different locale codes or formats
  static String _mapToScannerLocale(String appLocale) {
    // This mapping depends on what locale codes the scanner accepts
    // Modify this mapping based on the scanner's supported locales
    switch (appLocale) {
      case 'zh': return 'zh-CN'; // Chinese
      case 'ja': return 'ja-JP'; // Japanese
      case 'ko': return 'ko-KR'; // Korean
      case 'ru': return 'ru-RU'; // Russian
      case 'ar': return 'ar-SA'; // Arabic
      case 'hi': return 'hi-IN'; // Hindi
      case 'es': return 'es-ES'; // Spanish
      case 'fr': return 'fr-FR'; // French
      case 'de': return 'de-DE'; // German
      case 'it': return 'it-IT'; // Italian
      case 'pt': return 'pt-PT'; // Portuguese
      case 'th': return 'th-TH'; // Thai
      case 'tr': return 'tr-TR'; // Turkish
      case 'vi': return 'vi-VN'; // Vietnamese
      case 'he': return 'he-IL'; // Hebrew
      default: return 'en-US';   // Default to English
    }
  }
}
