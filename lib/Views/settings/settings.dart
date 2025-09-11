import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/Repository/authRepo.dart';
import 'package:safenetvpn/Repository/homeRepo.dart';
import 'package:safenetvpn/Views/account/account.dart';
import 'package:safenetvpn/Views/assistant/assistant.dart';
import 'package:safenetvpn/Views/feedback/feedback.dart';
import 'package:safenetvpn/Views/community/community.dart';
import 'package:safenetvpn/Views/privacypolicy/privacypolicy.dart';
import 'package:safenetvpn/Views/protocolchange/protocolchange.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    var authProvider = Get.find<AuthRepo>();
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          Text(
            "Settings",
            style: GoogleFonts.daysOne(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => Account()));
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Container(
                  //   width: 60,
                  //   height: 60,
                  //   decoration: BoxDecoration(
                  //     shape: BoxShape.circle,
                  //     color: Colors.grey,

                  //   ),
                  // ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 20.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Account()),
                    );
                  },
                  child: SettingsWidget(
                    imageData: "assets/images/killswitch.png",
                    title: "Account",
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProtocolChange()),
                    );
                  },
                  child: SettingsWidget(
                    imageData: "assets/images/protocols.png",
                    title: "Select Protocols",
                  ),
                ),
                GetBuilder<HomeRepo>(
                  builder: (provider) {
                    return SettingsWidgetWithToggle(
                      title: "Auto Connect",
                      value: provider.isAutoConnectEnabled.value,
                      image: "assets/images/share.png",
                      onToggle: (value) => provider.toggleAutoConnectState(),
                    );
                  },
                ),

                GetBuilder<HomeRepo>(
                  builder: (provider) {
                    return SettingsWidgetWithToggle(
                      title: "Kill Switch",
                      value: provider.killSwitchEnabled.value,
                      image: "assets/images/wifi.png",
                      onToggle: (value) => provider.toggleKillSwitchState(),
                    );
                  },
                ),

                GestureDetector(
                  onTap: () {},
                  child: SettingsWidget(
                    imageData: "assets/images/connectionmode.png",
                    title: "Connection Mode",
                    isConnetionActive: true,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AiAssistantScreen(),
                      ),
                    );
                  },
                  child: SettingsWidget(
                    imageData: 'assets/images/ai_assistant.png',
                    title: "Ai Assistant",
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackView()),
                    );
                  },
                  child: SettingsWidget(
                    imageData: "assets/images/feedback.png",
                    title: "Feedback",
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Community()),
                    );
                  },
                  child: SettingsWidget(
                    imageData: "assets/images/community.png",
                    title: "Community",
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Privacypolicy()),
                    );
                  },
                  child: SettingsWidget(
                    imageData: "assets/images/privacy.png",
                    title: "Privacy Policy",
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    authProvider.logout(context);
                  },
                  child: SettingsWidget(
                    imageData: "assets/images/logout.png",
                    title: "Logout",
                    islogout: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsWidget extends StatefulWidget {
  final String title;
  final String imageData;
  bool isConnetionActive = false;
  bool islogout = false;
  SettingsWidget({
    super.key,
    required this.title,
    required this.imageData,
    this.isConnetionActive = false,
    this.islogout = false,
  });

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  @override
  Widget build(BuildContext context) {
    var cont = Get.put<HomeRepo>(HomeRepo());
    return Container(
      height: 60, // Slightly increased for better image fit
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40, // Fixed width for icon circle
                  height: 40, // Fixed height for icon circle
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.imageData,
                      width: 22, // Fixed image width
                      height: 22, // Fixed image height
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                if (widget.isConnetionActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      cont.selectedProtocol.name ?? "None",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Image.asset(
                  "assets/images/forward.png",
                  width: 16,
                  height: 16,
                  color: widget.islogout ? Colors.red : Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsWidgetWithToggle extends StatefulWidget {
  final String title;
  final String image;
  final bool value;
  final ValueChanged<bool> onToggle;

  const SettingsWidgetWithToggle({
    super.key,
    required this.title,
    required this.value,
    required this.image,
    required this.onToggle,
  });

  @override
  State<SettingsWidgetWithToggle> createState() =>
      _SettingsWidgetWithToggleState();
}

class _SettingsWidgetWithToggleState extends State<SettingsWidgetWithToggle> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
             Container(
                  width: 40, // Fixed width for icon circle
                  height: 40, // Fixed height for icon circle
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Image.asset(
                      widget.image,
                      width: 22, // Fixed image width
                      height: 22, // Fixed image height
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(width: 5),
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Switch(
            value: widget.value,
            activeThumbColor: Colors.blue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.5),
            onChanged: widget.onToggle,
          ),
        ],
      ),
    );
  }
}
