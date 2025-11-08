import 'package:get/get.dart';
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safenetvpn/ui/core/ui/splash/splash.dart' show SplashView;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure CipherGateModel is available globally
  Get.put(CipherGateModel());
  runApp(const SafeNetApp());
}

class SafeNetApp extends StatelessWidget {
  
  const SafeNetApp({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // add a trasction left to right when navigating between pages

      defaultTransition: Transition.rightToLeft,

      title: 'SafeNet VPN',
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
