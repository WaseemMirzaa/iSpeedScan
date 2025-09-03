import 'dart:io';
import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ispeedscan/helper/local_provider.dart';

import 'package:ispeedscan/services/app_store_service.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../helper/log_helper.dart';
import '../helper/pdf_creation.dart';
import '../helper/shared_preference_service.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/permissions_util.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'scanner_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
export 'scanner_model.dart';

class ScannerWidget extends StatefulWidget {
  const ScannerWidget({super.key});
  // late String selectedValue;

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late String selectedValue;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   selectedValue = AppLocalizations.of(context)!.high;
  // }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      selectedValue = localizations.high;
    } else {
      // Handle the error or fallback here, for example:
      selectedValue = "en";
    }
  }

  DateTime? _sessionStartTime;
  int _totalUsageMinutes = 0;

  late ScannerModel _model;

  var service = PreferenceService();

  bool? isPhotoMode;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  // String selectedValue = AppLocalizations.of(context)!.high;

  Offerings? offerings;

  //todo is subscribed to false
  bool _isSubscribed = true;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  bool _is3DaysPassed = false;
  CustomerInfo? _customerInfo;

  // Progress bar state variables
  Timer? _progressTimer;
  double _progressValue = 1.0; // Start at 100% (full bar)
  int _remainingSeconds = 180; // 3 minutes = 180 seconds
  bool _showProgressBar = false;
  DateTime? _lastDialogShownDate;
  DateTime? _timerStartDate; // Track when timer cycle started
  bool _timerExpired = false; // Track if timer has expired

  @override
  void initState() {
    super.initState();

    _setPortraitMode();

    WidgetsBinding.instance.addObserver(this);
    _loadUsageTime();
    _checkFirstTimeOpen();
    _loadMode();
    _loadLastDialogShownDate();
    _loadTimerState();
    _initializeProgressBar();
  }

  Future<void> _checkFirstTimeOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTimeOpen = prefs.getBool('isFirstTimeAppOpened') ?? true;

    if (isFirstTimeOpen) {
      // Log first time open event
      await analytics.logEvent(
        name: 'event_on_first_open',
        parameters: {
          'os': Platform.isAndroid ? 'android' : 'ios',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Set the flag to false for future app opens
      await prefs.setBool('isFirstTimeAppOpened', false);

      LogHelper.logSuccessMessage(
          'First time app open', 'Event logged successfully');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionStartTime = DateTime.now();
      print('_sessionStartTime 👉 $_sessionStartTime');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_sessionStartTime != null) {
        _updateUsageTime();

        print('_sessionStartTime 👉 $_sessionStartTime');
      }
    }
  }

  Future<void> _updateUsageTime() async {
    final sessionEndTime = DateTime.now();
    final sessionDuration =
        sessionEndTime.difference(_sessionStartTime!).inSeconds;

    _totalUsageMinutes += sessionDuration;

    print('_end Time 👉 $sessionEndTime');
    print('_totalUsageMinutes 👉 $_totalUsageMinutes');

    await PreferenceService.saveUsageMinutes(_totalUsageMinutes);
  }

  Future<void> _loadUsageTime() async {
    final stopwatch = Stopwatch()..start();

    int minutes = await PreferenceService.checkAndResetMonthlyUsage();
    _totalUsageMinutes = minutes;

    stopwatch.stop();
    print(
        '⏱️ _loadUsageTime execution completed in ✅ ${stopwatch.elapsedMilliseconds}ms');
  }

  var isPurchased = false;
  SharedPreferences? prefs;

  Future<void> checkSubscriptionStatus() async {
    prefs = await SharedPreferences.getInstance();

    final storedSubscriptionStatus = prefs!.getBool('is_subscribed') ?? false;
    final isPurchasedChecked = prefs!.getBool('is_purchased_checked') ?? false;

    bool hasInternet = false;

    if (!isPurchasedChecked) {
      hasInternet = await checkInternet();
    }

    LogHelper.logSuccessMessage(
        'storedSubscriptionStatus', storedSubscriptionStatus);

    LogHelper.logSuccessMessage('isPurchasedChecked', isPurchasedChecked);

    if (storedSubscriptionStatus == true) {
      await analytics.logEvent(
        name: 'event_on_subscription_restored',
        parameters: {
          'os': Platform.isAndroid ? 'android' : 'ios',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      setState(() {
        //todo uncomment it
        // _isSubscribed = true;
      });
      return;
    } else {
      if (!isPurchasedChecked) {
        await checkPreviousAppPurchase();
      }

      // if (_isSubscribed) return;
      await service.checkAndSaveDate();

      _is3DaysPassed = await service.isFirstOpenDateOlderThan3Days();

      // Continue with regular subscription check
      _customerInfo = await Purchases.getCustomerInfo();
      offerings = await Purchases.getOfferings();

      LogHelper.logSuccessMessage('Customer Info', _customerInfo);
      LogHelper.logSuccessMessage('Offerings', offerings);

      if (_customerInfo
              ?.entitlements.all['sub_lifetime_ispeedscan']?.isActive ==
          true) {
        await prefs?.setBool('is_subscribed', true);

        await analytics.logEvent(
          name: 'event_on_already_subscribed',
          parameters: {
            'os': Platform.isAndroid ? 'android' : 'ios',
            'photoMode': isPhotoMode! ? "true" : "false",
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        setState(() {
          //todo uncomment it
          _isSubscribed = true;

          LogHelper.logSuccessMessage('subscribed', _isSubscribed);
        });
      } else {
        _isSubscribed = false;

        LogHelper.logErrorMessage('subscribed', _isSubscribed);
        setState(() {});
        if (_isSubscribed) {
          await prefs?.setBool('is_subscribed', true);
        }
      }

      if (!isPurchasedChecked) {
        checkPreviousAppPurchase();
      }

      if (_isSubscribed) {
        await prefs?.setBool('is_subscribed', true);
      }
    }

    if (hasInternet) {
      await prefs?.setBool('is_purchased_checked', true);
    }

    // Debug logging for subscription status
    print('📊 Subscription Status Check Complete:');
    print('  _isSubscribed: $_isSubscribed');
    print('  isPurchased: $isPurchased');
    print('  _is3DaysPassed: $_is3DaysPassed');

    // Update progress bar visibility after checking subscription status
    _updateProgressBarVisibility();
  }

  @override
  Future<void> _setPortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  // Main rating initialization method
  Future<void> initRateMyApp() async {
    final prefs = await SharedPreferences.getInstance();

    // Track first launch date
    if (!prefs.containsKey('first_launch_date')) {
      await prefs.setString(
          'first_launch_date', DateTime.now().toIso8601String());
    }

    // Increment launch count
    final currentCount = prefs.getInt('launch_count') ?? 0;
    await prefs.setInt('launch_count', currentCount + 1);

    // Check if we should show the rating dialog
    if (await _shouldShowRatingDialog()) {
      await _showCustomRatingDialog();
    }
  }

  // Check if rating dialog should be shown
  Future<bool> _shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();

    // Don't show if user has already rated
    if (prefs.getBool('has_rated') ?? false) {
      return false;
    }

    // Get first launch date
    final firstLaunchString = prefs.getString('first_launch_date');
    if (firstLaunchString == null) return false;

    final firstLaunch = DateTime.parse(firstLaunchString);
    final daysSinceFirstLaunch = DateTime.now().difference(firstLaunch).inDays;
    final launchCount = prefs.getInt('launch_count') ?? 0;

    // Check cooldown period
    final lastReminderString = prefs.getString('last_reminder_date');
    if (lastReminderString != null) {
      final lastReminder = DateTime.parse(lastReminderString);
      final daysSinceReminder = DateTime.now().difference(lastReminder).inDays;
      if (daysSinceReminder < 7) {
        return false; // Still in cooldown period
      }
    }

    // Show if: (3+ days AND 5+ launches) OR 7+ days
    return (daysSinceFirstLaunch >= 3 && launchCount >= 5) ||
        daysSinceFirstLaunch >= 7;
  }

  Future<void> _showCustomRatingDialog() async {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFFF8F9FA),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Icon or Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/app_launcher_icon.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to ispeed_logo.png if app_launcher_icon.jpg fails
                          return Image.asset(
                            'assets/images/ispeed_logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Final fallback to PDF icon
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF173F5A),
                                      Color(0xFF2E5A7A)
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Title
                  Text(
                    l10n!.rateThisApp,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF173F5A),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12),

                  // Message
                  Text(
                    l10n!.rateThisAppMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24),

                  // 5-Star Rating Bar
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: List.generate(5, (index) {
                  //     return GestureDetector(
                  //       onTap: () {
                  //         setState(() {
                  //           selectedStars = index + 1;
                  //         });
                  //       },
                  //       child: Container(
                  //         padding: EdgeInsets.all(4),
                  //         child: Icon(
                  //           selectedStars > index
                  //               ? Icons.star_rounded
                  //               : Icons.star_outline_rounded,
                  //           size: 40,
                  //           color: selectedStars > index
                  //               ? Colors.amber
                  //               : Colors.grey[300],
                  //         ),
                  //       ),
                  //     );
                  //   }),
                  // ),

                  SizedBox(height: 8),

                  // Rating feedback text

                  // Buttons
                  Column(
                    children: [
                      // Rate Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: EdgeInsets.only(bottom: 12),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            print('User clicked Rate button');

                            // Track analytics
                            try {
                              await analytics.logEvent(
                                name: 'rating_button_clicked',
                                parameters: {
                                  'timestamp': DateTime.now().toIso8601String(),
                                  'platform':
                                      Platform.isAndroid ? 'android' : 'ios',
                                },
                              );
                            } catch (e) {
                              print('Analytics error: $e');
                            }

                            // Always take user to store for rating/feedback
                            await _handleRateButtonPressed();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF173F5A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            l10n!.rate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Secondary buttons row
                      Row(
                        children: [
                          // "No Thanks" Button
                          Expanded(
                            child: Container(
                              height: 44,
                              margin: EdgeInsets.only(right: 6),
                              child: TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  print('User clicked "No Thanks"');

                                  // Set reminder for later (don't mark as rated)
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('last_reminder_date',
                                      DateTime.now().toIso8601String());
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  l10n!.noThanks,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // "Maybe Later" Button
                          Expanded(
                            child: Container(
                              height: 44,
                              margin: EdgeInsets.only(left: 6),
                              child: TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  print('User clicked "Maybe Later"');

                                  // Set reminder for later (don't mark as rated)
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('last_reminder_date',
                                      DateTime.now().toIso8601String());
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Text(
                                  l10n!.maybeLater,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // // Custom attractive rating dialog
  // Future<void> _showCustomRatingDialog() async {
  //   if (!mounted) return;

  //   // Log analytics
  //   await analytics.logEvent(
  //     name: 'rating_dialog_shown',
  //     parameters: {
  //       'timestamp': DateTime.now().toIso8601String(),
  //       'platform': Platform.isAndroid ? 'android' : 'ios',
  //     },
  //   );

  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(24.0),
  //         ),
  //         elevation: 20,
  //         backgroundColor: Colors.transparent,
  //         child: Container(
  //           width: MediaQuery.of(context).size.width * 0.85,
  //           constraints: BoxConstraints(
  //             maxWidth: 400,
  //             maxHeight: MediaQuery.of(context).size.height * 0.7,
  //           ),
  //           padding: EdgeInsets.all(28.0),
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(24.0),
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [
  //                 Colors.white,
  //                 Color(0xFFF8F9FA),
  //                 Color(0xFFF1F3F4),
  //               ],
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.15),
  //                 blurRadius: 30,
  //                 offset: Offset(0, 15),
  //                 spreadRadius: 0,
  //               ),
  //               BoxShadow(
  //                 color: Color(0xFF173F5A).withValues(alpha: 0.1),
  //                 blurRadius: 20,
  //                 offset: Offset(0, 10),
  //                 spreadRadius: 0,
  //               ),
  //             ],
  //           ),
  //           child: SingleChildScrollView(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 // Beautiful App Icon with enhanced styling
  //                 Container(
  //                   width: 90,
  //                   height: 90,
  //                   decoration: BoxDecoration(
  //                     borderRadius: BorderRadius.circular(20),
  //                     gradient: LinearGradient(
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                       colors: [
  //                         Color(0xFF173F5A),
  //                         Color(0xFF2E5A7A),
  //                         Color(0xFF4A7BA7),
  //                       ],
  //                     ),
  //                     boxShadow: [
  //                       BoxShadow(
  //                         color: Color(0xFF173F5A).withValues(alpha: 0.4),
  //                         blurRadius: 20,
  //                         offset: Offset(0, 8),
  //                         spreadRadius: 0,
  //                       ),
  //                       BoxShadow(
  //                         color: Colors.white.withValues(alpha: 0.8),
  //                         blurRadius: 10,
  //                         offset: Offset(-2, -2),
  //                         spreadRadius: 0,
  //                       ),
  //                     ],
  //                   ),
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(20),
  //                     child: Image.asset(
  //                       'assets/images/app_launcher_icon.jpg',
  //                       width: 90,
  //                       height: 90,
  //                       fit: BoxFit.cover,
  //                       errorBuilder: (context, error, stackTrace) {
  //                         return Image.asset(
  //                           'assets/images/ispeed_logo.png',
  //                           width: 90,
  //                           height: 90,
  //                           fit: BoxFit.cover,
  //                           errorBuilder: (context, error, stackTrace) {
  //                             return Container(
  //                               width: 90,
  //                               height: 90,
  //                               decoration: BoxDecoration(
  //                                 borderRadius: BorderRadius.circular(20),
  //                                 gradient: LinearGradient(
  //                                   begin: Alignment.topLeft,
  //                                   end: Alignment.bottomRight,
  //                                   colors: [
  //                                     Color(0xFF173F5A),
  //                                     Color(0xFF2E5A7A),
  //                                     Color(0xFF4A7BA7),
  //                                   ],
  //                                 ),
  //                               ),
  //                               child: Icon(
  //                                 Icons.document_scanner_rounded,
  //                                 size: 45,
  //                                 color: Colors.white,
  //                               ),
  //                             );
  //                           },
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 ),

  //                 SizedBox(height: 24),

  //                 // Enhanced Title with better typography
  //                 Text(
  //                   'Rate iSpeedScan',
  //                   style: TextStyle(
  //                     fontSize: 26,
  //                     fontWeight: FontWeight.bold,
  //                     color: Color(0xFF173F5A),
  //                     letterSpacing: -0.5,
  //                     height: 1.2,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),

  //                 SizedBox(height: 12),

  //                 // Enhanced Message with better styling
  //                 Text(
  //                   'Love using iSpeedScan? Your rating helps us improve and reach more users who need fast document scanning!',
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     color: Color(0xFF6B7280),
  //                     height: 1.5,
  //                     fontWeight: FontWeight.w400,
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),

  //                 SizedBox(height: 32),

  //                 // Enhanced Buttons with better styling
  //                 Column(
  //                   children: [
  //                     // Primary Rate Button with gradient
  //                     Container(
  //                       width: double.infinity,
  //                       height: 54,
  //                       margin: EdgeInsets.only(bottom: 16),
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(16.0),
  //                         gradient: LinearGradient(
  //                           begin: Alignment.topLeft,
  //                           end: Alignment.bottomRight,
  //                           colors: [
  //                             Color(0xFF173F5A),
  //                             Color(0xFF2E5A7A),
  //                           ],
  //                         ),
  //                         boxShadow: [
  //                           BoxShadow(
  //                             color: Color(0xFF173F5A).withValues(alpha: 0.3),
  //                             blurRadius: 15,
  //                             offset: Offset(0, 6),
  //                             spreadRadius: 0,
  //                           ),
  //                         ],
  //                       ),
  //                       child: ElevatedButton(
  //                         onPressed: () async {
  //                           Navigator.of(context).pop();
  //                           print('User clicked Rate button');

  //                           try {
  //                             await analytics.logEvent(
  //                               name: 'rating_button_clicked',
  //                               parameters: {
  //                                 'timestamp': DateTime.now().toIso8601String(),
  //                                 'platform':
  //                                     Platform.isAndroid ? 'android' : 'ios',
  //                               },
  //                             );
  //                           } catch (e) {
  //                             print('Analytics error: $e');
  //                           }

  //                           await _handleRateButtonPressed();
  //                         },
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: Colors.transparent,
  //                           foregroundColor: Colors.white,
  //                           shadowColor: Colors.transparent,
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(16.0),
  //                           ),
  //                           elevation: 0,
  //                         ),
  //                         child: Row(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           children: [
  //                             Icon(Icons.star_rounded, size: 20),
  //                             SizedBox(width: 8),
  //                             Text(
  //                               'Rate App',
  //                               style: TextStyle(
  //                                 fontSize: 17,
  //                                 fontWeight: FontWeight.w600,
  //                                 letterSpacing: 0.5,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     ),

  //                     // Secondary buttons row with enhanced styling
  //                     Row(
  //                       children: [
  //                         // "No Thanks" Button
  //                         Expanded(
  //                           child: Container(
  //                             height: 48,
  //                             margin: EdgeInsets.only(right: 8),
  //                             child: TextButton(
  //                               onPressed: () async {
  //                                 Navigator.of(context).pop();
  //                                 print('User clicked "No Thanks"');

  //                                 final prefs =
  //                                     await SharedPreferences.getInstance();
  //                                 await prefs.setString('last_reminder_date',
  //                                     DateTime.now().toIso8601String());
  //                               },
  //                               style: TextButton.styleFrom(
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(12.0),
  //                                   side: BorderSide(
  //                                     color: Color(0xFFE5E7EB),
  //                                     width: 1.5,
  //                                   ),
  //                                 ),
  //                                 backgroundColor: Colors.white,
  //                               ),
  //                               child: Text(
  //                                 'No Thanks',
  //                                 style: TextStyle(
  //                                   color: Color(0xFF6B7280),
  //                                   fontSize: 15,
  //                                   fontWeight: FontWeight.w500,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),

  //                         // "Maybe Later" Button
  //                         Expanded(
  //                           child: Container(
  //                             height: 48,
  //                             margin: EdgeInsets.only(left: 8),
  //                             child: TextButton(
  //                               onPressed: () async {
  //                                 Navigator.of(context).pop();
  //                                 print('User clicked "Maybe Later"');

  //                                 final prefs =
  //                                     await SharedPreferences.getInstance();
  //                                 await prefs.setString('last_reminder_date',
  //                                     DateTime.now().toIso8601String());
  //                               },
  //                               style: TextButton.styleFrom(
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.circular(12.0),
  //                                   side: BorderSide(
  //                                     color: Color(0xFFE5E7EB),
  //                                     width: 1.5,
  //                                   ),
  //                                 ),
  //                                 backgroundColor: Colors.white,
  //                               ),
  //                               child: Text(
  //                                 'Maybe Later',
  //                                 style: TextStyle(
  //                                   color: Color(0xFF6B7280),
  //                                   fontSize: 15,
  //                                   fontWeight: FontWeight.w500,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // Handle rate button pressed - Direct store navigation
  Future<void> _handleRateButtonPressed() async {
    final prefs = await SharedPreferences.getInstance();

    print('🌟 Rate button pressed - opening app store directly');

    // Log analytics
    try {
      await analytics.logEvent(
        name: 'rating_button_clicked',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
    } catch (e) {
      print('Analytics error: $e');
    }

    // Mark as rated to prevent repeated dialogs
    await prefs.setBool('has_rated', true);

    // Open store page directly for rating
    await _openStorePageForRating();
  }

  // Open store page for rating with enhanced native URL schemes
  Future<void> _openStorePageForRating() async {
    print('🌟 Opening app store for rating...');

    try {
      bool success = false;

      if (Platform.isAndroid) {
        // Android - Try multiple URL schemes for Google Play Store
        final androidUrls = [
          'https://play.google.com/store/apps/details?id=com.tevineighdesigns.ispeedscan1',
          'intent://details?id=com.tevineighdesigns.ispeedscan1#Intent;scheme=market;action=android.intent.action.VIEW;category=android.intent.category.BROWSABLE;package=com.android.vending;end',
        ];

        for (String url in androidUrls) {
          try {
            print('📱 Android: Trying URL: $url');
            success = await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            if (success) {
              print('✅ Android URL successful: $url');
              break;
            }
          } catch (e) {
            print('❌ Android URL failed: $url - Error: $e');
            continue;
          }
        }
      } else if (Platform.isIOS) {
        // iOS - Try multiple URL schemes for App Store
        final iosUrls = [
          'itms-apps://apps.apple.com/app/id6627339270',
        ];

        for (String url in iosUrls) {
          try {
            print('📱 iOS: Trying URL: $url');
            success = await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            if (success) {
              print('✅ iOS URL successful: $url');
              break;
            }
          } catch (e) {
            print('❌ iOS URL failed: $url - Error: $e');
            continue;
          }
        }
      }
    } catch (e) {
      print('❌ Store page opening failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not open app store. Please search for "iSpeedScan" in your app store and leave a review!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  // Manual trigger for testing
  Future<void> showRatingDialogManually() async {
    print('🧪 TESTING: Manually showing rating dialog');
    await _showCustomRatingDialog();
  }

  // Reset rating preferences for testing
  Future<void> resetRatingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_rated');
    await prefs.remove('first_launch_date');
    await prefs.remove('launch_count');
    await prefs.remove('last_reminder_date');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Rating preferences reset! You can now test the rating dialog.'),
          backgroundColor: Color(0xFF173F5A),
          duration: Duration(seconds: 3),
        ),
      );
    }
    print('✅ Rating preferences reset for testing');
  }

  // Test the rate button functionality directly
  Future<void> testRateButtonDirectly() async {
    print('🧪 TESTING: Testing rate button functionality directly');
    print(
        '🧪 Platform: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Unknown"}');
    await _handleRateButtonPressed();
  }

  Future<void> _loadLastDialogShownDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownString = prefs.getString('last_trial_dialog_shown');
    if (lastShownString != null) {
      try {
        final parts = lastShownString.split('-');
        if (parts.length == 3) {
          _lastDialogShownDate = DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day
          );
        }
      } catch (e) {
        print('Error parsing last dialog shown date: $e');
      }
    }
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user is subscribed or purchased - no timer needed
    if (_isSubscribed || isPurchased) {
      print('⏰ User subscribed/purchased, no timer restrictions');
      return;
    }

    // Check if 7-day trial has passed
    final is3DaysPassed = await service.isFirstOpenDateOlderThan3Days();

    // final is7DaysPassed = await service.isFirstOpenDateOlderThan7Days();
    if (!is3DaysPassed) {
      print('⏰ Still in 3-day free trial, no timer restrictions');
      return;
    }

    print('⏰ 3-day trial passed, loading timer state for monthly cycle');

    // Load timer start date
    final timerStartString = prefs.getString('timer_start_date');
    final timerExpiredString = prefs.getString('timer_expired_date');

    if (timerStartString != null) {
      try {
        _timerStartDate = DateTime.parse(timerStartString);

        // Check if timer has expired
        _timerExpired = prefs.getBool('timer_expired') ?? false;

        if (_timerExpired && timerExpiredString != null) {
          // Timer has expired, check if 30 days have passed since expiration
          final expiredDate = DateTime.parse(timerExpiredString);
          final now = DateTime.now();
          final daysSinceExpired = now.difference(expiredDate).inDays;

          if (daysSinceExpired >= 30) {
            // 30 days have passed since expiration, start new monthly cycle
            print(
                '🔄 30 days passed since timer expired, starting new monthly cycle');
            await _resetTimerCycle();
          } else {
            // Still in 30-day pause period
            _remainingSeconds = 0;
            _progressValue = 0.0;
            final remainingDays = 30 - daysSinceExpired;
            print(
                '⏸️ Timer paused at 0:00 for $remainingDays more days until monthly reset');
          }
        } else if (!_timerExpired) {
          // Timer is still running, continue from where it left off
          print('⏰ Timer still running, continuing countdown');
        } else {
          // Timer expired but no expiration date saved (legacy), set it now
          await prefs.setString(
              'timer_expired_date', DateTime.now().toIso8601String());
          _remainingSeconds = 0;
          _progressValue = 0.0;
          print('⏰ Timer expired, starting 30-day pause until monthly reset');
        }
      } catch (e) {
        print('Error parsing timer dates: $e');
        await _resetTimerCycle();
      }
    } else {
      // First time after 7-day trial - start new monthly timer cycle
      print('🆕 Starting first monthly timer cycle after 7-day trial');
      await _resetTimerCycle();
    }
  }

  Future<void> _resetTimerCycle() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    _timerStartDate = now;
    _timerExpired = false;
    _remainingSeconds = 180;
    _progressValue = 1.0;

    await prefs.setString('timer_start_date', now.toIso8601String());
    await prefs.setBool('timer_expired', false);
    await prefs.remove('timer_expired_date'); // Clear expiration date

    print('🆕 Starting new 30-day timer cycle');
  }

  Future<void> _saveTimerExpiredState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setBool('timer_expired', true);
    await prefs.setString('timer_expired_date', now.toIso8601String());
    _timerExpired = true;

    print('⏸️ Timer expired, starting 30-day pause period');
  }

  Future<void> _resetTimer() async {
    print('🔄 Manual timer reset requested');

    // Stop any running timer
    _stopProgressTimer();

    // Reset to new cycle
    await _resetTimerCycle();

    // Force start the timer for testing
    print('🚀 Force starting timer after reset');
    _startProgressTimer(force: true);

    // Update UI
    setState(() {});

    print('✅ Timer manually reset to 3:00 and started');
  }

  // TESTING METHOD - Force start timer for testing
  void _forceStartTimer() {
    print('🧪 TESTING: Force starting timer');
    _remainingSeconds = 180;
    _progressValue = 1.0;
    _timerExpired = false;
    _startProgressTimer(force: true);
    setState(() {
      _showProgressBar = true;
    });
    print('🧪 TESTING: Timer force started with 3:00');
  }

  // TESTING METHODS FOR DEBUG BUTTONS
  Future<void> _testBypass7DayTrial() async {
    print('🧪 TESTING: Bypassing 3-day trial');

    // Set subscription and purchase status to false
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_subscribed', false);
    await prefs.setBool('is_purchased_checked', false);

    // Set first open date to 8 days ago to bypass 7-day limit
    final eightDaysAgo = DateTime.now().subtract(Duration(days: 4));
    await prefs.setString('first_open_date', eightDaysAgo.toIso8601String());

    // Update local state
    _isSubscribed = false;
    isPurchased = false;
    _is3DaysPassed = true;

    // Update progress bar visibility
    _updateProgressBarVisibility();

    setState(() {});
    print('✅ TESTING: 3-day trial bypassed, progress bar should show');
  }

  Future<void> _testReset3MinTimer() async {
    print('🧪 TESTING: Resetting 3-minute timer');

    _isSubscribed = false;
    // Reset timer to fresh state
    await _resetTimerCycle();

    // Force start the timer
    _startProgressTimer(force: true);

    setState(() {
      _showProgressBar = true;
    });

    print('✅ TESTING: 3-minute timer reset and started');
  }

  Future<void> _testReset30DayTimer() async {
    print('🧪 TESTING: Resetting 30-day timer cycle');

    final prefs = await SharedPreferences.getInstance();

    // Clear all timer-related preferences
    await prefs.remove('timer_start_date');
    await prefs.remove('timer_expired');
    await prefs.remove('timer_expired_date');
    await prefs.remove('last_trial_dialog_shown');
    await prefs.remove('last_enjoying_dialog_shown');

    // Reset local state
    _timerStartDate = null;
    _timerExpired = false;
    _lastDialogShownDate = null;

    // Start new timer cycle
    await _resetTimerCycle();
    _startProgressTimer(force: true);

    setState(() {
      _showProgressBar = true;
    });

    print('✅ TESTING: 30-day timer cycle reset');
  }

  Future<void> _testShowDay2Dialog() async {
    print('🧪 TESTING: Simulating Day 2 dialog');

    final prefs = await SharedPreferences.getInstance();

    // Set first open date to 2 days ago
    final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
    await prefs.setString('first_open_date', twoDaysAgo.toIso8601String());

    // Clear the dialog shown preference to allow showing again
    await prefs.remove('last_enjoying_dialog_shown');

    // Set non-subscribed state
    _isSubscribed = false;
    isPurchased = false;

    // Force show the dialog
    await _checkAndShowStillEnjoyingDialog();

    print('✅ TESTING: Day 2 dialog triggered');
  }

  Future<void> _testShowDay4Dialog() async {
    print('🧪 TESTING: Simulating Day 4 dialog');

    final prefs = await SharedPreferences.getInstance();

    // Set first open date to 4 days ago
    final fourDaysAgo = DateTime.now().subtract(Duration(days: 4));
    await prefs.setString('first_open_date', fourDaysAgo.toIso8601String());

    // Clear the dialog shown preference to allow showing again
    await prefs.remove('last_enjoying_dialog_shown');

    // Set non-subscribed state
    _isSubscribed = false;
    isPurchased = false;

    // Force show the dialog
    await _checkAndShowStillEnjoyingDialog();

    print('✅ TESTING: Day 4 dialog triggered');
  }

  Future<void> _testShowTrialLimitDialog() async {
    print('🧪 TESTING: Showing trial limit dialog');

    final prefs = await SharedPreferences.getInstance();

    // Clear the dialog shown preference to allow showing again
    await prefs.remove('last_trial_dialog_shown');

    // Set timer to expired state
    _timerExpired = true;
    _remainingSeconds = 0;
    _progressValue = 0.0;

    // Force show the dialog
    await _showTrialLimitDialogOncePerDay();

    setState(() {});

    print('✅ TESTING: Trial limit dialog triggered');
  }

  // DEBUG METHOD - Check all dialog conditions
  Future<void> _debugDialogConditions() async {
    print('🔍 DEBUG: Checking trial limit dialog conditions:');
    print('   - _isSubscribed: $_isSubscribed');
    print('   - isPurchased: $isPurchased');
    print('   - _is3DaysPassed: $_is3DaysPassed');
    print('   - _timerExpired: $_timerExpired');
    print('   - _remainingSeconds: $_remainingSeconds');

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final lastShownString = prefs.getString('last_trial_dialog_shown');

    print('   - Today: $todayString');
    print('   - Last shown: $lastShownString');
    print('   - Already shown today: ${lastShownString == todayString}');

    // Check first open date
    final firstOpenDateString = await service.getFirstOpenDate();
    if (firstOpenDateString != null) {
      final firstOpenDate = DateTime.parse(firstOpenDateString);
      final daysSinceFirstOpen =
          DateTime.now().difference(firstOpenDate).inDays;
      print('   - First open date: $firstOpenDateString');
      print('   - Days since first open: $daysSinceFirstOpen');
    } else {
      print('   - First open date: null');
    }

    // Final verdict
    bool shouldShow = !_isSubscribed &&
        !isPurchased &&
        _is3DaysPassed &&
        _timerExpired &&
        lastShownString != todayString;

    print('   - Should show dialog: $shouldShow');
    print('   - Should block navigation: ${_shouldBlockNavigation()}');
  }

  // Check if navigation should be blocked
  bool _shouldBlockNavigation() {
    // Block navigation if:
    // 1. User is not subscribed AND not purchased
    // 2. 3-day trial period has passed
    // 3. 3-minute timer has expired
    bool shouldBlock =
        !_isSubscribed && !isPurchased && _is3DaysPassed && _timerExpired;

    print('🚫 Navigation block check:');
    print('   - Not subscribed: ${!_isSubscribed}');
    print('   - Not purchased: ${!isPurchased}');
    print('   - 3 days passed: $_is3DaysPassed');
    print('   - Timer expired: $_timerExpired');
    print('   - Should block: $shouldBlock');

    return shouldBlock;
  }

  void _initializeProgressBar() {
    // Check if we should show the progress bar
    _updateProgressBarVisibility();
  }

  void _updateProgressBarVisibility() {
    // Progress bar logic for non-subscribed users:
    // 1. During 3-day trial: NO progress bar (unlimited usage)
    // 2. After 3-day trial: YES progress bar (3-minute monthly timer)
    // 3. Subscribed/Purchased users: NO progress bar (unlimited usage)

    bool shouldShow = false;

    if (_isSubscribed || isPurchased) {
      // Subscribed or purchased users get unlimited access
      shouldShow = false;
      print('🔍 Progress Bar: Hidden (user subscribed/purchased)');
    } else if (!_is3DaysPassed) {
      // During 7-day trial period - no timer restrictions
      shouldShow = false;
      print('🔍 Progress Bar: Hidden (still in 7-day free trial)');
    } else {
      // After 7-day trial - show progress bar with monthly timer
      shouldShow = true;
      print(
          '🔍 Progress Bar: Visible (3-day trial ended, monthly timer active)');
    }

    // Debug logging
    print('🔍 Progress Bar Debug:');
    print('  _isSubscribed: $_isSubscribed');
    print('  isPurchased: $isPurchased');
    print('  _is3DaysPassed: $_is3DaysPassed');
    print('  shouldShow: $shouldShow');
    print('  _showProgressBar: $_showProgressBar');

    if (shouldShow != _showProgressBar) {
      setState(() {
        _showProgressBar = shouldShow;
        if (_showProgressBar && !_timerExpired) {
          print('🟢 Starting monthly progress timer');
          _startProgressTimer();
        } else {
          print('🔴 Stopping progress timer');
          _stopProgressTimer();
        }
      });
    }
  }

  void _startProgressTimer({bool force = false}) {
    // Don't start timer if it's already expired (unless forced)
    if (_timerExpired && !force) {
      print('⏰ Timer already expired, staying at 0:00');
      _remainingSeconds = 0;
      _progressValue = 0.0;
      setState(() {});
      return;
    }

    _stopProgressTimer(); // Stop any existing timer

    // If forcing start, ensure we have time remaining
    if (force && _remainingSeconds <= 0) {
      _remainingSeconds = 180; // Reset to 3 minutes
      _progressValue = 1.0;
      print('🔄 Force starting timer with 3:00');
    }

    // Update UI immediately to show initial state
    setState(() {});

    _progressTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        // Progress reduces as time remaining decreases
        _progressValue = _remainingSeconds / 180.0; // 180s = 1.0, 0s = 0.0

        print(
            '⏰ Timer: ${_formatTime(_remainingSeconds)} | Progress: ${(_progressValue * 100).toStringAsFixed(1)}%');

        if (_remainingSeconds <= 0) {
          _progressValue = 0.0; // Ensure it ends at 0
          _stopProgressTimer();

          // Set timer expired state immediately for dialog check
          _timerExpired = true;

          // Save expired state and show dialog (non-blocking)
          _saveTimerExpiredState().then((_) {
            _showTrialLimitDialogOncePerDay();
          });
        }
      });
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> _showTrialLimitDialogOncePerDay() async {
    // Check all required conditions first
    if (_isSubscribed) {
      print('🚫 User is subscribed, skipping trial limit dialog');
      return;
    }

    if (isPurchased) {
      print('🚫 User has purchased, skipping trial limit dialog');
      return;
    }

    if (!_is3DaysPassed) {
      print(
          '🚫 7-day trial period not passed yet, skipping trial limit dialog');
      return;
    }

    if (!_timerExpired) {
      print('🚫 Timer not expired yet, skipping trial limit dialog');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final lastShownString = prefs.getString('last_trial_dialog_shown');

    // Check if dialog was already shown today
    if (lastShownString == todayString) {
      print('🚫 Trial limit dialog already shown today, skipping...');
      return;
    }

    // All conditions met - save today's date and show the dialog
    await prefs.setString('last_trial_dialog_shown', todayString);
    _lastDialogShownDate = today;

    print(
        '✅ All conditions met - showing trial limit dialog for today: $todayString');
    print('   - Timer expired: $_timerExpired');
    print('   - 3 days passed: $_is3DaysPassed');
    print('   - Not subscribed: ${!_isSubscribed}');
    print('   - Not purchased: ${!isPurchased}');

    // Show the custom timer expired dialog
    if (mounted) {
      _showTimerExpiredDialog();
    }
  }

  void _showTimerExpiredDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.timer_off,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.freeTimeExpired,
                  style: FlutterFlowTheme.of(context).displayMedium.override(
                        fontFamily: 'Poppins',
                        color: Color(0xFF173F5A),
                        fontSize: 18.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.freeTimeWillResetNextMonth,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF173F5A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.premiumForever,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF173F5A),
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      t.unlimitedScanning,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Poppins',
                            fontSize: 13.0,
                            letterSpacing: 0.0,
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                t.later,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Navigate to subscription page
                await context.pushNamed(
                  'subscribe',
                  extra: {
                    'isSubscribed': _isSubscribed.toString(),
                  },
                );

                // After returning from the subscription page, check status
                await checkSubscriptionStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF173F5A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t.upgradeNow,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndShowStillEnjoyingDialog() async {
    // Only show if user is not subscribed and hasn't purchased
    if (_isSubscribed || isPurchased) {
      return;
    }

    // Get first open date from service
    final firstOpenDateString = await service.getFirstOpenDate();

    if (firstOpenDateString == null) {
      return;
    }

    // Parse the date string
    DateTime firstOpenDate;
    try {
      firstOpenDate = DateTime.parse(firstOpenDateString);
    } catch (e) {
      print('Error parsing first open date: $e');
      return;
    }

    final now = DateTime.now();
    final daysSinceFirstOpen = now.difference(firstOpenDate).inDays;

    // Show on day 2 or day 4
    if (daysSinceFirstOpen != 2 && daysSinceFirstOpen != 4) {
      return;
    }

    // Check if dialog was already shown today
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    final lastShownString = prefs.getString('last_enjoying_dialog_shown');

    if (lastShownString == todayString) {
      print('🚫 Still enjoying dialog already shown today, skipping...');
      return;
    }

    // Save today's date and show the dialog
    await prefs.setString('last_enjoying_dialog_shown', todayString);

    print('✅ Showing still enjoying dialog for day $daysSinceFirstOpen');

    if (mounted) {
      _showStillEnjoyingDialog();
    }
  }

  void _showStillEnjoyingDialog() {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              t.stillEnjoyingIt,
              style: FlutterFlowTheme.of(context).displayMedium.override(
                    fontFamily: 'Poppins',
                    color: Color(0xFF173F5A),
                    fontSize: 18.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          content: Text(
            t.stillEnjoyingItMessage,
            style: FlutterFlowTheme.of(context).bodyMedium.override(
                  fontFamily: 'Poppins',
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                t.later,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Navigate to subscription page
                await context.pushNamed(
                  'subscribe',
                  extra: {
                    'isSubscribed': _isSubscribed.toString(),
                  },
                );

                // After returning from the subscription page, check status
                await checkSubscriptionStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF173F5A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t.upgradeNow,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getProgressBarTitle() {
    final t = AppLocalizations.of(context)!;
    if (_timerExpired) {
      return t.readyToUnlockUnlimitedPower;
    } else if (_isSubscribed && !isPurchased) {
      return t.subscriptionTimeRemaining;
    } else if (!_is3DaysPassed) {
      return t.freeTrialTimeRemaining;
    } else {
      return t.trialTimeRemaining;
    }
  }

  void onPurchaseCompleted() {
    // Called when user completes purchase
    setState(() {
      isPurchased = true;
      _showProgressBar = false;
    });
    _stopProgressTimer();
  }

  // TESTING METHODS - Remove these in production
  void _testProgressBarScenarios() {
    print('🧪 Testing Progress Bar Scenarios:');

    // Test Scenario 1: New user (< 7 days, not subscribed, not purchased)
    print('Scenario 1: New user');
    _testScenario(
        isSubscribed: false, isPurchased: false, is7DaysPassed: false);

    // Test Scenario 2: Subscribed user without purchase
    print('Scenario 2: Subscribed user without purchase');
    _testScenario(isSubscribed: true, isPurchased: false, is7DaysPassed: true);

    // Test Scenario 3: Purchased user (should not show)
    print('Scenario 3: Purchased user');
    _testScenario(isSubscribed: true, isPurchased: true, is7DaysPassed: true);
  }

  void _testScenario(
      {required bool isSubscribed,
      required bool isPurchased,
      required bool is7DaysPassed}) {
    setState(() {
      _isSubscribed = isSubscribed;
      this.isPurchased = isPurchased;
      _is3DaysPassed = is7DaysPassed;
    });
    _updateProgressBarVisibility();
  }

  @override
  void dispose() {
    _stopProgressTimer();
    _model.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final t = AppLocalizations.of(context)!;

    print("Current locale in scanner: ${provider.locale.languageCode}");
    print("Mode text: ${t.mode}");
    print("AppLocalizations locale: ${t.localeName}");

    // Force rebuild with the correct locale
    Locale currentLocale = Localizations.localeOf(context);
    print("Localizations.localeOf: $currentLocale");

    // Print all available translations for debugging
    print("PDF text: ${t.pdf}");
    print("Photo text: ${t.photo}");
    print("How to use text: ${t.howToUseISpeedScan}");

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: PopScope(
        canPop: !_shouldBlockNavigation(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _shouldBlockNavigation()) {
            print('🚫 Navigation blocked - trial expired and timer ended');
            // Optionally show a message to the user
            _showTrialLimitDialogOncePerDay();
          }
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          appBar: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).primary,
            automaticallyImplyLeading: !_shouldBlockNavigation(),
            leading: _shouldBlockNavigation()
                ? null
                : IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (!_shouldBlockNavigation()) {
                        Navigator.pop(context);
                      }
                    },
                  ),
            title: Text(
              valueOrDefault<String>(
                _model.teststCopy,
                'iSpeedScan',
              ),
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    fontSize: 22.0,
                    letterSpacing: 0.0,
                  ),
            ),
            actions: const [],
            centerTitle: true,
            elevation: 2.0,
          ),
          body: SafeArea(
            top: true,
            child: (animationsMap.isEmpty)
                ? Container()
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.safePop();
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 90.0,
                                      height: 90.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .accent2,
                                        image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: Image.asset(
                                            'assets/images/qslogo_copy.png',
                                          ).image,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: FlutterFlowTheme.of(context)
                                              .secondary,
                                          width: 2.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  await requestPermission(cameraPermission);

                                  if (!_isSubscribed &&
                                      _is3DaysPassed &&
                                      _totalUsageMinutes > 3 * 60) {
                                    print('days passed $_is3DaysPassed');
                                    print('😂$_totalUsageMinutes');
                                    await analytics.logEvent(
                                      name: 'event_on_trial_limit_reached',
                                      parameters: {
                                        'os': Platform.isAndroid
                                            ? 'android'
                                            : 'ios',
                                        'photoMode':
                                            isPhotoMode! ? "true" : "false",
                                        'timestamp':
                                            DateTime.now().toIso8601String(),
                                      },
                                    );
                                    showTrialLimitDialog(context);

                                    return;
                                  }

                                  await analytics.logEvent(
                                    name: 'event_on_scanner_button_pressed',
                                    parameters: {
                                      'os': Platform.isAndroid
                                          ? 'android'
                                          : 'ios',
                                      'timestamp':
                                          DateTime.now().toIso8601String(),
                                      'photoMode':
                                          isPhotoMode! ? "true" : "false",
                                    },
                                  );
                                  try {
                                    var images = await actions.scannerAction(
                                      context,
                                    );
                                    checkPdfCreation(images);
                                  } catch (e) {
                                    // showErrorAlert(context, 'Error2',
                                    //     ' Error while picking images${e}');
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    'assets/images/return_copy.png',
                                    width: 300.0,
                                    height: 142.0,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ).animateOnPageLoad(
                                  animationsMap['imageOnPageLoadAnimation']!),
                              FFButtonWidget(
                                onPressed: () async {
                                  await requestPermission(cameraPermission);

                                  if (!_isSubscribed &&
                                      _is3DaysPassed &&
                                      _totalUsageMinutes > 3 * 60) {
                                    print('days passed $_is3DaysPassed');
                                    await analytics.logEvent(
                                      name: 'event_on_trial_limit_reached',
                                      parameters: {
                                        'os': Platform.isAndroid
                                            ? 'android'
                                            : 'ios',
                                        'photoMode':
                                            isPhotoMode! ? "true" : "false",
                                        'timestamp':
                                            DateTime.now().toIso8601String(),
                                      },
                                    );
                                    showTrialLimitDialog(context);

                                    return;
                                  }
                                  try {
                                    await analytics.logEvent(
                                      name: 'event_on_scanner_button_pressed',
                                      parameters: {
                                        'os': Platform.isAndroid
                                            ? 'android'
                                            : 'ios',
                                        'photoMode':
                                            isPhotoMode! ? "true" : "false",
                                        'timestamp':
                                            DateTime.now().toIso8601String(),
                                      },
                                    );
                                    var images = await actions.scannerAction(
                                      context,
                                    );
                                    checkPdfCreation(images);
                                  } catch (e) {
                                    // showErrorAlert(context, 'Error3',
                                    //     ' Error while picking images${e}');
                                  }

                                  safeSetState(() {});
                                },
                                text: '',
                                options: FFButtonOptions(
                                  height: 4.0,
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      24.0, 0.0, 24.0, 0.0),
                                  iconPadding:
                                      const EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 0.0),
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Readex Pro',
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                      ),
                                  elevation: 3.0,
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 20.0, 0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 1.0, 0.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 3.0,
                                        color: Color(0x33000000),
                                        offset: Offset(
                                          0.0,
                                          1.0,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              // Progress bar for subscribed but not purchased users
                              if (_showProgressBar)
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16.0, 12.0, 16.0, 8.0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 5.0,
                                          color: Color(0x3416202A),
                                          offset: Offset(0.0, 2.0),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: Color(0xFF173F5A),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _getProgressBarTitle(),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14.0,
                                                    // maxLines: 3,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF173F5A),
                                                    // maxLines: 2,
                                                  ),
                                              maxLines: 2,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _formatTime(_remainingSeconds),
                                                maxLines: 1,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 14.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: _remainingSeconds <=
                                                                  50
                                                              ? Colors.red
                                                              : _remainingSeconds <=
                                                                      90
                                                                  ? Colors
                                                                      .orange
                                                                  : Color(
                                                                      0xFF173F5A),
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8.0),
                                        LinearProgressIndicator(
                                          value: _progressValue,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _remainingSeconds <= 50
                                                ? Colors.red
                                                : _remainingSeconds <= 90
                                                    ? Colors.orange
                                                    : Color(0xFF173F5A),
                                          ),
                                          minHeight: 6.0,
                                        ),
                                        SizedBox(height: 8.0),
                                        // Show motivating message when timer expired or almost expired
                                        if (_timerExpired) ...[
                                          Text(
                                            t.timesUpButYourJourneyContinues,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange[700],
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 4.0),
                                          Text(
                                            t.upgradeToUnlimitedScanning,
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 11.0,
                                                  color: Colors.grey[700],
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ] else if (_remainingSeconds <= 50) ...[
                                          Text(
                                            t.finalCountdown,
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 13.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 4.0),
                                          Text(
                                            t.dontLetProductivityStop,
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 11.0,
                                                  color: Colors.red[700],
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                        // Show buttons when timer expired or almost expired
                                        if (_timerExpired ||
                                            _remainingSeconds <= 50) ...[
                                          SizedBox(height: 12.0),
                                          // Two buttons in a row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    // Navigate to subscription page
                                                    await context.pushNamed(
                                                      'subscribe',
                                                      extra: {
                                                        'isSubscribed':
                                                            _isSubscribed
                                                                .toString(),
                                                      },
                                                    );

                                                    // After returning from the subscription page, check status
                                                    await checkSubscriptionStatus();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16.0,
                                                            vertical: 12.0),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    elevation: 2.0,
                                                  ),
                                                  child: Text(
                                                    t.subscribeNow,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 13.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              // SizedBox(width: 8.0),
                                              // Expanded(
                                              //   child: ElevatedButton(
                                              //     onPressed: () {
                                              //       // Navigate to purchase page
                                              //       context.pushNamed(
                                              //           'PurchasePage');
                                              //     },
                                              //     style: ElevatedButton.styleFrom(
                                              //       backgroundColor:
                                              //           Colors.red[700],
                                              //       foregroundColor: Colors.white,
                                              //       padding: EdgeInsets.symmetric(
                                              //           horizontal: 16.0,
                                              //           vertical: 12.0),
                                              //       shape: RoundedRectangleBorder(
                                              //         borderRadius:
                                              //             BorderRadius.circular(
                                              //                 8.0),
                                              //       ),
                                              //       elevation: 2.0,
                                              //     ),
                                              //     child: Text(
                                              //       t.upgradeNow,
                                              //       style: FlutterFlowTheme.of(
                                              //               context)
                                              //           .bodyMedium
                                              //           .override(
                                              //             fontFamily: 'Poppins',
                                              //             fontSize: 13.0,
                                              //             fontWeight:
                                              //                 FontWeight.w600,
                                              //             color: Colors.white,
                                              //           ),
                                              //     ),
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          // Reset Timer Button
                                          //   SizedBox(
                                          //     width: double.infinity,
                                          //     child: OutlinedButton(
                                          //       onPressed: () async {
                                          //         await _resetTimer();
                                          //       },
                                          //       style: OutlinedButton.styleFrom(
                                          //         foregroundColor: Colors.red,
                                          //         side: BorderSide(
                                          //             color: Colors.red,
                                          //             width: 1.5),
                                          //         padding: EdgeInsets.symmetric(
                                          //             horizontal: 16.0,
                                          //             vertical: 10.0),
                                          //         shape: RoundedRectangleBorder(
                                          //           borderRadius:
                                          //               BorderRadius.circular(8.0),
                                          //         ),
                                          //       ),
                                          //       child: Text(
                                          //         t.resetTimer,
                                          //         style:
                                          //             FlutterFlowTheme.of(context)
                                          //                 .bodyMedium
                                          //                 .override(
                                          //                   fontFamily: 'Poppins',
                                          //                   fontSize: 12.0,
                                          //                   fontWeight:
                                          //                       FontWeight.w500,
                                          //                   color: Colors.red,
                                          //                 ),
                                          //       ),
                                          //     ),
                                          //   ),
                                        ] else ...[
                                          Text(
                                            t.stillEnjoyingItMessage,
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12.0,
                                                  color: Colors.grey[600],
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 12.0),
                                          // Two buttons in a row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Expanded(
                                              //   child: ElevatedButton(
                                              //     onPressed: () async {
                                              //       // Navigate to subscription page
                                              //       await context.pushNamed(
                                              //         'subscribe',
                                              //         extra: {
                                              //           'isSubscribed':
                                              //               _isSubscribed
                                              //                   .toString(),
                                              //         },
                                              //       );

                                              //       // After returning from the subscription page, check status
                                              //       await checkSubscriptionStatus();
                                              //     },
                                              //     style: ElevatedButton.styleFrom(
                                              //       backgroundColor:
                                              //           Color(0xFF173F5A),
                                              //       foregroundColor: Colors.white,
                                              //       padding: EdgeInsets.symmetric(
                                              //           horizontal: 16.0,
                                              //           vertical: 12.0),
                                              //       shape: RoundedRectangleBorder(
                                              //         borderRadius:
                                              //             BorderRadius.circular(
                                              //                 8.0),
                                              //       ),
                                              //       elevation: 2.0,
                                              //     ),
                                              //     child: Text(
                                              //       t.subscribeNow,
                                              //       style: FlutterFlowTheme.of(
                                              //               context)
                                              //           .bodyMedium
                                              //           .override(
                                              //             fontFamily: 'Poppins',
                                              //             fontSize: 13.0,
                                              //             fontWeight:
                                              //                 FontWeight.w600,
                                              //             color: Colors.white,
                                              //           ),
                                              //     ),
                                              //   ),
                                              // ),
                                              // SizedBox(width: 8.0),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    // Navigate to subscription page
                                                    await context.pushNamed(
                                                      'subscribe',
                                                      extra: {
                                                        'isSubscribed':
                                                            _isSubscribed
                                                                .toString(),
                                                      },
                                                    );

                                                    // After returning from the subscription page, check status
                                                    await checkSubscriptionStatus();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color(0xFF2A5F7A),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 16.0,
                                                            vertical: 12.0),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    elevation: 2.0,
                                                  ),
                                                  child: Text(
                                                    t.upgradeNow,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 13.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              if (isPhotoMode != null)
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(16.0,
                                      _showProgressBar ? 4.0 : 12.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 60.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 5.0,
                                          color: Color(0x3416202A),
                                          offset: Offset(
                                            0.0,
                                            2.0,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12.0),
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                t.mode,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(t.pdf),
                                              Switch(
                                                value: isPhotoMode!,
                                                onChanged: (value) {
                                                  setState(() {
                                                    isPhotoMode = value;
                                                  });
                                                  _toggleMode(isPhotoMode!);
                                                },
                                                activeColor: Colors.blue,
                                                inactiveThumbColor: Colors.grey,
                                              ),
                                              Text(t.photo),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'rowOnPageLoadAnimation1']!),
                                  ),
                                ),
                              if (isPhotoMode != null &&
                                  !isPhotoMode! &&
                                  Platform.isAndroid)
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16.0, 12.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 60.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 5.0,
                                          color: Color(0x3416202A),
                                          offset: Offset(
                                            0.0,
                                            2.0,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12.0),
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          // context.pushNamed('howto');
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        12.0, 0.0, 0.0, 0.0),
                                                child: Text(
                                                  t.pdfQuality,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLarge
                                                      .override(
                                                        fontFamily:
                                                            'Readex Pro',
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: selectedValue,
                                                // dropdownColor: Colors.transparent,
                                                // No background
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16),
                                                // Text styling
                                                items: [t.low, t.medium, t.high]
                                                    .map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(
                                                      value,
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyLarge
                                                          .override(
                                                            fontFamily:
                                                                'Readex Pro',
                                                            letterSpacing: 0.0,
                                                          ),
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  setState(() {
                                                    selectedValue = newValue!;
                                                    PreferenceService
                                                        .saveQuality(newValue);
                                                  });
                                                },
                                              ),
                                            ),
                                            // Align(
                                            //   alignment:
                                            //       const AlignmentDirectional(0.9, 0.0),
                                            //   child: Icon(
                                            //     Icons.arrow_forward_ios,
                                            //     color: FlutterFlowTheme.of(context)
                                            //         .secondaryText,
                                            //     size: 18.0,
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      ).animateOnPageLoad(animationsMap[
                                          'rowOnPageLoadAnimation1']!),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 5.0,
                                        color: Color(0x3416202A),
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        context.pushNamed('howto');
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                t.howToUseISpeedScan,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.9, 0.0),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'rowOnPageLoadAnimation1']!),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 5.0,
                                        color: Color(0x3416202A),
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        context.pushNamed('simplicity');
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                t.simplicityAndEfficiency,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.9, 0.0),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'rowOnPageLoadAnimation2']!),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 5.0,
                                        color: Color(0x3416202A),
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        context.pushNamed('privacy');
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                t.privacyAndSecurity,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.9, 0.0),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'rowOnPageLoadAnimation3']!),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 5.0,
                                        color: Color(0x3416202A),
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        await analytics.logEvent(
                                          name: 'event_on_more_apps_clicked',
                                          parameters: {
                                            'os': Platform.isAndroid
                                                ? 'android'
                                                : 'ios',
                                            'photoMode':
                                                isPhotoMode! ? "true" : "false",
                                            'timestamp': DateTime.now()
                                                .toIso8601String(),
                                          },
                                        );
                                        context.pushNamed('more_apps');
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                t.moreAppsByTevinEighDesigns,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.9, 0.0),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'rowOnPageLoadAnimation3']!),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context.pushNamed('tevin');
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 60.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 5.0,
                                          color: Color(0x3416202A),
                                          offset: Offset(
                                            0.0,
                                            2.0,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(12.0),
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          context.pushNamed('tevin');
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(
                                                        12.0, 0.0, 0.0, 0.0),
                                                child: AutoSizeText(
                                                  t.aboutTevinEighDesigns,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLarge
                                                      .override(
                                                        fontFamily:
                                                            'Readex Pro',
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ],
                                        ),
                                      ).animateOnPageLoad(animationsMap[
                                          'rowOnPageLoadAnimation4']!),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    await context.pushNamed(
                                      'subscribe',
                                      extra: {
                                        'isSubscribed':
                                            _isSubscribed.toString(),
                                      },
                                    ).then((result) async {
                                      if (result != null && result is List) {
                                        // because you returned a list with one map
                                        final promoResult = result[0];
                                        final bool isPromoApplied =
                                            (promoResult['promoCodeApplied']
                                                    as bool?) ??
                                                false;

                                        print(
                                            'Promo code applied: $isPromoApplied');

                                        if (isPromoApplied) {
                                          final DateTime fiveDaysAgo =
                                              DateTime.now().subtract(
                                                  const Duration(days: 5));
                                          await service
                                              .checkAndSaveDate(fiveDaysAgo);
                                        }
                                      }
                                    });

                                    await checkSubscriptionStatus();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 60.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 5.0,
                                          color: Color(0x3416202A),
                                          offset: Offset(0.0, 2.0),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(12.0),
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                !_isSubscribed
                                                    ? '${t.lifeTimeSubsciption} \$1.99'
                                                    : t.viewPurchaseDetails,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.9, 0.0),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(
                                      animationsMap['rowOnPageLoadAnimation1']!,
                                    ),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 0.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 60.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 5.0,
                                        color: Color(0x3416202A),
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: InkWell(
                                      splashColor: Colors.transparent,
                                      focusColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () async {
                                        context.pushNamed('language');
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      12.0, 0.0, 0.0, 0.0),
                                              child: Text(
                                                t.languageAndTranslation,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .override(
                                                          fontFamily:
                                                              'Readex Pro',
                                                          letterSpacing: 0.0,
                                                        ),
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment:
                                                const AlignmentDirectional(
                                                    0.9, 0.0),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 18.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animateOnPageLoad(animationsMap[
                                        'rowOnPageLoadAnimation1']!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 20.0, 0.0, 0.0),
                            child: SafeArea(
                              child: Container(
                                width: 391.0,
                                height: 33.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).secondary,
                                ),
                                child: Align(
                                  alignment:
                                      const AlignmentDirectional(0.0, 0.0),
                                  child: Text(
                                    t.checkYourPhotoGalaryForYourSavedPhotos,
                                    textAlign: TextAlign.start,
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          fontSize: 11.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Debug button for checking trial conditions

                        // if (kDebugMode)
                        //   Padding(
                        //     padding: const EdgeInsetsDirectional.fromSTEB(
                        //         16.0, 12.0, 16.0, 0.0),
                        //     child: InkWell(
                        //       splashColor: Colors.transparent,
                        //       focusColor: Colors.transparent,
                        //       hoverColor: Colors.transparent,
                        //       highlightColor: Colors.transparent,
                        //       onTap: () async {
                        //         _showTrialStatusDialog();
                        //       },
                        //       child: Container(
                        //         width: double.infinity,
                        //         height: 60.0,
                        //         decoration: BoxDecoration(
                        //           color: FlutterFlowTheme.of(context)
                        //               .secondaryBackground,
                        //           boxShadow: const [
                        //             BoxShadow(
                        //               blurRadius: 5.0,
                        //               color: Color(0x3416202A),
                        //               offset: Offset(
                        //                 0.0,
                        //                 2.0,
                        //               ),
                        //             )
                        //           ],
                        //           borderRadius: BorderRadius.circular(12.0),
                        //           shape: BoxShape.rectangle,
                        //           border: Border.all(
                        //             color: Colors.orange,
                        //             width: 2.0,
                        //           ),
                        //         ),
                        //         child: Padding(
                        //           padding: const EdgeInsets.all(8.0),
                        //           child: Row(
                        //             mainAxisSize: MainAxisSize.max,
                        //             children: [
                        //               Icon(
                        //                 Icons.bug_report,
                        //                 color: Colors.orange,
                        //                 size: 24.0,
                        //               ),
                        //               Expanded(
                        //                 child: Padding(
                        //                   padding: const EdgeInsetsDirectional
                        //                       .fromSTEB(12.0, 0.0, 0.0, 0.0),
                        //                   child: Text(
                        //                     'Check Trial Status (Debug)',
                        //                     style: FlutterFlowTheme.of(context)
                        //                         .bodyLarge
                        //                         .override(
                        //                           fontFamily: 'Readex Pro',
                        //                           color: Colors.orange,
                        //                           letterSpacing: 0.0,
                        //                           fontWeight: FontWeight.w600,
                        //                         ),
                        //                   ),
                        //                 ),
                        //               ),
                        //               Align(
                        //                 alignment: const AlignmentDirectional(
                        //                     0.9, 0.0),
                        //                 child: Icon(
                        //                   Icons.info_outline,
                        //                   color: Colors.orange,
                        //                   size: 18.0,
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),

                        // // // TESTING BUTTONS - Remove in production
                        //   if (kDebugMode) ...[
                        //     SizedBox(height: 16),
                        //     Container(
                        //       margin: EdgeInsets.symmetric(horizontal: 16),
                        //       padding: EdgeInsets.all(12),
                        //       decoration: BoxDecoration(
                        //         color: Colors.red[50],
                        //         border: Border.all(color: Colors.red[200]!),
                        //         borderRadius: BorderRadius.circular(8),
                        //       ),
                        //       child: Column(
                        //         crossAxisAlignment: CrossAxisAlignment.start,
                        //         children: [
                        //           Text(
                        //             '🧪 DEBUG TESTING BUTTONS',
                        //             style: TextStyle(
                        //               fontWeight: FontWeight.bold,
                        //               color: Colors.red[700],
                        //               fontSize: 12,
                        //             ),
                        //           ),
                        //           SizedBox(height: 8),
                        //           Wrap(
                        //             spacing: 8,
                        //             runSpacing: 4,
                        //             children: [
                        //               ElevatedButton(
                        //                 onPressed: _testBypass7DayTrial,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.orange,
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Bypass 7-Day Trial',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: _testReset3MinTimer,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.blue,
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Reset 3-Min Timer',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: _testReset30DayTimer,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.purple,
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Reset 30-Day Timer',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: _testShowDay2Dialog,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.green,
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Show Day 2 Dialog',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: _testShowDay4Dialog,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.teal,
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Show Day 4 Dialog',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: _testShowTrialLimitDialog,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.red,
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Show Trial Limit Dialog',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: _debugDialogConditions,
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.purple[700],
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Debug Dialog Conditions',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //               ElevatedButton(
                        //                 onPressed: () {
                        //                   print(
                        //                       '🧪 TESTING: Navigation block status');
                        //                   print(
                        //                       '   - Should block: ${_shouldBlockNavigation()}');
                        //                   if (_shouldBlockNavigation()) {
                        //                     print(
                        //                         '   - ❌ Navigation is ${t.blocked}');
                        //                     ScaffoldMessenger.of(context)
                        //                         .showSnackBar(
                        //                       SnackBar(
                        //                         content:
                        //                             Text(t.navigationBlocked),
                        //                         backgroundColor: Colors.red,
                        //                       ),
                        //                     );
                        //                   } else {
                        //                     print(
                        //                         '   - ✅ Navigation is ${t.allowed}');
                        //                     ScaffoldMessenger.of(context)
                        //                         .showSnackBar(
                        //                       SnackBar(
                        //                         content:
                        //                             Text(t.navigationAllowed),
                        //                         backgroundColor: Colors.green,
                        //                       ),
                        //                     );
                        //                   }
                        //                 },
                        //                 style: ElevatedButton.styleFrom(
                        //                   backgroundColor: Colors.orange[700],
                        //                   foregroundColor: Colors.white,
                        //                   padding: EdgeInsets.symmetric(
                        //                       horizontal: 8, vertical: 4),
                        //                 ),
                        //                 child: Text('Test Navigation Block',
                        //                     style: TextStyle(fontSize: 10)),
                        //               ),
                        //             ],
                        //           ),
                        //         ],
                        //       ),
                        //     ),
                        //   ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _toggleMode(bool value) {
    PreferenceService.saveMode(value); // Save the state
  }

  Future<void> _loadMode() async {
    // final stopwatch = Stopwatch()..start();

    _model = createModel(context, () => ScannerModel());

    // Run subscription check and preferences loading in parallel
    try {
      setState(() async {
        isPhotoMode = await PreferenceService.getMode();
        selectedValue = await PreferenceService.getPDFQuality();
      });
    } catch (e) {}

    await performInitState();
    // stopwatch.stop();

    await checkSubscriptionStatus();

    // Check and show still enjoying dialog on days 2 and 4
    await _checkAndShowStillEnjoyingDialog();

    // print(
    // '⏱️ _loadMode execution completed in ✅ ${stopwatch.elapsedMilliseconds}ms');

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await requestPermission(cameraPermission);

      if (!_isSubscribed && _is3DaysPassed && _totalUsageMinutes > 3 * 60) {
        print('days passed $_is3DaysPassed');
        print('😂$_totalUsageMinutes');

        await analytics.logEvent(
          name: 'event_on_trial_limit_reached',
          parameters: {
            'os': Platform.isAndroid ? 'android' : 'ios',
            'photoMode': isPhotoMode! ? "true" : "false",
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        showTrialLimitDialog(context);
        return;
      }

      try {
        await analytics.logEvent(
          name: 'event_on_scanner_opened',
          parameters: {
            'os': Platform.isAndroid ? 'android' : 'ios',
            'photoMode': isPhotoMode! ? "true" : "false",
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        var images = await actions.scannerAction(context);
        checkPdfCreation(images);
      } catch (e) {
        // showErrorAlert(context, 'Error1', ' Error while picking images${e}');
      }
    });
  }

  Future<void> performInitState() async {
    animationsMap.addAll({
      'imageOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(-100.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'rowOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'rowOnPageLoadAnimation4': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    // Delay the rate dialog to ensure context is ready
    Future.delayed(Duration(seconds: 4), () {
      initRateMyApp();
    });
  }

  Future<void> checkPdfCreation(List<String> images) async {
    if (images.isEmpty) {
      // showErrorAlert(context, 'Error', 'Empty Images');
      return;
    }

    final time = DateTime.now(); // Format: MM.dd.yy_h.mmAM/PM

    String formattedDate = DateFormat('MM.dd.yy_h.mma').format(time);

    String name = 'iSpeedScan_$formattedDate.pdf';

    isPhotoMode = await PreferenceService.getMode();

    if (!isPhotoMode!) {
      LoadingDialog.show(context);

      List<File> imageFiles = [];

      List<Uint8List> imageBytesList = [];
      //
      for (String picturePath in images) {
        File imageFile = File(picturePath);

        imageFiles.add(imageFile); // Store as File

        Uint8List bytes = await imageFile.readAsBytes();

        imageBytesList.add(bytes); // Store as Uint8List
      }

      final fileupList = imageBytesList.map((bytes) {
        return SerializableFile(bytes, name)
            .toMap(); // Replace '' with appropriate filename if needed
      }).toList();

      final params = PdfMultiImgParams(
          fileupList: fileupList,
          filename: name,
          selectedIndex: 0,
          selectedValue:
              selectedValue); // Get the index of the selected orientation

      var pdf2 = await pdfMultiImgWithIsolate(params);
      if (pdf2.bytes == null) {
        // showErrorAlert(context, 'Error', 'PDF Creation Error');
      }
      LoadingDialog.hide(context);
      saveAndSharePdf(pdf2.bytes!, name);
      await analytics.logEvent(
        name: 'event_on_pdf_created_and_saved',
        parameters: {
          'os': Platform.isAndroid ? 'android' : 'ios',
          'photoMode': isPhotoMode! ? "true" : "false",
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> saveAndSharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      late String filePath;

      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        filePath = '${directory.path}/$fileName';
      } else if (Platform.isIOS) {
        final directory = await getTemporaryDirectory();
        filePath = '${directory.path}/$fileName';
      }

      // Write the PDF bytes to the file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('🟢 PDF saved to: $filePath');

      if (Platform.isAndroid) {
        var newPath = filePath.replaceAll('temp', '');

        // await PdfCompressor.compressPdfFile(
        //     filePath, newPath, CompressQuality.HIGH);
        // return outputPath;
        // var thumbnailPath = await generatePdfThumbnail(filePath);

        // final xThumbnail = XFile(thumbnailPath);

        final xFile = XFile(filePath);

        await Share.shareXFiles([xFile], subject: '$fileName');

        return;
      }

      // For iOS, check if it's an iPad
      if (Platform.isIOS) {
        final bool isIpad = await _isIpad();
        if (isIpad) {
          // Use native iOS sharing for iPad
          try {
            LogHelper.logMessage(
                'iPad Sharing', 'Attempting to share file at path: $filePath');

            // Ensure the file exists and is readable
            final file = File(filePath);
            if (!await file.exists()) {
              LogHelper.logErrorMessage(
                  'iPad Sharing', 'File does not exist at path: $filePath');
              throw Exception('File does not exist');
            }

            // Move file to Documents directory for better iOS compatibility
            final documentsDir = await getApplicationDocumentsDirectory();
            final newFilePath = '${documentsDir.path}/$fileName';
            await file.copy(newFilePath);

            LogHelper.logMessage(
                'iPad Sharing', 'File copied to: $newFilePath');

            final MethodChannel platform =
                MethodChannel('com.ispeedscan/share');
            final bool result = await platform.invokeMethod('shareFileOnIpad', {
              'filePath': newFilePath,
              'mimeType': 'application/pdf',
              'fileName': fileName,
            });
            if (!result) {
              LogHelper.logErrorMessage(
                  'iPad Sharing', 'Share menu presentation failed');
              throw Exception('Failed to share on iPad');
            }
            LogHelper.logSuccessMessage(
                'iPad Sharing', 'File shared successfully');
          } on PlatformException catch (e) {
            print('Error sharing on iPad: ${e.message}');
            throw Exception('Failed to share on iPad: ${e.message}');
          }
        } else {
          // Regular iOS sharing for iPhone
          final xFile = XFile(filePath);
          await Share.shareXFiles([xFile], subject: fileName);
        }
      }

      print('File saved and ready to share.');
    } catch (e) {
      print('Error saving or sharing PDF: $e');
    }
  }

  Future<bool> _isIpad() async {
    if (!Platform.isIOS) return false;
    final deviceInfo = await DeviceInfoPlugin().iosInfo;
    return deviceInfo.model.toLowerCase().contains('ipad');
  }

  // Future<String> generatePdfThumbnail(String pdfPath) async {
  //   // Open the PDF and render the first page
  //   final document = await PdfDocument.openFile(pdfPath);
  //   final page = await document.getPage(1);

  //   // Render the page as an image (adjust width and height for quality)
  //   final image = await page.render(width: 1920, height: 1090);

  //   // Save the rendered image as a temporary file
  //   final directory = Directory('/storage/emulated/0/Download');
  //   final thumbnailPath = '${directory.path}/thumbnail.png';
  //   final thumbnailFile = File(thumbnailPath);
  //   await thumbnailFile.writeAsBytes(image!.bytes);

  //   return thumbnailPath;
  // }

  void _showTrialStatusDialog() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Calculate days since first open
        DateTime? firstOpenDate;
        try {
          // This would need to be implemented to get the actual first open date
          // For now, we'll show the current values
        } catch (e) {
          // Handle error
        }

        // Calculate usage in minutes for display
        double usageMinutes = _totalUsageMinutes / 60.0;

        // Determine trial status
        String trialStatus;
        String accessStatus;

        if (_isSubscribed) {
          trialStatus = t.subscribed;
          accessStatus = t.unlimitedAccess;
        } else if (!_is3DaysPassed) {
          trialStatus = t.freeTrialActive;
          accessStatus = t.unlimitedScanningAccess;
        } else if (_totalUsageMinutes <= 3 * 60) {
          trialStatus = t.monthlyAllowance;
          accessStatus = t.scanningAvailable;
        } else {
          trialStatus = t.trialExpired;
          accessStatus = t.scanningBlocked;
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              t.trialStatusDebug,
              style: FlutterFlowTheme.of(context).displayMedium.override(
                    fontFamily: 'Poppins',
                    color: Color(0xFF173F5A),
                    fontSize: 16.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${t.status} $trialStatus",
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Poppins',
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: _isSubscribed
                          ? Colors.green
                          : (!_is3DaysPassed
                              ? Colors.blue
                              : (_totalUsageMinutes <= 3 * 60
                                  ? Colors.orange
                                  : Colors.red)),
                    ),
              ),
              SizedBox(height: 8),
              Text("Access: $accessStatus"),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Text("Debug Info:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("• Subscribed: $_isSubscribed"),
              Text("• 3 days passed: $_is3DaysPassed"),
              Text("• Usage Time: ${usageMinutes.toStringAsFixed(2)} minutes"),
              Text("• Usage Seconds: $_totalUsageMinutes seconds"),
              Text("• Limit: 180 seconds (3 minutes)"),
              SizedBox(height: 8),
              Text(
                "${t.logic} ${!_isSubscribed && _is3DaysPassed && _totalUsageMinutes > 3 * 60 ? t.blocked : t.allowed}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: (!_isSubscribed &&
                          _is3DaysPassed &&
                          _totalUsageMinutes > 3 * 60)
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.close),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Force refresh the trial status
                _loadUsageTime();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF173F5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                t.refresh,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> checkPreviousAppPurchase() async {
    if (!Platform.isIOS) {
      LogHelper.logMessage('Platform Check', 'Not iOS platform');
      return false;
    }

    try {
      final client = http.Client();

      // Try up to 3 times to get the receipt
      for (int i = 0; i < 2; i++) {
        try {
          final receipt = await const MethodChannel('app_store_receipt')
              .invokeMethod<String>('getReceipt');

          if (receipt != null) {
            // isPurchased = true;
            await analytics.logEvent(
              name: 'event_on_previous_purchase_found',
              parameters: {
                'os': Platform.isAndroid ? 'android' : 'ios',
                'photoMode': isPhotoMode! ? "true" : "false",
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
            setState(() {
              isPurchased = true;
              //todo uncomment it
              _isSubscribed = true;
            });
            await prefs?.setBool('is_subscribed', true);

            LogHelper.logMessage('Receipt Status', 'Receipt found on device');
            LogHelper.logMessage('Receipt Data',
                '${receipt.substring(0, min(50, receipt.length))}...');

            // First try production URL
            final prodResponse = await _verifyReceipt(receipt, false);
            if (prodResponse != null && prodResponse['status'] == 0) {
              setState(() {
                isPurchased = true;
                //todo uncomment it
                _isSubscribed = true;
              });
              await prefs?.setBool('is_subscribed', true);

              LogHelper.logSuccessMessage(
                  'Purchase Verification', 'Valid production receipt found');
              return true;
            }

            // If production fails, try sandbox
            final sandboxResponse = await _verifyReceipt(receipt, true);
            if (sandboxResponse != null && sandboxResponse['status'] == 0) {
              await prefs?.setBool('is_subscribed', true);

              LogHelper.logSuccessMessage(
                  'Purchase Verification', 'Valid sandbox receipt found');
              return true;
            }
          }

          LogHelper.logMessage(
              'Receipt Attempt', 'Attempt ${i + 1} failed, retrying...');
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          LogHelper.logErrorMessage('Receipt Fetch Error', e);
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      LogHelper.logErrorMessage(
          'Receipt Status', 'Failed to verify receipt after 3 attempts');
      return false;
    } catch (e) {
      LogHelper.logErrorMessage('Receipt Validation', e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> _verifyReceipt(
      String receipt, bool sandbox) async {
    try {
      // In debug mode, always try sandbox endpoint first
      final url = 'https://sandbox.itunes.apple.com/verifyReceipt';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'receipt-data': receipt,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      LogHelper.logErrorMessage('Receipt Verification Error', e);
    }
    return null;
  }

  checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        return false;
      }
    } catch (_) {
      return false;
    }
    return true;
  }
}

class LoadingDialog {
  static void show(BuildContext context, {String message = "Creating PDF..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(message, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context, {bool isImagePickerCalled = false}) {
    Navigator.of(context, rootNavigator: true).pop(); // Closes the dialog
  }
}

void showTrialLimitDialog(BuildContext context) {
  final t = AppLocalizations.of(context)!;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Center(
          child: Text(
            textAlign: TextAlign.center,
            t.freeTrialExpiredOrFeaturesExhausted,
            style: FlutterFlowTheme.of(context).displayMedium.override(
                  fontFamily: 'Poppins',
                  color: Color(0xFF173F5A),
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/premium.png',
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            Text(
              textAlign: TextAlign.justify,
              t.freeFeaturesRenewEvery30Days,
              // textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).displayMedium.override(
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 15.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: 10),
            Text(
              textAlign: TextAlign.justify,
              t.upgradeNowWithOneTimePurchase,
              // textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).displayMedium.override(
                    fontFamily: 'Poppins',
                    color: Color(0xFF173F5A),
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(t.cancel,
                style: FlutterFlowTheme.of(context).displayMedium.override(
                      fontFamily: 'Poppins',
                      color: Colors.black,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                    )),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to subscription page
              Navigator.pop(context);
              context.pushNamed('subscribe');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF173F5A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(t.upgradeNow,
                style: FlutterFlowTheme.of(context).displayMedium.override(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                    )),
          ),
        ],
      );
    },
  );
}
