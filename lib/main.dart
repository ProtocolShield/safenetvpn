import 'dart:io';
import 'package:get/get.dart';
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safenetvpn/ui/core/ui/splash/splash.dart' show SplashView;
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:safenetvpn/firebase_options.dart';
import 'package:safenetvpn/services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Analytics Service
  await AnalyticsService().init();

  // Track app open
  AnalyticsService().trackEvent(
    'app_open',
    parameters: {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
    },
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Set window options
    WindowOptions windowOptions = const WindowOptions(
      size: Size(480, 750), // Default size for the window
      minimumSize: Size(480, 750), // Minimum size for the window
      maximumSize: Size(480, 750),
      center: true, // Center the window on screen
      backgroundColor: Colors.transparent, // Optional background color
      title: 'PS VPN', // Window title
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Ensure CipherGateModel is available globally
  Get.put(CipherGateModel());
  // Run the app
  runApp(const SafeNetApp());
}

class SafeNetApp extends StatelessWidget {
  const SafeNetApp({super.key});

  // Create analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Add observer to track screen views
      navigatorObservers: [observer],
      defaultTransition: Transition.rightToLeft,

      title: 'PS VPN',
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Poppins",
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        // Use a fully opaque dark background so no white shows through on transitions
        canvasColor: const Color(0xFF0F0F12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF121417),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
        dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF16181D)),
      ),
      home: const SplashView(),
    );
  }
}
