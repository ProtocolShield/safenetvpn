import 'package:flutter/material.dart';

class Privacypolicy extends StatelessWidget {
  const Privacypolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF232326),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 40), // For symmetry
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Effective Date
                  const Text(
                    'Effective Date: February 10, 2025',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Scrollable Content
                  Expanded(
                    child: ListView(
                      children: [
                        // Section 1
                        const Text(
                          '1. Introduction',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SafeNet VPN is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our services.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Section 2
                        const Text(
                          '2. Information We Collect',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Bullet(
                          title:
                              'Personal information you provide when registering, such as your email address and username.',
                        ),
                        const Bullet(
                          title:
                              'Usage data including connection times, server selections, and bandwidth usage.',
                        ),
                        const Bullet(
                          title:
                              'Device information such as device type, operating system, and app version.',
                        ),
                        const Bullet(
                          title:
                              'Diagnostic data to help us improve service reliability and performance.',
                        ),
                        const SizedBox(height: 24),
                        // Section 3
                        const Text(
                          '3. How We Use Your Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Bullet(
                        title:   'To provide and maintain our VPN services.',
                        ),
                        Bullet(
                          title: 'To personalize your experience and improve our offerings.',
                        ),
                        Bullet(
                          title: 'To monitor and analyze usage and trends.',
                        ),
                        Bullet(
                          title: 'To communicate with you about updates, promotions, and support.',
                        ),
                        const SizedBox(height: 24),
                        // Section 4
                        const Text(
                          '4. Data Security',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We implement industry-standard security measures to protect your data from unauthorized access, disclosure, or destruction.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Section 5
                        const Text(
                          '5. Changes to This Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We may update this Privacy Policy from time to time. We encourage you to review this page periodically for any changes.',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            //     Gradient Scrollbar (visual only, not interactive)
            Positioned(
              right: 8,
              top: 80,
              bottom: 24,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A90E2), Color(0xFFE94057)],
                  ),
                ),
              ),
            ),
            // Bottom bar indicator
            Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Bullet extends StatelessWidget {
  final String title;
  const Bullet({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u2022 ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
