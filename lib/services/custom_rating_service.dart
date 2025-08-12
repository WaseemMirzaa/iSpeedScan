import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_rating_dialog.dart';

class CustomRatingService {
  static const String _preferencesPrefix = 'customRateMyApp_';
  static const String _hasRatedKey = '${_preferencesPrefix}hasRated';
  static const String _launchCountKey = '${_preferencesPrefix}launchCount';
  static const String _firstLaunchKey = '${_preferencesPrefix}firstLaunch';
  static const String _lastReminderKey = '${_preferencesPrefix}lastReminder';
  
  // Configuration
  static const int minDays = 7;
  static const int minLaunches = 7;
  static const int remindDays = 7;
  static const int remindLaunches = 10;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set first launch date if not set
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setString(_firstLaunchKey, DateTime.now().toIso8601String());
    }
    
    // Increment launch count
    final currentCount = prefs.getInt(_launchCountKey) ?? 0;
    await prefs.setInt(_launchCountKey, currentCount + 1);
  }

  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if already rated
    if (prefs.getBool(_hasRatedKey) ?? false) {
      return false;
    }
    
    // Check minimum days
    final firstLaunchString = prefs.getString(_firstLaunchKey);
    if (firstLaunchString == null) return false;
    
    final firstLaunch = DateTime.parse(firstLaunchString);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    
    if (daysSinceFirstLaunch < minDays) {
      return false;
    }
    
    // Check minimum launches
    final launchCount = prefs.getInt(_launchCountKey) ?? 0;
    if (launchCount < minLaunches) {
      return false;
    }
    
    // Check if we should remind again
    final lastReminderString = prefs.getString(_lastReminderKey);
    if (lastReminderString != null) {
      final lastReminder = DateTime.parse(lastReminderString);
      final daysSinceReminder = DateTime.now().difference(lastReminder).inDays;
      
      if (daysSinceReminder < remindDays) {
        return false;
      }
      
      // Check if enough launches since reminder
      final launchesSinceReminder = launchCount - (prefs.getInt('${_preferencesPrefix}reminderLaunchCount') ?? 0);
      if (launchesSinceReminder < remindLaunches) {
        return false;
      }
    }
    
    return true;
  }

  static Future<void> showRatingDialog(BuildContext context) async {
    if (!await shouldShowDialog()) return;
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CustomRatingDialog(
          onButtonPressed: (String action) {
            _handleButtonPress(action);
          },
          onDismissed: () {
            _handleButtonPress('dismissed');
          },
        );
      },
    );
  }

  static Future<void> _handleButtonPress(String action) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (action) {
      case 'rate':
        await prefs.setBool(_hasRatedKey, true);
        print('User chose to rate the app');
        break;
      case 'later':
        await prefs.setString(_lastReminderKey, DateTime.now().toIso8601String());
        await prefs.setInt('${_preferencesPrefix}reminderLaunchCount', prefs.getInt(_launchCountKey) ?? 0);
        print('User chose to rate later');
        break;
      case 'no':
        await prefs.setBool(_hasRatedKey, true);
        print('User chose not to rate');
        break;
      case 'feedback':
        await prefs.setBool(_hasRatedKey, true);
        print('User provided feedback');
        break;
      case 'dismissed':
        await prefs.setString(_lastReminderKey, DateTime.now().toIso8601String());
        await prefs.setInt('${_preferencesPrefix}reminderLaunchCount', prefs.getInt(_launchCountKey) ?? 0);
        print('Dialog was dismissed');
        break;
    }
  }

  // Debug methods
  static Future<void> resetRatingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasRatedKey);
    await prefs.remove(_launchCountKey);
    await prefs.remove(_firstLaunchKey);
    await prefs.remove(_lastReminderKey);
    await prefs.remove('${_preferencesPrefix}reminderLaunchCount');
  }

  static Future<Map<String, dynamic>> getRatingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    final firstLaunchString = prefs.getString(_firstLaunchKey);
    final daysSinceFirstLaunch = firstLaunchString != null 
        ? DateTime.now().difference(DateTime.parse(firstLaunchString)).inDays 
        : 0;
    
    final lastReminderString = prefs.getString(_lastReminderKey);
    final daysSinceReminder = lastReminderString != null 
        ? DateTime.now().difference(DateTime.parse(lastReminderString)).inDays 
        : null;
    
    return {
      'hasRated': prefs.getBool(_hasRatedKey) ?? false,
      'launchCount': prefs.getInt(_launchCountKey) ?? 0,
      'daysSinceFirstLaunch': daysSinceFirstLaunch,
      'daysSinceReminder': daysSinceReminder,
      'shouldShow': await shouldShowDialog(),
      'firstLaunch': firstLaunchString,
      'lastReminder': lastReminderString,
    };
  }
}
