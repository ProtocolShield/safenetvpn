import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/Repository/authRepo.dart';
import 'package:safenetvpn/Repository/homeRepo.dart';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
  var provider = Get.put<AuthRepo>(AuthRepo());
  var provider1 = Get.put<HomeRepo>(HomeRepo());
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
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
                     Expanded(
                      child: Text(
                        'My Account',
                        style: GoogleFonts.daysOne(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40), // For symmetry
                  ],
                ),
              ),

              // Personal Details Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF232326),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7F5AF0), Color(0xFFE94057)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Personal Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      DetailRow(
                        icon: Icons.person,
                        title: provider.userInfo!.name,
                        subtitle: 'Username',
                      ),
                      const Divider(
                        color: Color(0xFF353535),
                        thickness: 1,
                        height: 28,
                      ),
                      DetailRow(
                        icon: Icons.email,
                        title: provider.userInfo!.email,
                        subtitle: 'Email address',
                      ),
                      const Divider(
                        color: Color(0xFF353535),
                        thickness: 1,
                        height: 28,
                      ),
                      DetailRow(
                        icon: Icons.calendar_today,
                        title: 'August 15, 2025',
                        subtitle: 'Member since',
                      ),
                    ],
                  ),
                ),
              ),

              provider1.isPremium.value == true
                  ? // Subscription Details Card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF232326),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7F5AF0),
                                        Color(0xFFE94057),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Subscription Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            DetailRow(
                              icon: Icons.star,
                              title: 'Premium Plan',
                              subtitle: 'Current plan',
                              trailing: const RenewBadge(),
                            ),
                            const Divider(
                              color: Color(0xFF353535),
                              thickness: 1,
                              height: 28,
                            ),
                            DetailRow(
                              icon: Icons.check_circle,
                              iconColor: Colors.green,
                              title: provider1.subscription.value!.status,
                              subtitle: 'Subscription status',
                            ),
                            const Divider(
                              color: Color(0xFF353535),
                              thickness: 1,
                              height: 28,
                            ),
                            DetailRow(
                              icon: Icons.calendar_today,
                              title:
                                  "${provider1.expiryDate.value.day} / ${provider1.expiryDate.value.month} / ${provider1.expiryDate.value.year}",
                              subtitle: 'Expires on',
                            ),
                            const Divider(
                              color: Color(0xFF353535),
                              thickness: 1,
                              height: 28,
                            ),
                            DetailRow(
                              icon: Icons.timelapse,
                              title:
                                  '${provider1.expiryDate.value.difference(DateTime.now()).inDays} days remaining',
                              subtitle: 'Until renewal',
                              trailing: const RenewBadge(),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                    children: [
                      SizedBox(height: 20),
                      Center(child: Text("No Subscription Details Available")),
                    ],
                  ),

              
            ],
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Widget? trailing;

  const DetailRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor = const Color(0xFF7F7F7F),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F5AF0), Color(0xFFE94057)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class RenewBadge extends StatelessWidget {
  const RenewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F5AF0), Color(0xFFE94057)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Renew',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
