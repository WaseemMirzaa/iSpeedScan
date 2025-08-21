import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/services.dart';
import 'package:ispeedscan/helper/local_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../app_globals.dart';
import '../helper/log_helper.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ispeedscan/helper/local_provider.dart';

class SubscriptionWidget extends StatefulWidget {
  const SubscriptionWidget({super.key});

  @override
  State<SubscriptionWidget> createState() => _ConverterWidgetState();
}

class _ConverterWidgetState extends State<SubscriptionWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  SharedPreferences? prefs;

  var analytics = FirebaseAnalytics.instance;

  Offerings? offerings;
  bool _isSubscribed = false;
  CustomerInfo? _customerInfo;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();

    animationsMap.addAll({
      'textOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(3.0, 3.0),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
    });
    initSubscriptionScreenEvent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});

      // Ensure that no text field is focused when the app starts
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    // Check if isSubscribed parameter was passed through extra
    final routerState = GoRouterState.of(context);
    final extraMap = routerState.extra as Map<String, dynamic>?;

    if (extraMap != null && extraMap.containsKey('isSubscribed')) {
      setState(() {
        _isSubscribed = extraMap['isSubscribed'] as String == 'true';
        LogHelper.logSuccessMessage('isSubscribed', _isSubscribed.toString());
      });
    }

    if (!_isSubscribed) {
      try {
        getSubscriptionsData();
      } catch (e) {
        LogHelper.logMessage('Subscription Error', e);
      }
    } else {
      await analytics.logEvent(
        name: 'event_on_user_already_subscribed',
        parameters: {
          'screen': 'Subscription Screen',
          'os': Platform.isAndroid ? 'android' : 'ios',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<bool> checkPreviousAppPurchase() async {
    if (!Platform.isIOS) {
      LogHelper.logMessage('Platform Check', 'Not iOS platform');
      return false;
    }

    try {
      final client = http.Client();

      // Try up to 3 times to get the receipt
      for (int i = 0; i < 3; i++) {
        try {
          final receipt = await const MethodChannel('app_store_receipt')
              .invokeMethod<String>('getReceipt');

          if (receipt != null) {
            // isPurchased = true;
            await prefs?.setBool('is_subscribed', true);

            setState(() {
              // isPurchased = true;
              _isSubscribed = true;
            });
            LogHelper.logMessage('Receipt Status', 'Receipt found on device');
            LogHelper.logMessage('Receipt Data',
                '${receipt.substring(0, min(50, receipt.length))}...');

            // First try production URL
            final prodResponse = await _verifyReceipt(receipt, false);
            if (prodResponse != null && prodResponse['status'] == 0) {
              await prefs?.setBool('is_subscribed', true);

              setState(() {
                // isPurchased = true;
                _isSubscribed = true;
              });
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final t = AppLocalizations.of(context)!;
    Locale currentLocale = Localizations.localeOf(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF173F5A),
          automaticallyImplyLeading: true,
          actions: [
            // Only show restore button when:
            // 1. User is NOT currently subscribed (_isSubscribed is false)
            // 2. On iOS platform (since App Store handles restores differently)
          ],
          centerTitle: false,
          elevation: 2.0,
        ),
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 180.0,
                        height: 180.0,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/app_launcher_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                              // color: const Color(0xFF8ca9cf),
                              ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  // border: Border.all(color: borderColor, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _isSubscribed
                                          ? t.currentPlanFullAccess
                                          : t.currentPlanFreeTrail,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            fontFamily: 'Inter',
                                            color: _isSubscribed
                                                ? Color(0xFF173F5A)
                                                : Colors.black,
                                            fontSize: 18.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: RichText(
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  t.freeTailOneWeekUnlimitedUse,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                            ),
                                            TextSpan(
                                              text: t
                                                  .freeVersionAfterTrailExpires,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                            ),
                                            TextSpan(
                                              text: t
                                                  .fourMinutesOfFreeScanningWeekly,
                                              style: const TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                            TextSpan(
                                              text: t
                                                  .oneTimePurchaseUnlockFullAccess,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                            ),
                                            TextSpan(
                                              text: t
                                                  .unlimitedScansLifetimeAccess,
                                              style: TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),
                                            TextSpan(
                                              text: t
                                                  .getLifetimeAccessAndOtherDecs,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        fontFamily: 'Inter',
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                            ),
                                          ],
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14.0,
                                                  letterSpacing: 0.0,
                                                  color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    // Visibility(
                                    //   visible: _isSubscribed,
                                    //   child: Align(
                                    //     alignment: const AlignmentDirectional(0.0, 0.0),
                                    //     child: Padding(
                                    //       padding: const EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 0.0),
                                    //       child: FFButtonWidget(
                                    //         onPressed: () async {
                                    //           // _cancelSubscription();
                                    //           Navigator.of(context).pop();
                                    //         },
                                    //         text: 'Enjoy Your Full Access',
                                    //         options: FFButtonOptions(
                                    //           width: double.infinity,
                                    //           height: 50.0,
                                    //           padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                                    //           iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                    //           color:  Colors.green,
                                    //           textStyle: FlutterFlowTheme.of(context).titleLarge.override(
                                    //             fontFamily: 'Readex Pro',
                                    //             color: FlutterFlowTheme.of(context).info,
                                    //             fontSize: 18.0,
                                    //             letterSpacing: 0.0,
                                    //           ),
                                    //           elevation: 0.0,
                                    //           borderSide: const BorderSide(
                                    //             color: Colors.green,
                                    //             width: 2.0,
                                    //           ),
                                    //           borderRadius: BorderRadius.circular(8.0),
                                    //         ),
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Visibility(
                      //   visible: _isSubscribed,
                      //   child: Align(
                      //     alignment: const AlignmentDirectional(0.0, 0.0),
                      //     child: Padding(
                      //       padding: const EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 0.0),
                      //       child: FFButtonWidget(
                      //         onPressed: () async {
                      //           _cancelSubscription();
                      //         },
                      //         text: 'Cancel Subscription',
                      //         options: FFButtonOptions(
                      //           width: double.infinity,
                      //           height: 50.0,
                      //           padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      //           iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      //           color: const Color(0xFFD12323),
                      //           textStyle: FlutterFlowTheme.of(context).titleLarge.override(
                      //                 fontFamily: 'Readex Pro',
                      //                 color: FlutterFlowTheme.of(context).info,
                      //                 fontSize: 18.0,
                      //                 letterSpacing: 0.0,
                      //               ),
                      //           elevation: 0.0,
                      //           borderSide: const BorderSide(
                      //             color: Color(0xFFD12323),
                      //             width: 2.0,
                      //           ),
                      //           borderRadius: BorderRadius.circular(8.0),
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      Visibility(
                        visible: !_isSubscribed,
                        child: Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                8.0, 16.0, 8.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await analytics.logEvent(
                                  name:
                                      'event_on_purchase_subscription_button_pressed',
                                  parameters: {
                                    'screen': 'Subscription Screen',
                                    'os':
                                        Platform.isAndroid ? 'android' : 'ios',
                                    'timestamp':
                                        DateTime.now().toIso8601String(),
                                  },
                                );
                                var offering = offerings
                                    ?.getOffering('sub_lifetime_ispeedscan');

                                if (offering != null) {
                                  try {
                                    var customerInfo =
                                        await Purchases.purchaseStoreProduct(
                                            offering.availablePackages[0]
                                                .storeProduct);

                                    getSubscriptionsData(
                                        'event_on_subscription_purchased_successful');

                                    LogHelper.logSuccessMessage(
                                        'Purchase Package', customerInfo);

                                    // getSubscriptionsData();
                                  } catch (e) {
                                    LogHelper.logErrorMessage(
                                        'Subscription Purchase Error ', e);
                                  }

                                  // offering
                                }
                              },
                              text: '${t.purchaseNow} \$1.99',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 50.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                color: const Color(0xFF173F5A),
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context).info,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                    ),
                                elevation: 0.0,
                                borderSide: const BorderSide(
                                  color: Color(0xFF173F5A),
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (Platform.isIOS && !_isSubscribed)
                        Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                8.0, 8.0, 8.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                LoadingDialog.show(context,
                                    message: t.checkingActivePurchases);
                                try {
                                  await checkAndRestorePurchases();
                                  // await getSubscriptionsData();
                                } catch (_) {
                                  // LoadingDialog.hide(context);
                                }
                              },
                              text: t.alreadyPuchasedRestoreHere,
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 50.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                iconPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                color: const Color(0xFF173F5A),
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      fontFamily: 'Readex Pro',
                                      color: FlutterFlowTheme.of(context).info,
                                      fontSize: 18.0,
                                      letterSpacing: 0.0,
                                    ),
                                elevation: 0.0,
                                borderSide: const BorderSide(
                                  color: Color(0xFF173F5A),
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                          StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('app_settings')
                            .doc('promo_code')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox
                                .shrink(); // or a loader if you prefer
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final bool isEnabled = data['is_enabled'] ?? false;
                          final List<String> failureCodes =
                              List<String>.from(data['failure_codes'] ?? []);

                          if (!isEnabled) {
                            return const SizedBox.shrink();
                          }

                          return Visibility(
                            visible: !_isSubscribed,
                            child: Align(
                              alignment: const AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8.0, 16.0, 8.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    ShowPromoCodeDialog.show(
                                        context, t, failureCodes);
                                  },
                                  text: '${t.usePromoCode}',
                                  // 'Buy Now in 1.99\$'
                                  // ,
                                  options: FFButtonOptions(
                                    width: double.infinity,
                                    height: 50.0,
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            24.0, 0.0, 24.0, 0.0),
                                    iconPadding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 0.0),
                                    color: const Color(0xFF173F5A),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .override(
                                          fontFamily: 'Readex Pro',
                                          color:
                                              FlutterFlowTheme.of(context).info,
                                          fontSize: 18.0,
                                          letterSpacing: 0.0,
                                        ),
                                    elevation: 0.0,
                                    borderSide: const BorderSide(
                                      color: Color(0xFF173F5A),
                                      width: 2.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkAndRestorePurchases() async {
    try {
      _customerInfo = await Purchases.restorePurchases();

      // Check if restoration was successful by verifying entitlements
      final hasActiveEntitlement = _customerInfo
              ?.entitlements.all['sub_lifetime_ispeedscan']?.isActive ??
          false;

      LoadingDialog.hide(context);

      if (hasActiveEntitlement) {
        setState(() {
          _isSubscribed = true;
        });

        // Show success alert
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final t = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(t.success),
              content: Text(t.yourPurchaseHasBeenSuccessfullyRestored),
              actions: [
                TextButton(
                  child: Text(t.ok),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Show no purchases found alert
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final t = AppLocalizations.of(context)!;

            return AlertDialog(
              title: Text(t.noPurchasesFound),
              content: Text(t.weCouldntFindAnyPurchasesToRestore),
              actions: [
                TextButton(
                  child: Text(t.ok),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Show error alert
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final t = AppLocalizations.of(context)!;

          return AlertDialog(
            title: Text(t.error),
            content: Text(t.faildToRestorePurchasesPlzTryAgainLater),
            actions: [
              TextButton(
                child: Text(t.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      LogHelper.logErrorMessage('Restore Purchase Error', e);
    }
  }

  // Method to cancel the subscription
  Future<void> _cancelSubscription() async {
    // try {

    var hasActiveEntitlements =
        _customerInfo?.entitlements.active.isNotEmpty ?? false;

    if (hasActiveEntitlements) {
      await Purchases.setAttributes({'subscription_status': 'canceled'});

      print("Subscription marked as canceled.");

      // var activeEntitlement = _customerInfo!.entitlements.active[0];
      //
      // await _openSubscriptionManagementPage();
    }
  }

  // Open the subscription management page in the App Store
  Future<void> _openSubscriptionManagementPage() async {
    var url = "https://apps.apple.com/account/subscriptions";

    if (AppGlobals.subscriptionType == SubscriptionType.sandbox) {
      url = 'itms-apps://sandbox.itunes.apple.com/account/subscriptions';
    }

    print(LogHelper.logMessage('Url', url));

    if (await canLaunch(url)) {
      await launch(url);

      getSubscriptionsData();
    } else {
      print('Could not open the subscription management page.');
    }
  }

  Future<void> getSubscriptionsData([String? param]) async {
    prefs = await SharedPreferences.getInstance();

    final storedSubscriptionStatus = prefs!.getBool('is_subscribed') ?? false;

    _customerInfo = await Purchases.getCustomerInfo();

    offerings = await Purchases.getOfferings();

    var offering = offerings?.getOffering('sub_lifetime');

    LogHelper.logSuccessMessage('Customer Info', _customerInfo);

    LogHelper.logSuccessMessage('Offerings', offerings);

    if (_customerInfo?.entitlements.all['sub_lifetime_ispeedscan'] != null &&
        _customerInfo?.entitlements.all['sub_lifetime_ispeedscan']?.isActive ==
            true) {
      await prefs?.setBool('is_subscribed', true);

      // User has subscription, show them the feature
      setState(() {
        _isSubscribed = true;
      });
      if (param != null) {
        await analytics.logEvent(
          name: param!,
          parameters: {
            'price':
                offering?.availablePackages[0].storeProduct.price.toString(),
            'currencyCode':
                offering?.availablePackages[0].storeProduct.currencyCode,
            'screen': 'Subscription Screen',
            'os': Platform.isAndroid ? 'android' : 'ios',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await analytics.logEvent(
          name: 'event_on_subscription_already_purchased',
          parameters: {
            'screen': 'Subscription Screen',
            'os': Platform.isAndroid ? 'android' : 'ios',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } else {
      if (storedSubscriptionStatus == false && !_isSubscribed) {
        checkPreviousAppPurchase();
      }
    }
  }

  Future<void> initSubscriptionScreenEvent() async {
    await analytics.logEvent(
      name: 'event_on_subscription_screen_opened',
      parameters: {
        'os': Platform.isAndroid ? 'android' : 'ios',
        // 'photoMode': isPhotoMode! ? "true" : "false",
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

class LoadingDialog {
  static bool isShowing = false;
  static bool isImagePickerCalled = false;
  static bool isAlreadyCancelled = false;

  static void show(BuildContext context, {String? message}) {
    final t = AppLocalizations.of(context)!;
    final displayMessage = message ?? t.creatingPdf;

    if (isAlreadyCancelled) {
      isAlreadyCancelled = false;
      return;
    }

    isShowing = true;

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
                Text(displayMessage, style: const TextStyle(fontSize: 16)),
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

// Function to show an AlertDialog for permissions
void _showPermissionDialog(BuildContext context, String message,
    {bool openSettings = false}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final t = AppLocalizations.of(context)!;

      return AlertDialog(
        title: Text(t.permissionRequired),
        content: Text(message),
        actions: [
          TextButton(
            child: Text(t.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (openSettings)
            TextButton(
              child: Text(t.openSettings),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
        ],
      );
    },
  );
}



class ShowPromoCodeDialog {
  static Future<void> show(
    BuildContext context,
    AppLocalizations appLocalizations,
    List<String> failureCodes,
  ) async {
    final promoController = TextEditingController();
    String? errorText;

    // Brand color you shared for buttons/borders
    const brandColor = Color(0xFF173F5A);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              elevation: 8,
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              title: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, color: brandColor),
                  const SizedBox(width: 8),
                  // NOTE: cannot be const because it uses a localized string
                  Text(
                    appLocalizations.enterPromoCode,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: promoController,
                    autofocus: true,
                    style: const TextStyle(
                      color: brandColor,
                    ),
                    cursorColor: brandColor,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _validateAndApply(
                        context,
                        appLocalizations,
                        promoController.text,
                        setState,
                        (msg) => errorText = msg,
                        failureCodes),
                    decoration: InputDecoration(
                      labelText: appLocalizations.promoCode,
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: brandColor,
                      ),
                      // hintText: '000111',
                      // prefixIcon: const Icon(Icons.qr_code_2_rounded),
                      filled: true,

                      // Use themed borders; add a brand-colored focused border
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: brandColor,
                          width: 2,
                        ),
                      ),
                      errorText: errorText,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                // Cancel (outlined, on-surface-variant border)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.8),
                      width: 1.2,
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    appLocalizations.cancel,
                    style: theme.textTheme.labelLarge,
                  ),
                ),

                // Apply (elevated, brand color)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => _validateAndApply(
                    context,
                    appLocalizations,
                    promoController.text,
                    setState,
                    (msg) => errorText = msg,
                    failureCodes,
                  ),
                  child: Text(
                    appLocalizations.apply,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Validates the code and shows a SnackBar on success.
  static void _validateAndApply(
    BuildContext context,
    AppLocalizations loc,
    String input,
    void Function(void Function()) setState,
    void Function(String?) setError,
    List<String> failureCodes,
  ) {
    final code = input.trim();

    var valid = failureCodes.contains(code);
    if (valid) {
      Navigator.of(context).pop([
        // {"promoCodeApplied": true},
        // {"id": 2, "name": "Item 2"},
      ]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white),
              const SizedBox(width: 8),
              Text(
                loc.promoCodeAppliedSuccessfully,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pop([
        {"promoCodeApplied": true},
        // {"id": 2, "name": "Item 2"},
      ]);
    } else {
      setState(() {
        setError(loc.invalidPromoCode);
      });
    }
  }
}
