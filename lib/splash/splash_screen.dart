import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flutter_flow/nav/nav.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../helper/shared_preference_service.dart';
import 'package:ispeedscan/l10n/app_localizations_es.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ToggleModeScreen extends StatefulWidget {
  @override
  _ToggleModeScreenState createState() => _ToggleModeScreenState();
}

class _ToggleModeScreenState extends State<ToggleModeScreen> {
  bool? isPdfMode;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _loadMode();
    _initializeSplashScreen();
  }

  Future<void> _initializeSplashScreen() async {
    // Show splash for 4 seconds then navigate
    await Future.delayed(const Duration(milliseconds: 4000));
    if (mounted) {
      AppStateNotifier.instance.stopShowingSplashImage();
    }
  }

  Future<void> _loadMode() async {
    bool savedMode = await PreferenceService.getMode();
    setState(() {
      isPdfMode = savedMode;
    });
  }

  @override
  void dispose() {
    // Reset orientation when leaving screen
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF173F5A), // Top color
                    Color(0xFF4B5E76), // Middle color
                    Color(0xFFCBCDD3), // Bottom color
                  ],
                  stops: [0.0, 0.5, 1.0], // Gradient stops
                ),
              ),
            ),
          ),
          Positioned(
            left: 100,
            top: 180,
            right: 100,
            child: Image.asset(
              'assets/images/qslogo_copy.png',
              fit: BoxFit.contain, // Use cover to fill the space
            ),
          ),

          //
          //
          //
          if (isPdfMode != null)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 12.0, 16.0, 0.0),
                          child: Container(
                              width: double.infinity,
                              height: 80.0,
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
                                          '${t.mode}: ',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily: 'Readex Pro',
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t.pdf,
                                          // "PDF",
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily: 'Readex Pro',
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                        Transform.scale(
                                          scale: 1.5, //
                                          child: Switch(
                                            value: isPdfMode!,
                                            onChanged: (value) {
                                              setState(() {
                                                isPdfMode = value;
                                              });
                                              _toggleMode(isPdfMode!);
                                            },
                                            activeColor: Colors.blue,
                                            inactiveThumbColor: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 15,
                                        ),
                                        Text(
                                          t.photo,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge
                                              .override(
                                                fontFamily: 'Readex Pro',
                                                letterSpacing: 0.0,
                                              ),
                                        ),
                                        SizedBox(
                                          width: 2,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleMode(bool value) {
    PreferenceService.saveMode(value); // Save the state
  }
}
