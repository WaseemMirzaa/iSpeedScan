import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ispeedscan/helper/analytics_debug_helper.dart';
import 'package:ispeedscan/helper/log_helper.dart';
import 'package:ispeedscan/services/firebase_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_globals.dart';
import 'flutter_flow/flutter_flow_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    // Initialize Firebase first
    if (Firebase.apps.isEmpty) {
      // For Android, initialize with manual options
      if (Platform.isAndroid) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyCjdvnpDIYnLUHIGh94j4nsLXmqsbkGXsY',
            appId: '1:695369766912:android:3c84020514c056b80760e5',
            messagingSenderId: '695369766912',
            projectId: 'ispeedscan-4edc4',
            storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
          ),
        );
      } else if (Platform.isIOS) {
        // For iOS, use manual options as well
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAHUsS5Wj9C7BFE6h2T3D3epCBtWu5nahM',
            appId: '1:695369766912:ios:c14507644b575c110760e5',
            messagingSenderId: '695369766912',
            projectId: 'ispeedscan-4edc4',
            storageBucket: 'ispeedscan-4edc4.firebasestorage.app',
          ),
        );
      }
    }

    if (Platform.isAndroid) {
      await AnalyticsDebugHelper.enableDebugMode();
    }

    // Initialize Firebase service
    await FirebaseService.instance.initialize();

    // Log app open
    await FirebaseService.instance.logAppOpen();

    print('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
  }

  const MethodChannel('log_helper').setMethodCallHandler((call) async {
    return LogHelper.handlePlatformLog(call);
  });

  GoRouter.optionURLReflectsImperativeAPIs = true;

  usePathUrlStrategy();

  await Purchases.configure(PurchasesConfiguration(
      (Platform.isAndroid) ? revenueCatAndroidKey : revenueCatKey));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  bool displaySplashImage = true;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    // No need to log app open here since we already did it in main()
    // FirebaseService.instance.logAppOpen();

    Future.delayed(const Duration(milliseconds: 4000),
        () => safeSetState(() => _appStateNotifier.stopShowingSplashImage()));
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ispeedscan',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
