// ignore_for_file: must_be_immutable
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/ui/core/ui/account/account.dart' show Account;
import 'package:safenetvpn/ui/core/ui/feedback/feedback.dart' show FeedbackView;
import 'package:safenetvpn/ui/core/ui/privacypolicy/privacypolicy.dart'
    show Privacypolicy;
import 'package:safenetvpn/ui/core/ui/protocolchange/protocolchange.dart'
    show ProtocolChange;
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    var authProvider = Get.put<CipherGateModel>(CipherGateModel());
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
                        MaterialPageRoute(
                          builder: (context) => ProtocolChange(),
                        ),
                      );
                    },
                    child: SettingsWidget(
                      imageData: "assets/images/protocols.png",
                      title: "Select Protocols",
                    ),
                  ),
                  GetBuilder<HomeGateModel>(
                    builder: (provider) {
                      return SettingsWidgetWithToggle(
                        title: "Auto Connect",
                        value: provider.autoConnectOn.value,
                        image: "assets/images/share.png",
                        onToggle: (value) => provider.toggleAutoConnectState(),
                      );
                    },
                  ),

                  GetBuilder<HomeGateModel>(
                    builder: (provider) {
                      return SettingsWidgetWithToggle(
                        title: "Kill Switch",
                        value: provider.killSwitchOn.value,
                        image: "assets/images/wifi.png",
                        onToggle: (value) => provider.toggleKillSwitchState(),
                      );
                    },
                  ),

                  SettingsWidget(
                    imageData: "assets/images/connectionmode.png",
                    title: "Connection Mode",
                    isConnetionActive: true,
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
                        MaterialPageRoute(
                          builder: (context) => Privacypolicy(),
                        ),
                      );
                    },
                    child: SettingsWidget(
                      imageData: "assets/images/privacy.png",
                      title: "Privacy Policy",
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      authProvider.shatter(context);
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
  var cont = Get.put<HomeGateModel>(HomeGateModel());

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                if (widget.isConnetionActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Obx(
                      () => Text(
                        cont.selectedProtocol.value == Proto.wireguard
                            ? "WireGuard"
                            : "IKEv2",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                if (!widget.isConnetionActive)
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
              const SizedBox(width: 10),
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
            // activeThumbColor: Colors.blue,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.5),
            onChanged: widget.onToggle,
          ),
        ],
      ),
    );
  }
}
