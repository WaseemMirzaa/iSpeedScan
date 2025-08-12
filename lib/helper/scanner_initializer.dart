// /// Initialize the scanner with the current language
// static Future<void> initialize() async {
//   if (_initialized) return;
  
//   try {
//     // Get current locale from SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     final localeCode = prefs.getString(_localeKey) ?? 'en';
    
//     // Special handling for Hebrew
//     if (localeCode == 'he') {
//       print('Initializing scanner with Hebrew language (he-IL)');
//     } else {
//       print('Initializing scanner with language: $localeCode');
//     }
    
//     // Initialize the scanner with the current language
//     await _channel.invokeMethod('initializeScanner', {'language': localeCode});
    
//     _initialized = true;
//   } catch (e) {
//     print('Error initializing scanner: $e');
//   }
// }