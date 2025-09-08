// ignore_for_file: avoid_print, file_names
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vpn/flutter_vpn.dart' show FlutterVpn;

class Ikeav2EngineAndIpSec {
  bool _isInitialized = false;

  Future<void> initIkev2() async {
    try {
      if (!_isInitialized) {
        await FlutterVpn.prepare();
        _isInitialized = true;
      }
    } catch (e) {
      log('Error initializing IKEv2: $e');
      rethrow;
    }
  }

  Future<bool> connectTheIKEAV2(
    String server,
    String username,
    String password
  ) async {
    try {
      await initIkev2();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? isKillSwitch = prefs.getBool('killSwitchEnabled');
      List<String>? selectedApps = prefs.getStringList('blocked_apps');


      await FlutterVpn.connectIkev2EAP(
        server: server,
        username: username,
        password: password,
        selectedApps: selectedApps,
        killSwitch: isKillSwitch ?? false,
      );

      return true;
    } catch (e) {
      log('Error connecting to IKEv2: $e');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      await FlutterVpn.disconnect();
      return true;
    } catch (e) {
      log('Error disconnecting IKEv2: $e');
      return false;
    }
  }
}
