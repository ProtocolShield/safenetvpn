import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:safenetvpn/Views/premium/premium.dart';
import 'package:safenetvpn/Widgets/connectionTimer.dart';
import 'package:safenetvpn/Repository/homeRepo.dart' show HomeRepo, VpnConnectedStates;


class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> with TickerProviderStateMixin {

  int selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<HomeRepo>(HomeRepo());
    // Add this line to help debug release mode issues
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 212),
                Image.asset(
                  'assets/images/worldmap.png',
                  fit: BoxFit.cover,
                  scale: 3.0,
                ),
              ],
            ),
            // Main Content
            SafeArea(
              child: Obx(
                () => Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 15,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Center(
                                child: Image.asset('assets/logo.png', scale: 5),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    "assets/images/safenettext.png",
                                    scale: 8,
                                  ),
                                  SizedBox(height: 4),
                                  const Text(
                                    "Privacy Made Simple",
                                    style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Premium()),
                              );
                            },
                            child: Image.asset("assets/images/premium.png", scale: 4)),
                        ],
                      ),
                    ),
                
                    // Server Selection
                    GestureDetector(
                      onTap: () => provider.onItemTapped(1),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              "assets/images/globe.png",
                              scale: 4,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child:  Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (provider.vpnConnectionState.value ==
                                      VpnConnectedStates.connected) ...[
                                    Row(
                                      children: [
                                        CachedNetworkImage(
                                       imageUrl:    provider
                                                  .servers[provider
                                                      .selectedServerIndex.value]
                                                  .image ,
                                          height: 15,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          provider
                                                  .servers[provider
                                                      .selectedServerIndex.value]
                                                  .name ,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "IP ${provider.servers[provider.selectedServerIndex.value].subServers[provider.selectedSubServerIndex.value].vpsServer.ipAddress}",
                                      style: const TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      "Select Server",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              )),
                          
                            if (provider.vpnConnectionState.value ==
                                VpnConnectedStates.connected) ...[
                              // Signal strength bars
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF888888),
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                
                    const SizedBox(height: 20),
                
                    // Speed Stats
                      Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Upload
                        Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Upload",
                                      style: TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: provider.uploadSpeed.value,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: " Kb/s",
                                            style: TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                
                          // Download
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 8.0,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Download",
                                      style: TextStyle(
                                        color: Color(0xFF888888),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: provider.downloadSpeed.value,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: " Kb/s",
                                            style: TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                
                    SizedBox(height: 20),
                
                    // Connected Time
                    const Text(
                      "Connected Time",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    provider.vpnConnectionState.value == VpnConnectedStates.connected
                        ? ConnectionTimer()
                        : const Text(
                            "00:00:00",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                
                    SizedBox(height: 20),
                    // Connection Button
                    GestureDetector(
                      onTap: () {},
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse animation for connected state
                          if (provider.vpnConnectionState.value ==
                              VpnConnectedStates.connected)
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green.withValues(alpha: 0.2),
                              ),
                            ),
                          // Outer glow ring
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                                    color:
                                  (provider.vpnConnectionState.value ==
                                              VpnConnectedStates.connected
                                          ? Colors.green
                                          : provider.vpnConnectionState.value ==
                                                VpnConnectedStates.connecting
                                          ? Colors.orange
                                          : Colors.red)
                                      .withValues(alpha: 0.1),
                            ),
                          ),
                          // Main button
                          GestureDetector(
                            onTap: () async {
                              await provider.toggleVpn(context);
                         
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    provider.vpnConnectionState.value ==
                                            VpnConnectedStates.connected
                                        ? Colors.green.shade400
                                        : provider.vpnConnectionState.value ==
                                              VpnConnectedStates.connecting
                                        ? Colors.orange.shade400
                                        : Colors.red.shade400,
                                    provider.vpnConnectionState.value ==
                                            VpnConnectedStates.connected
                                        ? Colors.green.shade600
                                        : provider.vpnConnectionState.value ==
                                              VpnConnectedStates.connecting
                                        ? Colors.orange.shade600
                                        : Colors.red.shade600,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (provider.vpnConnectionState.value ==
                                                    VpnConnectedStates.connected
                                                ? Colors.green
                                                : provider.vpnConnectionState.value ==
                                                      VpnConnectedStates
                                                          .connecting
                                                ? Colors.orange
                                                : Colors.red)
                                            .withValues(alpha: 0.4),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child:
                                  provider.vpnConnectionState.value ==
                                      VpnConnectedStates.connecting
                                  ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 5,
                                      ),
                                    ),
                                  )
                                  : Image.asset("assets/images/power.png", scale: 4,)
                            ),
                          ),
                        ],
                      ),
                    ),
                
                    const SizedBox(height: 20),
                
                    // Status Text
                    if (provider.vpnConnectionState.value == VpnConnectedStates.connecting)
                      const Text(
                        "Connecting..",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else if (provider.vpnConnectionState.value ==
                        VpnConnectedStates.connected) ...[
                      const Text(
                        "Your connection is protected",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Connected",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      const Text(
                        "Tap to connect",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
