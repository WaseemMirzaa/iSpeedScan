import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'helper/local_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ispeedscan/helper/local_provider.dart';

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

    final selectedLocale = provider.locale.languageCode;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        title: Text(
          t.languageSettings,
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
                  t.selectYourPreferredLanguage,
                  style: FlutterFlowTheme.of(context).headlineSmall,
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                child: Text(
                  t.chooseTheLanguageYouWant,
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
                    //done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'en',
                      languageName: 'English',
                      flagEmoji: '🇺🇸',
                      isSelected: currentLocale == 'en',
                      onTap: () {
                        provider.setLocale(const Locale('en'));
                        Navigator.pop(context);
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'es',
                      languageName: 'Español',
                      flagEmoji: '🇪🇸',
                      isSelected: currentLocale == 'es',
                      onTap: () {
                        provider.setLocale(const Locale('es'));
                        Navigator.pop(context);

                        print(
                            "Setting locale to Spanish"); // Add this debug statement
                      },
                    ),

                    //done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'fr',
                      languageName: 'Français',
                      flagEmoji: '🇫🇷',
                      isSelected: currentLocale == 'fr',
                      onTap: () {
                        provider.setLocale(const Locale('fr'));

                        Navigator.pop(context);
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'de',
                      languageName: 'Deutsch',
                      flagEmoji: '🇩🇪',
                      isSelected: currentLocale == 'de',
                      onTap: () {
                        provider.setLocale(const Locale('de'));
                        Navigator.pop(context);
                      },
                    ),

                    //done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'it',
                      languageName: 'Italiano',
                      flagEmoji: '🇮🇹',
                      isSelected: currentLocale == 'it',
                      onTap: () {
                        provider.setLocale(const Locale('it'));
                        Navigator.pop(context);
                      },
                    ),

                    //done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'ja',
                      languageName: '日本語',
                      flagEmoji: '🇯🇵',
                      isSelected: currentLocale == 'ja',
                      onTap: () {
                        provider.setLocale(const Locale('ja'));
                        Navigator.pop(context);
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'ar',
                      languageName: 'Arabic',
                      flagEmoji: '🇦🇪',
                      isSelected: currentLocale == 'ar',
                      onTap: () {
                        provider.setLocale(const Locale('ar'));
                        Navigator.pop(context);
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'hi',
                      languageName: 'हिन्दी',
                      flagEmoji: '🇮🇳',
                      isSelected: currentLocale == 'hi',
                      onTap: () {
                        provider.setLocale(const Locale('hi'));
                        Navigator.pop(context);
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'ko',
                      languageName: '한국어',
                      flagEmoji: '🇰🇷',
                      isSelected: currentLocale == 'ko',
                      onTap: () {
                        provider.setLocale(const Locale('ko'));
                        Navigator.pop(context);
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'pt',
                      languageName: 'Português',
                      flagEmoji:
                          '🇵🇹', // Portugal flag; use 🇧🇷 for Brazil if preferred
                      isSelected: currentLocale == 'pt',
                      onTap: () {
                        provider.setLocale(const Locale('pt'));
                        Navigator.pop(context);

                        print(
                            "Setting locale to Portuguese"); // Debug statement
                      },
                    ),

//done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'ru',
                      languageName: 'Русский',
                      flagEmoji: '🇷🇺',
                      isSelected: currentLocale == 'ru',
                      onTap: () {
                        provider.setLocale(const Locale('ru'));

                        Navigator.pop(context);
                        print("Setting locale to Russian"); // Debug statement
                      },
                    ),

                    //done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'th',
                      languageName: 'ไทย',
                      flagEmoji: '🇹🇭',
                      isSelected: currentLocale == 'th',
                      onTap: () {
                        provider.setLocale(const Locale('th'));

                        Navigator.pop(context);
                        print("Setting locale to Thai"); // Debug statement
                      },
                    ),

                    //done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'tr',
                      languageName: 'Türkçe',
                      flagEmoji: '🇹🇷',
                      isSelected: currentLocale == 'tr',
                      onTap: () {
                        provider.setLocale(const Locale('tr'));

                        Navigator.pop(context);
                        print("Setting locale to Turkish"); // Debug statement
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'vi',
                      languageName: 'Tiếng Việt',
                      flagEmoji: '🇻🇳',
                      isSelected: currentLocale == 'vi',
                      onTap: () {
                        provider.setLocale(const Locale('vi'));
                        Navigator.pop(context);
                        print(
                            "Setting locale to Vietnamese"); // Debug statement
                      },
                    ),

                    // done
                    _buildLanguageCard(
                      context: context,
                      languageCode: 'zh',
                      languageName: '中文',
                      flagEmoji: '🇨🇳',
                      isSelected: currentLocale == 'zh',
                      onTap: () {
                        provider.setLocale(const Locale('zh'));

                        Navigator.pop(context);
                        print("Setting locale to Chinese"); // Debug statement
                      },
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
                          t.languageInformation,
                          style:
                              FlutterFlowTheme.of(context).titleMedium.copyWith(
                                    color: Colors.black,
                                  ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 8, 0, 0),
                          child: Text(
                            t.iSpeedScanSupportsMultipleLanuages,
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
