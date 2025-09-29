import 'package:flutter/material.dart';
import 'package:safenetvpn/ui/core/ui/auth/auth.dart' show Auth;

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          children: [
            SizedBox(height: 50),
            Image.asset(
              'assets/images/onboarding2.png',
              fit: BoxFit.cover,
              scale: 3.5,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                "Connect to high-speed servers worldwide for streaming, gaming, and browsing without limits.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Image.asset(
              'assets/images/onboarding2_logo.png',
              fit: BoxFit.cover,
              scale: 3.0,
            ),
            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/dnsleak.png', scale: 4),
                Image.asset('assets/images/vpnserver.png', scale: 4),
              ]
            ),

            Image.asset('assets/images/webserver.png', scale: 4),

            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Auth()),
                );
              },
              child: Container(
                width: double.infinity,
                height: 60,
                padding: EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset("assets/images/onboarding_button.png"),
                    SizedBox(width: 8),
                    Text(
                      "Get Started",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Image.asset("assets/images/forward.png", scale: 3),
                    SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
