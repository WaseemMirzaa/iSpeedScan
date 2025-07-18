import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// List of supported locales
class L10n {
  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('ja'),
    Locale('ar'),
    Locale('hi'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale('he'), // Added Hebrew
  ];
}

class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('en'); // Default to English

  LocaleProvider() {
    // Load appropriate locale when provider is created
    _initializeLocale();
  }

  /// Current app locale
  Locale get locale => _locale;

  /// Initialize locale based on priority:
  /// 1. User selected locale (if exists)
  /// 2. Device locale (if supported)
  /// 3. Default locale (English)
  Future<void> _initializeLocale() async {
    try {
      // Step 1: Check for user-selected locale in SharedPreferences
      final userSelectedLocale = await _getUserSelectedLocale();
      if (userSelectedLocale != null) {
        _locale = userSelectedLocale;
        print("Using user-selected locale: ${userSelectedLocale.languageCode}");
        notifyListeners();
        return;
      }

      // Step 2: Check device locale
      final deviceLocale = await _getDeviceLocale();
      if (deviceLocale != null && _isLocaleSupported(deviceLocale)) {
        _locale = deviceLocale;
        print("Using device locale: ${deviceLocale.languageCode}");
        notifyListeners();
        return;
      }

      // Step 3: Fallback to default (English)
      _locale = const Locale('en');
      print("Using default locale: en");
      notifyListeners();
    } catch (e) {
      print("Error initializing locale: $e");
      // Ensure we have a valid locale even if there's an error
      _locale = const Locale('en');
      notifyListeners();
    }
  }

  /// Get user-selected locale from SharedPreferences
  Future<Locale?> _getUserSelectedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocaleCode = prefs.getString(_localeKey);
    
    if (savedLocaleCode != null) {
      final locale = Locale(savedLocaleCode);
      if (_isLocaleSupported(locale)) {
        return locale;
      }
    }
    return null;
  }

  /// Get device locale
  Future<Locale?> _getDeviceLocale() async {
    final deviceLocale = WidgetsBinding.instance.window.locale;
    return deviceLocale;
  }

  /// Check if locale is in supported locales
  bool _isLocaleSupported(Locale locale) {
    return L10n.supportedLocales.contains(locale);
  }

  /// Set new locale if it's supported and save to preferences
  void setLocale(Locale locale) {
    if (!_isLocaleSupported(locale)) return;
    _locale = locale;
    _saveLocale(locale.languageCode);
    notifyListeners();
    print("Locale changed to: ${locale.languageCode}");
  }

  /// Reset to default (English)
  void clearLocale() {
    _locale = const Locale('en');
    _saveLocale('en');
    notifyListeners();
  }

  /// Save locale to SharedPreferences
  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    print("Saved locale: $languageCode");
  }
}
