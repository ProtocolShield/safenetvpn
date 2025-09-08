import 'package:eva_icons_flutter/eva_icons_flutter.dart' show EvaIcons;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safenetvpn/Repository/authRepo.dart';
import 'package:safenetvpn/Repository/homeRepo.dart' show HomeRepo;
import 'package:safenetvpn/Views/auth/auth.dart';
import 'package:safenetvpn/Views/server/serverview.dart';
import 'package:safenetvpn/Views/settings/settings.dart';
import 'package:safenetvpn/Views/vpnScreen/vpnscreen.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  final screens = [const VpnScreen(), const Serverview(), const Settings()];

  var repo = Get.put<HomeRepo>(HomeRepo());
  var repo1 = Get.put<AuthRepo>(AuthRepo());

  @override
  void initState() {
    super.initState();
    repo.getServers(true);
    repo.startGettingStages();
    repo.myKillSwitch();
    repo.autoConnect(context);
    repo.loadserverFromStorage();
    repo1.getUser(context);
    repo.getPremium();
    repo.loadProtocolFromStorage();
    repo.getPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: screens[repo.selectedBottomIndex.value],
        bottomNavigationBar: SafeArea(
          bottom: true,
          top: false,
          right: false,
          left: false,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              border: Border(
                top: BorderSide(color: Color(0xFF333333), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BottomNavItem(
                  index: 0,
                  icon: EvaIcons.homeOutline,
                  label: "Home",
                  isSelected: repo.selectedBottomIndex.value == 0,
                  onTap: () {
                    repo.onItemTapped(0);
                  },
                ),
                BottomNavItem(
                  index: 1,
                  icon: EvaIcons.globe2Outline,
                  label: "Server",
                  isSelected: repo.selectedBottomIndex.value == 1,
                  onTap: () {
                    repo.onItemTapped(1);
                  },
                ),
                BottomNavItem(
                  index: 2,
                  icon: EvaIcons.settingsOutline,
                  label: "Setting",
                  isSelected: repo.selectedBottomIndex.value == 2,
                  onTap: () {
                    repo.onItemTapped(2);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Colors.purple, Colors.blue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isSelected
              ? ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return gradient.createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Icon(icon, color: Colors.white),
                )
              : Icon(icon, color: Colors.white),
          isSelected
              ? ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return gradient.createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
        ],
      ),
    );
  }
}
