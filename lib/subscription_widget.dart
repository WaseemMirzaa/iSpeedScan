import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
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

  Offerings? offerings;
  bool _isSubscribed = false;
  CustomerInfo? _customerInfo;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();

    try {
      getSubscriptionsData();
    } catch (e) {
      LogHelper.logMessage('Subscription Error', e);
    }

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

    // getSubscriptionsData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      safeSetState(() {});

      // Ensure that no text field is focused when the app startscf
      FocusScope.of(context).requestFocus(FocusNode());
    });
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
                                var offering = offerings
                                    ?.getOffering('sub_lifetime_ispeedscan');

                                if (offering != null) {
                                  try {
                                    var customerInfo =
                                        await Purchases.purchaseStoreProduct(
                                            offering.availablePackages[0]
                                                .storeProduct);

                                    getSubscriptionsData();

                                    LogHelper.logSuccessMessage(
                                        'Purchase Package', customerInfo);

                                    getSubscriptionsData();
                                  } catch (e) {
                                    LogHelper.logErrorMessage(
                                        'Subscription Purchase Error ', e);
                                  }

                                  // offering
                                }
                              },
                              text: '${t.purchaseNow} \$4.99',
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

  Future<void> getSubscriptionsData() async {
    prefs = await SharedPreferences.getInstance();

    final storedSubscriptionStatus = prefs!.getBool('is_subscribed') ?? false;

    _customerInfo = await Purchases.getCustomerInfo();

    offerings = await Purchases.getOfferings();

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
    } else {
      _isSubscribed = false;

      if (storedSubscriptionStatus == false) {
        checkPreviousAppPurchase();
      }
    }
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
