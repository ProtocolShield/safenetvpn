import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:safenetvpn/Repository/authRepo.dart';
import 'package:safenetvpn/Views/bottomnav/bottomnav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safenetvpn/Views/onboarding/onboarding1.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:safenetvpn/Repository/homeRepo.dart' show HomeRepo;

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  double visualPercent = 0.0; // 0 → 1 for the bar fill
  double displayPercent = 0.0; // 0 → 0.10 for the text
  Timer? percentTimer;

  @override
  void initState() {
    super.initState();

    // Animate bar & text
    percentTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        visualPercent += 0.02; // Bar fill speed
        if (displayPercent < 0.10) {
          displayPercent += 0.002; // Display 0% → 10%
        }
      });

      if (visualPercent >= 1.0) {
        visualPercent = 1.0;
        percentTimer?.cancel();
      }
    });

    final repo = Get.put<HomeRepo>(HomeRepo());
    final repo1 = Get.put<AuthRepo>(AuthRepo());
  
    repo.getServers(true);
    repo.startGettingStages();
    repo.myKillSwitch();
    repo.autoConnect(context);
    repo1.getUser(context);
    repo.loadserverFromStorage();
    repo.getPlans();
    repo.getPremium();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (!mounted) return;

    if (token != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Bottomnav()));
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Onboarding1()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Image.asset(
              'assets/images/safenetlogo.png',
              fit: BoxFit.cover,
              scale: 3.0,
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/safenettext.png',
              fit: BoxFit.cover,
              scale: 3.0,
            ),
            const SizedBox(height: 50),

            // Progress bar
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PercentageProgressBar(
                  visualPercent: visualPercent,
                  displayPercent: displayPercent,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bottom text
            const Text(
              "Initializing Secure Connection..",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class PercentageProgressBar extends StatelessWidget {
  final double visualPercent; // Controls bar fill
  final double displayPercent; // Controls shown % text

  const PercentageProgressBar({
    super.key,
    required this.visualPercent,
    required this.displayPercent,
  });

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      width: 240,
      lineHeight: 10.0,
      percent: visualPercent.clamp(0.0, 1.0),
      backgroundColor: const Color(0xFF1E1E1E),
      barRadius: const Radius.circular(8),
      linearGradient: const LinearGradient(
        colors: [Color(0xFF0072FF), Colors.purple],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    );
  }
}
