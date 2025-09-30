import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:safenetvpn/ui/core/ui/bottomnav/bottomnav.dart' show Bottomnav;
import 'package:safenetvpn/ui/core/ui/onboarding/onboarding1.dart' show Onboarding1;

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  double visualPercent = 0.0;
  double displayPercent = 0.0;
  Timer? percentTimer;

  @override
  void initState() {
    super.initState();

    // Animate bar & text safely
    percentTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return; // prevents setState after dispose
      setState(() {
        visualPercent += 0.02;
        if (displayPercent < 0.10) {
          displayPercent += 0.002;
        }
      });

      if (visualPercent >= 1.0) {
        visualPercent = 1.0;
        percentTimer?.cancel();
      }
    });

    final repo = Get.put<HomeGateModel>(HomeGateModel());
    final repo1 = Get.put<CipherGateModel>(CipherGateModel());

    repo.getsrvList(true);
    repo.sGettingStages();
    repo.myKillSwitch();
    repo.autoC(context);
    repo1.probe(context);
    repo.lServerFromLocal();
    repo.gPlans();
    repo.getPre();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return; // check before navigation
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('t');

    if (!mounted) return;

    if (token != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Bottomnav()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Onboarding1()),
      );
    }
  }

  @override
  void dispose() {
    percentTimer?.cancel(); // ✅ cancel timer to prevent leaks
    super.dispose();
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
              'assets/safenet.png',
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
            const Spacer(),
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
  final double visualPercent;
  final double displayPercent;

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
