import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
class SubscriptionWidget extends StatefulWidget {
  const SubscriptionWidget({super.key});

  @override
  State<SubscriptionWidget> createState() => _ConverterWidgetState();
}

class _ConverterWidgetState extends State<SubscriptionWidget> with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

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

  @override
  void dispose() {
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
        appBar: AppBar(
          backgroundColor: Color(0xFF173F5A),
          automaticallyImplyLeading: true,

          actions: [
            if(_isSubscribed)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Align(
                alignment: const AlignmentDirectional(0.0, 0.0),
                child: GestureDetector(
                  child: Text(
                    'Restore Purchase',
                    style:  FlutterFlowTheme.of(context).displayMedium
                    .override(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 18.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                  ),
                  onTap: () {
                   
                    LoadingDialog.show(context, message: 'Checking Active Purchase');

                    checkAndRestorePurchases();

                    getSubscriptionsData();

                    LoadingDialog.hide(context);
                  },
                ),
              ),
            )
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
                                    Text( _isSubscribed ?
                                    'Current Plan : Full Access' : 'Current Plan : Free Trial',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                            fontFamily: 'Inter',
                                            color: _isSubscribed ? Color(0xFF173F5A) :Colors.black,
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
                                        textScaler: MediaQuery.of(context).textScaler,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'FREE TRIAL – 1 Week – Unlimited Use\n\n',
                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            TextSpan(
                                              text: 'FREE VERSION – After Trial Expires\n\n',
                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const TextSpan(
                                              text: ' ✔ 4 minutes of FREE scanning weekly\n\n',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),

                                            TextSpan(
                                              text: 'One Time Purchase (Unlock Full Access)',
                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const TextSpan(
                                              text: '\n\n ✔ Unlimited Scans, lifetime access',
                                              style: TextStyle(
                                                fontSize: 14.0,
                                              ),
                                            ),

                                            TextSpan(
                                              text: '\n\nGet lifetime access to iSpeedScan with a one-time purchase & unlock its full power today 🚀',
                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(fontFamily: 'Inter', fontSize: 14.0, letterSpacing: 0.0, color: Colors.black),
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
                            padding: const EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {

                                var offering = offerings?.getOffering('sub_lifetime_ispeedscan');

                                if (offering != null) {
                                  try {
                                    var customerInfo = await Purchases.purchaseStoreProduct(offering.availablePackages[0].storeProduct);

                                    getSubscriptionsData();

                                    LogHelper.logSuccessMessage('Purchase Package', customerInfo);

                                    getSubscriptionsData();
                                  } catch (e) {
                                    LogHelper.logErrorMessage('Subscription Purchase Error ', e);
                                  }

                                  // offering
                                }
                              },
                              text: 'Purchase Now \$4.99',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 50.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                                iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                color: const Color(0xFF173F5A),
                                textStyle: FlutterFlowTheme.of(context).titleLarge.override(
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

    _customerInfo = await Purchases.restorePurchases();

    LoadingDialog.hide(context);
  }

  // Method to cancel the subscription
  Future<void> _cancelSubscription() async {
    // try {

    var hasActiveEntitlements = _customerInfo?.entitlements.active.isNotEmpty ?? false;

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
    _customerInfo = await Purchases.getCustomerInfo();

    offerings = await Purchases.getOfferings();

    LogHelper.logSuccessMessage('Customer Info', _customerInfo);

    LogHelper.logSuccessMessage('Offerings', offerings);

    if (_customerInfo?.entitlements.all['sub_lifetime_ispeedscan'] != null && _customerInfo?.entitlements.all['sub_lifetime_ispeedscan']?.isActive == true) {
      // User has subscription, show them the feature
      setState(() {
        _isSubscribed = true;
      });
    } else {
      _isSubscribed = false;

      setState(() {});
      // Show the Paywall
    }
  }
}

class LoadingDialog {
  static bool isShowing = false;
  static bool isImagePickerCalled = false;
  static bool isAlreadyCancelled = false;

  static void show(BuildContext context, {String message = "Creating PDF..."}) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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

// Function to show an AlertDialog for permissions
void _showPermissionDialog(BuildContext context, String message, {bool openSettings = false}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Permission Required"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          if (openSettings)
            TextButton(
              child: const Text("Open Settings"),
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
