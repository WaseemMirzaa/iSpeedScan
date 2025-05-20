import 'package:flutter/material.dart';

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
  ];
}

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  /// Current app locale
  Locale get locale => _locale;

  /// Set new locale if it's supported
  void setLocale(Locale locale) {
    if (!L10n.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
    print(
        "Locale changed to: ${locale.languageCode}"); // Add this for debugging
  }

  /// Reset to default (English)
  void clearLocale() {
    _locale = const Locale('en');
    notifyListeners();
  }
}
