import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  static const String modeKey = "isPdfMode";
  static const String pdfQuality = "pdfQuality";

  static const _firstOpenDateKey = 'first_open_date';
  static const _pdfCreatedCountKey = 'pdf_created_count';
  static const String _usageKey = 'usage_minutes';
  static const String _lastResetKey = 'last_reset';

  // Save Mode to SharedPreferences
  static Future<void> saveMode(bool isPdfMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(modeKey, isPdfMode);
  }

  static Future<void> saveQuality(String quality) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pdfQuality, quality);
  }

  // Read Mode from SharedPreferences (default: true)
  static Future<bool> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(modeKey) ?? true;
  }

  // Read Mode from SharedPreferences (default: true)
  static Future<String> getPDFQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(pdfQuality) ?? 'Low';
  }

  // Remove Mode from SharedPreferences
  static Future<void> removeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(modeKey);
  }

  static getSavedQuality() {}

  // Save the current date as the first open date
  Future<void> saveFirstOpenDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    String formattedDate =
        now.toIso8601String(); // You can customize the format
    await prefs.setString(_firstOpenDateKey, formattedDate);
  }

  checkAndSaveDate() async {
    var date = await getFirstOpenDate();

    if (date == null) {
      saveFirstOpenDate();
    }
  }

  // Retrieve the saved first open date or return null if not set
  Future<String?> getFirstOpenDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firstOpenDateKey);
  }

  // Check if it's the first time the app is opened
  Future<bool> isFirstOpen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_firstOpenDateKey) == null;
  }

  // Check if the saved first open date is older than 7 days
  Future<bool> isFirstOpenDateOlderThan7Days() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDate = prefs.getString(_firstOpenDateKey);

    if (savedDate == null) {
      saveFirstOpenDate();
      return false; // No saved date, so it's not older than 7 days
    }

    // Parse the saved date from ISO8601 string
    DateTime firstOpenDate = DateTime.parse(savedDate);
    DateTime currentDate = DateTime.now();

    // Calculate the difference between the current date and the saved date
    Duration difference = currentDate.difference(firstOpenDate);

    print('Difference in days 🟡 ${firstOpenDate}');
    // Check if the difference is greater than 7 days
    return difference.inDays > 7;
  }

  // Increment and return the PDF created count
  Future<int> incrementAndReturnPdfCreatedCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_pdfCreatedCountKey) ?? 0;
    int newCount = currentCount + 1;
    await prefs.setInt(_pdfCreatedCountKey, newCount);

    return newCount;
  }

  // Fetch the PDF created count
  Future<int> getPdfCreatedCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var olderThan7Days = await isFirstOpenDateOlderThan7Days();

    if (!olderThan7Days) {
      await prefs.setInt(_pdfCreatedCountKey, 0);
    }

    return prefs.getInt(_pdfCreatedCountKey) ?? 0;
  }

  // Reset the PDF created count after 7 days
  Future<void> resetPdfCreatedCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? firstOpenDate = prefs.getString(_firstOpenDateKey);

    if (firstOpenDate != null) {
      DateTime firstOpenDateTime = DateTime.parse(firstOpenDate);
      DateTime currentDate = DateTime.now();
      Duration difference = currentDate.difference(firstOpenDateTime);

      if (difference.inDays % 7 == 0) {
        await prefs.setInt(_pdfCreatedCountKey, 0);
      }
    }
  }

  /// Saves the total usage time in minutes
  static Future<void> saveUsageMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_usageKey, minutes);
  }

  /// Retrieves the total usage time in minutes
  static Future<int> getUsageMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usageKey) ?? 0;
  }

  /// Saves the last reset timestamp
  static Future<void> saveLastResetTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastResetKey, time.millisecondsSinceEpoch);
  }

  /// Retrieves the last reset timestamp
  static Future<DateTime?> getLastResetTime() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_lastResetKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Resets usage time if a month has passed (30 days)
  static Future<int> checkAndResetMonthlyUsage() async {
    final now = DateTime.now();
    final lastReset = await getLastResetTime();

    if (lastReset == null || now.difference(lastReset).inDays >= 30) {
      await saveUsageMinutes(0);
      await saveLastResetTime(now);
      return 0;
    }

    return await getUsageMinutes();
  }

  /// Resets usage time if a week has passed (deprecated - use checkAndResetMonthlyUsage)
  static Future<int> checkAndResetWeeklyUsage() async {
    final now = DateTime.now();
    final lastReset = await getLastResetTime();

    if (lastReset == null || now.difference(lastReset).inDays >= 7) {
      await saveUsageMinutes(0);
      await saveLastResetTime(now);
      return 0;
    }

    return await getUsageMinutes();
  }
}
