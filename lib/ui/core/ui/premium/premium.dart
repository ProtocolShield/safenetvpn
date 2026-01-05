import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safenetvpn/services/analytics_service.dart';

class Premium extends StatefulWidget {
  const Premium({super.key});

  @override
  State<Premium> createState() => _PremiumState();
}

class _PremiumState extends State<Premium> {
  int selectedPlan = 0;
  final controller = Get.put(HomeGateModel());
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => isLoading = true);
    await controller.gPlans();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Premium',
                        style: GoogleFonts.daysOne(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40), // For symmetry
                  ],
                ),
                const SizedBox(height: 28),
                // Unlock Features Title
                const Text(
                  'Unlock All VPN Features',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 28),
                // Gradient Card
                Obx(() {
                  if (controller.plans.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232326),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  // Use the selected plan instead of first/last
                  final currentPlan = selectedPlan < controller.plans.length
                      ? controller.plans[selectedPlan]
                      : controller.plans.first;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4A90E2),
                          Color(0xFF7F5AF0),
                          Color(0xFFE94057),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${currentPlan.name}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "\$${currentPlan.discountPrice}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '\$${currentPlan.originalPrice}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${currentPlan.name}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${currentPlan.description}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Features List
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FeatureItem(
                                icon: Icons.public,
                                text: 'Unlimited high-speed servers worldwide',
                                fontSize: 13,
                              ),
                              FeatureItem(
                                icon: Icons.sports_esports,
                                text:
                                    'Access to secure streaming & gaming servers',
                                fontSize: 13,
                              ),
                              FeatureItem(
                                icon: Icons.lock,
                                text: 'Military-grade encryption with no logs',
                                fontSize: 13,
                              ),
                              FeatureItem(
                                icon: Icons.cloud,
                                text: '24/7 priority support',
                                fontSize: 13,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 28),
                // Plan Options - Dynamic List
                Obx(() {
                  if (controller.plans.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Colors.white54,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Plans not available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Unable to load subscription plans',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: List.generate(
                      controller.plans.length,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index < controller.plans.length - 1 ? 12 : 0,
                        ),
                        child: PlanOption(
                          index: index,
                          title:
                              '${controller.plans[index].name} \$${controller.plans[index].discountPrice}',
                          trailing: controller.plans[index].isBestDeal
                              ? 'Popular'
                              : '${controller.plans[index].invoiceInterval} Billed',
                          titleSize: 14,
                          trailingSize: 11,
                          selectedPlan: selectedPlan,
                          onSelected: (idx) {
                            setState(() {
                              selectedPlan = idx;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 28),
                // Continue Button
                GestureDetector(
                  onTap: () async {
                    // Track payment button click
                    if (selectedPlan < controller.plans.length) {
                      AnalyticsService().trackPaymentClick(
                        controller.plans[selectedPlan].name,
                      );
                    }

                    final Uri url = Uri.parse(
                      'https://psvpn.protocolshield.com/pricing',
                    );
                    try {
                      bool launched = await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched) {
                        // Fallback for older url_launcher versions or web
                        // ignore: deprecated_member_use
                        await launch(url.toString());
                      }
                    } catch (e) {
                      debugPrint('URL launch error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open the payment page: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Text(
                        'Continue to Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Feature Row Widget
class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final double fontSize;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.text,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan Option Widget
class PlanOption extends StatelessWidget {
  final int index;
  final String title;
  final String trailing;
  final double titleSize;
  final double trailingSize;
  final int selectedPlan;
  final ValueChanged<int> onSelected;

  const PlanOption({
    super.key,
    required this.index,
    required this.title,
    required this.trailing,
    required this.titleSize,
    required this.trailingSize,
    required this.selectedPlan,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedPlan == index;

    return GestureDetector(
      onTap: () => onSelected(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF232326),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF4A90E2) : Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (trailing == 'Popular')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Popular',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: trailingSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                trailing,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: trailingSize,
                  fontFamily: 'Poppins',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
