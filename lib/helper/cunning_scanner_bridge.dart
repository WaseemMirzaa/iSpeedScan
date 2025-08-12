// In the setLanguage method, add a debug statement for Hebrew
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ispeedscan/helper/scanner_locale_helper.dart';
import 'package:ispeedscan/helper/local_provider.dart';
import 'package:ispeedscan/helper/log_helper.dart';
 import 'package:shared_preferences/shared_preferences.dart';

//  Future<bool> setLanguage() async {
//   try {
//     // Get current locale from SharedPreferences
//     final prefs = await SharedPreferences.getInstance();
//     final localeCode = prefs.getString(_localeKey) ?? 'en';
    
//     // Special handling for Hebrew
//     if (localeCode == 'he') {
//       print('Setting Cunning Scanner language to Hebrew (he-IL)');
//     } else {
//       print('Setting Cunning Scanner language to: $localeCode');
//     }
    
//     // Call platform-specific method to set scanner language
//     final result = await _channel.invokeMethod('setLanguage', {'language': localeCode});
//     return result ?? false;
//   } catch (e) {
//     print('Error setting Cunning Scanner language: $e');
//     return false;
//   }
// }