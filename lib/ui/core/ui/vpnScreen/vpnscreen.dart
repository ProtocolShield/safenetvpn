import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:safenetvpn/ui/widgets/connectionTimer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:safenetvpn/ui/core/ui/premium/premium.dart' show Premium;
import 'package:safenetvpn/view_model/homeGateModel.dart'
    show HomeGateModel, MyVpnConnectState;

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> with TickerProviderStateMixin {
  int selectedTabIndex = 0;
  var provider = Get.put<HomeGateModel>(HomeGateModel());

  @override
  Widget build(BuildContext context) {
    // Add this line to help debug release mode issues
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 212),
              Image.asset(
                'assets/images/worldmap.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 400,
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
                              child: Image.asset(
                                'assets/safenet.png',
                                scale: 10,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/psv.png", scale: 5),
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
                                builder: (context) => const Premium(),
                              ),
                            );
                          },
                          child: Image.asset(
                            "assets/images/premium.png",
                            scale: 4.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Server Selection
                  GestureDetector(
                    onTap: () => provider.onItemTapped(1),
                    child: Container(
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 2.0,
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
                          provider.vpnConnectionState ==
                                  MyVpnConnectState.connected
                              ? CachedNetworkImage(
                                  imageUrl: provider
                                      .srvList[provider.srvIndex.value]
                                      .image,
                                  height: 30,
                                  width: 30,
                                )
                              : Image.asset(
                                  "assets/images/globe.png",
                                  height: 20,
                                ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (provider.vpnConnectionState.value ==
                                    MyVpnConnectState.connected) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider
                                            .srvList[provider.srvIndex.value]
                                            .name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        "IP : ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        provider
                                            .srvList[provider.srvIndex.value]
                                            .subServers[provider
                                                .subSrvIndex
                                                .value]
                                            .vpsServer
                                            .ipAddress,
                                        style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
                            ),
                          ),

                          // if (provider.vpnConnectionState.value ==
                          //     VpnConnectedStates.connected) ...[
                          //   // Signal strength bars

                          // ],
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

                  // Upload
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 150, // fixed width
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 12.0,
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
                                padding: const EdgeInsets.all(4),
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
                              const SizedBox(width: 8),
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
                                          text: provider.uS.value,
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
                      ),
                      // Download
                      SizedBox(
                        width: 150, // same fixed width
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 12.0,
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
                                padding: const EdgeInsets.all(4),
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
                              const SizedBox(width: 8),
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
                                          text: provider.dS.value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
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
                      ),
                    ],
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
                  provider.vpnConnectionState.value ==
                          MyVpnConnectState.connected
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
                        // Pulse animation for different states
                        if (provider.vpnConnectionState.value ==
                            MyVpnConnectState.connected)
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.withOpacity(0.2),
                            ),
                          )
                        else if (provider.vpnConnectionState.value ==
                            MyVpnConnectState.connecting)
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          )
                        else
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                        // Outer glow ring
                        // Container(
                        //   width: ,
                        //   height: 150,
                        //   decoration: BoxDecoration(
                        //     shape: BoxShape.circle,
                        //     color:
                        //         (provider.vpnConnectionState.value ==
                        //                     VpnConnectedStates.connected
                        //                 ? Colors.green
                        //                 : provider.vpnConnectionState.value ==
                        //                       VpnConnectedStates.connecting
                        //                 ? Colors.orange
                        //                 : Colors.red)
                        //             .withValues(alpha: 0.1),
                        //   ),
                        // ),
                        // Main button
                        GestureDetector(
                          onTap: () async {
                            await provider.tVpn(context);
                          },
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  provider.vpnConnectionState.value ==
                                          MyVpnConnectState.connected
                                      ? Colors.green.shade400
                                      : provider.vpnConnectionState.value ==
                                            MyVpnConnectState.connecting
                                      ? Colors.orange.shade400
                                      : Colors.red.shade400,
                                  provider.vpnConnectionState.value ==
                                          MyVpnConnectState.connected
                                      ? Colors.green.shade600
                                      : provider.vpnConnectionState.value ==
                                            MyVpnConnectState.connecting
                                      ? Colors.orange.shade600
                                      : Colors.red.shade600,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (provider.vpnConnectionState.value ==
                                                  MyVpnConnectState.connected
                                              ? Colors.green
                                              : provider
                                                        .vpnConnectionState
                                                        .value ==
                                                    MyVpnConnectState.connecting
                                              ? Colors.orange
                                              : Colors.red)
                                          .withValues(alpha: 0.4),
                                  blurRadius: 3,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child:
                                provider.vpnConnectionState.value ==
                                    MyVpnConnectState.connecting
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
                                : Image.asset(
                                    "assets/images/power.png",
                                    scale: 4,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status Text
                  if (provider.vpnConnectionState.value ==
                      MyVpnConnectState.connecting)
                    const Text(
                      "Connecting..",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (provider.vpnConnectionState.value ==
                      MyVpnConnectState.connected) ...[
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
    );
  }
}
