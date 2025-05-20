import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'helper/local_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage>
    with TickerProviderStateMixin {
  final animationsMap = <String, AnimationInfo>{};
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    setupAnimations();
  }

  void setupAnimations() {
    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.ms,
            duration: 600.ms,
            begin: 0,
            end: 1,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.ms,
            duration: 600.ms,
            begin: Offset(0, 50),
            end: Offset(0, 0),
          ),
        ],
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    final currentLocale = provider.locale.languageCode;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: Text(
          'Language Settings',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Outfit',
                color: Colors.white,
                fontSize: 22.0,
              ),
        ),
        centerTitle: true,
        elevation: 2.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                child: Text(
                  'Select Your Preferred Language',
                  style: FlutterFlowTheme.of(context).headlineSmall,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                child: Text(
                  'Choose the language you want to use in the app',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
                child: GridView(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                  ),
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'en',
                      languageName: 'English',
                      flagEmoji: '🇺🇸',
                      isSelected: currentLocale == 'en',
                      onTap: () => provider.setLocale(const Locale('en')),
                    ),
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'es',
                      languageName: 'Español',
                      flagEmoji: '🇪🇸',
                      isSelected: currentLocale == 'es',
                      onTap: () {
                        provider.setLocale(const Locale('es'));
                        print(
                            "Setting locale to Spanish"); // Add this debug statement
                      },
                    ),
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'fr',
                      languageName: 'Français',
                      flagEmoji: '🇫🇷',
                      isSelected: currentLocale == 'fr',
                      onTap: () => provider.setLocale(const Locale('fr')),
                    ),
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'de',
                      languageName: 'Deutsch',
                      flagEmoji: '🇩🇪',
                      isSelected: currentLocale == 'de',
                      onTap: () => provider.setLocale(const Locale('de')),
                    ),
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'it',
                      languageName: 'Italiano',
                      flagEmoji: '🇮🇹',
                      isSelected: currentLocale == 'it',
                      onTap: () => provider.setLocale(const Locale('it')),
                    ),
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'ja',
                      languageName: '日本語',
                      flagEmoji: '🇯🇵',
                      isSelected: currentLocale == 'ja',
                      onTap: () => provider.setLocale(const Locale('ja')),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 24, 16, 24),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Color(0x1F000000),
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Language Information',
                          style: FlutterFlowTheme.of(context).titleMedium,
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                          child: Text(
                            'iSpeedScan supports multiple languages to make the app accessible to users worldwide. If your preferred language is not available, more languages will be added in future updates.',
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animateOnPageLoad(
                    animationsMap['containerOnPageLoadAnimation']!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required BuildContext context,
    required String languageCode,
    required String languageName,
    required String flagEmoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Color(0x1F000000),
              offset: Offset(0, 2),
            )
          ],
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).primaryBackground,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flagEmoji,
              style: TextStyle(fontSize: 30),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
              child: Text(
                languageName,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Readex Pro',
                      color: isSelected
                          ? Colors.white
                          : FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
