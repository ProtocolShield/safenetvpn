// ignore_for_file: use_build_context_synchronously
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart' show HomeGateModel, MyVpnConnectState, Proto;

class ProtocolChange extends StatelessWidget {
  const ProtocolChange({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GetBuilder<HomeGateModel>(
          builder: (homeRepo) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
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
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Select Protocol',
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
                ),

                // Auto Select Protocol
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  child: Row(
                    children: [
                      Image.asset("assets/images/autoselectprotocol.png", scale: 4),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Auto Select Protocol',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Let SafeNet VPN choose the best protocol',
                              style: TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: homeRepo.autoSelectProtocol,
                        onChanged: (val) async {
                          if (homeRepo.vpnConnectionState.value == MyVpnConnectState.connected ||
                              homeRepo.vpnConnectionState.value == MyVpnConnectState.connecting) {
                            final shouldDisconnect = await showDisconnectDialog(context);
                            if (shouldDisconnect) {
                              if (homeRepo.selectedProtocol == Proto.wireguard) {
                                await homeRepo.dWireguard();
                              } else {
                                await homeRepo.dIkeav2(context);
                              }
                            } else {
                              return;
                            }
                          }
                          await homeRepo.setAutoSelectProtocol(val);
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF7F5AF0),
                        inactiveThumbColor: Colors.grey.shade400,
                        inactiveTrackColor: Colors.grey.shade700,
                      )
                    ]
                  )
                ),
                const Divider(color: Color(0xFF232326), thickness: 1, height: 32),

                // Protocol Options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildProtocolOption(
                        icon: Icons.lock,
                        iconBg: const LinearGradient(colors: [Color(0xFF232326), Color(0xFF232326)]),
                        title: 'Ikeav2',
                        description: 'Disbale intenet access if VPN conection suddenly drops. You should active alwasy-on VPN firstly',
                        selected: homeRepo.selectedProtocol == Proto.ikeav2 && !homeRepo.autoSelectProtocol,
                        onTap: () async {
                          if (!homeRepo.autoSelectProtocol) {
                            if (homeRepo.vpnConnectionState.value == MyVpnConnectState.connected ||
                                homeRepo.vpnConnectionState.value == MyVpnConnectState.connecting) {
                              final shouldDisconnect = await showDisconnectDialog(context);
                              if (shouldDisconnect) {
                                if (homeRepo.selectedProtocol == Proto.wireguard) {
                                  await homeRepo.dWireguard();
                                } else {
                                  await homeRepo.dIkeav2(context);
                                }
                              } else {
                                return;
                              }
                            }
                            await homeRepo.setProtocol(Proto.ikeav2);
                          }
                        },
                      ),
                      const Divider(color: Color(0xFF232326), thickness: 1, height: 32),
                      _buildProtocolOption(
                        icon: Icons.flash_on,
                        iconBg: const LinearGradient(colors: [Color(0xFF232326), Color(0xFF232326)]),
                        title: 'Wireguard',
                        description: 'Disbale intenet access if VPN conection suddenly drops. You should active alwasy-on VPN firstly',
                        selected: homeRepo.selectedProtocol == Proto.wireguard && !homeRepo.autoSelectProtocol,
                        onTap: () async {
                          if (!homeRepo.autoSelectProtocol) {
                            if (homeRepo.vpnConnectionState.value == MyVpnConnectState.connected ||
                                homeRepo.vpnConnectionState.value == MyVpnConnectState.connecting) {
                              final shouldDisconnect = await showDisconnectDialog(context);
                              if (shouldDisconnect) {
                                if (homeRepo.selectedProtocol == Proto.wireguard) {
                                  await homeRepo.dWireguard();
                                } else {
                                  await homeRepo.dIkeav2(context);
                                }
                              } else {
                                return;
                              }
                            }
                            await homeRepo.setProtocol(Proto.wireguard);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Bottom bar indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProtocolOption({
    required IconData icon,
    required LinearGradient iconBg,
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
    onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: selected ? Color(0xFF7F5AF0) : Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: selected
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7F5AF0),
                        width: 3,
                      ),
                      color: Colors.grey.shade600
                    ),
                    child: const Center(
                      child: Icon(Icons.circle, color: Colors.white, size: 12),
                    ),
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade600,
                        width: 2,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showDisconnectDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF232326),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.power_settings_new, color: Color(0xFF7F5AF0), size: 40),
              const SizedBox(height: 16),
              const Text(
                'Disconnect VPN?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You need to disconnect the VPN before changing protocol.',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF7F5AF0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Disconnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ) ?? false;
}
