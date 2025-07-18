import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'privacy_model.dart';
export 'privacy_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ispeedscan/helper/local_provider.dart';

class PrivacyWidget extends StatefulWidget {
  const PrivacyWidget({super.key});

  @override
  State<PrivacyWidget> createState() => _PrivacyWidgetState();
}

class _PrivacyWidgetState extends State<PrivacyWidget>
    with TickerProviderStateMixin {
  late PrivacyModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  var point1 =
      '1. Information Collection and Utilization\niSpeedScan is built to function without collecting or storing personal data for its core features, such as document scanning and storage. All data processed by the app stays on your device, with the exception of minimal information needed for subscription processing. Here’s what we access and why:\n\n•Camera Access: We need access to your device’s camera to scan documents. All images are processed locally and never sent elsewhere.\n\n•Photo Gallery Access: We request permission to save scanned documents to your photo gallery. This is only for your convenience, and we don’t touch your existing photos.•Storage of PDFs in Files: If you opt to save scans as PDFs, we’ll ask for storage permissions. These files remain under your control on your device.\n\n•Document Management: Users have full control over their PDFs and can choose to share, email, save, or upload them as they prefer.\n\n•Subscription Processing: To unlock full features, a one-time subscription fee is processed securely through a third-party service. We don’t collect or store your payment details—everything is handled safely by that service.';
  var point2 =
      '2. Data Transmission Practices\nFor its main functions—like scanning and saving documents — iSpeedScan doesn’t send any data to external servers or third parties. Everything happens locally on your device. The only data transmitted is related to your life time subscription, which is securely managed by a payment service';
  var point3 =
      '3. Absence of Advertisements\niSpeedScan offers a clean, ad-free experience. Once you pay the one-time subscription fee you get full access to all features—no hidden costs or interruptions.';
  var point4 =
      '4. Our Dedication to Your Privacy\nWe’re committed to upholding the highest privacy and security standards for our users. If you have any questions or want more details about this policy, please don’t hesitate to reach out to use.';

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _model = createModel(context, () => PrivacyModel());

    animationsMap.addAll({
      'textOnPageLoadAnimation1': AnimationInfo(
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
      'textOnPageLoadAnimation2': AnimationInfo(
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
      'buttonOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(100.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    _model.dispose();

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
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              context.safePop();
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 30.0,
            ),
          ),
          actions: const [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      16.0, 16.0, 16.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0.0, 20.0, 0.0, 20.0),
                        child: Center(
                          child: Text(
                            t.privacyAndSecurity,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Readex Pro',
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                          ).animateOnPageLoad(
                              animationsMap['textOnPageLoadAnimation1']!),
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
                                fontFamily: 'Readex Pro',
                                color: FlutterFlowTheme.of(context).primaryText,
                                fontSize: 12.5,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                              ),
                          children: [
                            TextSpan(
                              text:
                                  '${t.atISpeedScanWePrioritizAndOtherDetails}\n\n${t.informationCollectionAndOtherDetails}\n\n${t.dataTransmissionPracticeAndOtherDetails}\n\n${t.absenceOfAdvertismentsAndOtherDetails}\n\n${t.ourDedicationToYourPrivacyAndOtherDetails}\n\n${t.privacyAndSecurityDetailFive}',
                            ),
                            TextSpan(
                              text:
                                  'https://firebase.google.com/support/privacy',
                              style: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .override(
                                    fontFamily: 'Readex Pro',
                                    color: Colors.blue,
                                    fontSize: 12.5,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  await launchURL(
                                      'https://firebase.google.com/support/privacy');
                                },
                            ),
                          ],
                        ),
                      ).animateOnPageLoad(
                          animationsMap['textOnPageLoadAnimation2']!),
                      Divider(
                        height: 32.0,
                        thickness: 1.0,
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
