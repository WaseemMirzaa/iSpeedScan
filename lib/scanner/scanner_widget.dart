import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:ispeedscan/services/app_store_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:share_plus/share_plus.dart';
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
export 'scanner_model.dart';

class ScannerWidget extends StatefulWidget {
  const ScannerWidget({super.key});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  DateTime? _sessionStartTime;
  int _totalUsageMinutes = 0;

  late ScannerModel _model;

  var service = PreferenceService();

  bool? isPhotoMode;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  String selectedValue = 'High';

  Offerings? offerings;
  bool _isSubscribed = true;
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  bool _is7DaysPassed = false;
  CustomerInfo? _customerInfo;

  @override
  void initState() {
    super.initState();

    _setPortraitMode();

    WidgetsBinding.instance.addObserver(this);
    _loadUsageTime();
    _checkFirstTimeOpen();
    _loadMode();
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
      
      LogHelper.logSuccessMessage('First time app open', 'Event logged successfully');
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

    int minutes = await PreferenceService.checkAndResetWeeklyUsage();
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
        _isSubscribed = true;
      });
      return;
    } else {
      if (!isPurchasedChecked) {
        await checkPreviousAppPurchase();
      }

      // if (_isSubscribed) return;
      await service.checkAndSaveDate();
      _is7DaysPassed = await service.isFirstOpenDateOlderThan7Days();

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
  }

  @override
  Future<void> _setPortraitMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> initRateMyApp() async {
    RateMyApp rateMyApp = RateMyApp(
      preferencesPrefix: 'rateMyApp_',
      minDays: 7,
      minLaunches: 7,
      remindDays: 7,
      remindLaunches: 10,
      googlePlayIdentifier: 'com.tevineighdesigns.ispeedscan1',
      appStoreIdentifier: '6627339270',
    );

    rateMyApp.init().then((_) {
      if (rateMyApp.shouldOpenDialog) {
        rateMyApp.showRateDialog(
          context,
          title: 'Rate this app', // The dialog title.
          message:
              'If you enjoy using this app, we’d really appreciate it if you could take a minute to leave a review! Your feedback helps us improve and won’t take more than a minute of your time.', // The dialog message.
          rateButton: 'RATE', // The dialog "rate" button text.
          noButton: 'NO THANKS', // The dialog "no" button text.
          laterButton: 'MAYBE LATER', // The dialog "later" button text.
          listener: (button) {
            // The button click listener (useful if you want to cancel the click event).
            switch (button) {
              case RateMyAppDialogButton.rate:
                print('Clicked on "Rate".');
                break;
              case RateMyAppDialogButton.later:
                print('Clicked on "Later".');
                break;
              case RateMyAppDialogButton.no:
                print('Clicked on "No".');
                break;
            }

            return true; // Return false if you want to cancel the click event.
          },
          ignoreNativeDialog:
              false, // Set to false if you want to show the Apple's native app rating dialog on iOS or Google's native app rating dialog (depends on the current Platform).
          dialogStyle: const DialogStyle(), // Custom dialog styles.
          onDismissed: () => rateMyApp.callEvent(RateMyAppEventType
              .laterButtonPressed), // Called when the user dismissed the dialog (either by taping outside or by pressing the "back" button).
          // contentBuilder: (co/ntext, defaultContent) => content, // This one allows you to change the default dialog content.
          // actionsBuilder: (context) => [], // This one allows you to use your own buttons.
        );
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          // automaticallyImplyLeading: false,
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
                                      color:
                                          FlutterFlowTheme.of(context).accent2,
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

                                if (_is7DaysPassed &&
                                    _totalUsageMinutes > 4 * 60 &&
                                    !_isSubscribed) {
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
                                  //todo add check for free 4 minutes scan
                                  showTrialLimitDialog(context);

                                  return;
                                }

                                await analytics.logEvent(
                                  name: 'event_on_scanner_button_pressed',
                                  parameters: {
                                    'os':
                                        Platform.isAndroid ? 'android' : 'ios',
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

                                if (_is7DaysPassed &&
                                    _totalUsageMinutes > 4 * 60 &&
                                    !_isSubscribed) {
                                  print('days passed $_is7DaysPassed');
                                  //todo add check for free 4 minutes scan
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
                            if (isPhotoMode != null)
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Mode: ',
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
                                            Text("PDF"),
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
                                            Text("Photo"),
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
                                                'PDF Quality',
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
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: selectedValue,
                                              // dropdownColor: Colors.transparent,
                                              // No background
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16),
                                              // Text styling
                                              items: ['Low', 'Medium', 'High']
                                                  .map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(
                                                    value,
                                                    style: FlutterFlowTheme.of(
                                                            context)
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
                                                  PreferenceService.saveQuality(
                                                      newValue);
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
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'How to Use iSpeedScan',
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
                                          alignment: const AlignmentDirectional(
                                              0.9, 0.0),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context)
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
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Simplicity and Efficiency',
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
                                          alignment: const AlignmentDirectional(
                                              0.9, 0.0),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context)
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
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'Privacy and Security',
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
                                          alignment: const AlignmentDirectional(
                                              0.9, 0.0),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context)
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
                                          'timestamp':
                                              DateTime.now().toIso8601String(),
                                        },
                                      );
                                      context.pushNamed('more_apps');
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              'More Apps By Tevin Eigh Designs',
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
                                          alignment: const AlignmentDirectional(
                                              0.9, 0.0),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context)
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
                                                'About Tevin Eigh Designs',
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
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context)
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
                                      'isSubscribed': _isSubscribed.toString(),
                                    },
                                  );

                                  // After returning from the subscription page, check status
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
                                            padding: const EdgeInsetsDirectional
                                                .fromSTEB(12.0, 0.0, 0.0, 0.0),
                                            child: Text(
                                              !_isSubscribed
                                                  ? 'Lifetime Subscription = \$4.99'
                                                  : 'View Purchase Details',
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
                                          alignment: const AlignmentDirectional(
                                              0.9, 0.0),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            color: FlutterFlowTheme.of(context)
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
                                alignment: const AlignmentDirectional(0.0, 0.0),
                                child: Text(
                                  'Check your Photo Gallery for your Saved Photo(s)',
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
                    ],
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

    // print(
    // '⏱️ _loadMode execution completed in ✅ ${stopwatch.elapsedMilliseconds}ms');

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await requestPermission(cameraPermission);

      IF(_isSubscribed) {
        analytics.logEvent(
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

      if (!_isSubscribed) {
        print('days passed $_is7DaysPassed');
        print('😂$_totalUsageMinutes');

        if (_is7DaysPassed && _totalUsageMinutes > 4 * 60 && !_isSubscribed) {
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

    initRateMyApp();
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

  Future<String> generatePdfThumbnail(String pdfPath) async {
    // Open the PDF and render the first page
    final document = await PdfDocument.openFile(pdfPath);
    final page = await document.getPage(1);

    // Render the page as an image (adjust width and height for quality)
    final image = await page.render(width: 1920, height: 1090);

    // Save the rendered image as a temporary file
    final directory = Directory('/storage/emulated/0/Download');
    final thumbnailPath = '${directory.path}/thumbnail.png';
    final thumbnailFile = File(thumbnailPath);
    await thumbnailFile.writeAsBytes(image!.bytes);

    return thumbnailPath;
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
            isPurchased = true;
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
            "FREE TRIAL EXPIRED or FREE FEATURES EXHAUSTED",
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
              "FREE FEATURES RENEW EVERY 7 DAYS",
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
              'UPGRADE NOW WITH A ONE TIME PURCHASE & UNLOCK THE FULL POWER OF iSpeedScan 🚀.',
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
            child: Text("Cancel",
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
            child: Text("Upgrade Now",
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
