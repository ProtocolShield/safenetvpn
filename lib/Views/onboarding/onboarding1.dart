import 'package:flutter/material.dart';
import 'package:safenetvpn/Views/onboarding/onboarding2.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Image.asset(
              'assets/images/onboarding1.png',
              fit: BoxFit.cover,
              scale: 3.5,
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                "Keep your data private and secure every time you connect.",
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Image.asset(
              'assets/images/onboarding1_logo.png',
              fit: BoxFit.cover,
              scale: 3.0,
            ),
            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/dnsleak.png', scale: 4),
                Image.asset('assets/images/vpnserver.png', scale: 4),
              ],
            ),

            Image.asset('assets/images/webserver.png', scale: 4),

            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Onboarding2()),
              ),
              child: Container(
                height: 60,
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
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
                      "Next",
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
