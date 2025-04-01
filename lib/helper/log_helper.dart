
import 'package:flutter/services.dart';

class LogHelper {
  static const platform = MethodChannel('log_helper');

  static logSuccessMessage(String? logTitle, dynamic message) {
    print('🟢🟢🟢🟢🟢 SUCCESS ${logTitle ?? ''} : $message');
  }

  static logErrorMessage(String? logTitle, dynamic message) {
    print('🔴🔴🔴🔴🔴 ERROR ${logTitle ?? ''} : $message');
  }

  static logMessage(String? logTitle, dynamic message) {
    print('🟡🟡🟡🟡🟡 MESSAGE ${logTitle ?? ''} : $message');
  }

  static Future<void> handlePlatformLog(MethodCall call) async {
    if (call.method == 'logMessage') {
      final Map<String, dynamic> args = Map<String, dynamic>.from(call.arguments);
      final String type = args['type'] as String;
      final String title = args['title'] as String;
      final String message = args['message'] as String;

      switch (type) {
        case 'success':
          logSuccessMessage(title, message);
          break;
        case 'error':
          logErrorMessage(title, message);
          break;
        default:
          logMessage(title, message);
      }
    }
  }
}
