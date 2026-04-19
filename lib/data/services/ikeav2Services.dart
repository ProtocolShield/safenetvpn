// ignore_for_file: avoid_print, file_names
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vpn/flutter_vpn.dart' show FlutterVpn;
import 'package:safenetvpn/data/services/windows_vpn_service.dart';

class Ikeav2EngineAndIpSecServices {
  bool _isInitialized = false;
  late WindowsVpnService _windowsVpn;

  Ikeav2EngineAndIpSecServices() {
    _windowsVpn = WindowsVpnService();
  }

  Future<void> initIkev2() async {
    try {
      if (!_isInitialized) {
        // Only initialize flutter_vpn on Android/iOS
        if (Platform.isAndroid || Platform.isIOS) {
          await FlutterVpn.prepare();
          print("✅ [IKEV2] flutter_vpn prepared (Android/iOS)");
        } else if (Platform.isWindows) {
          print("✅ [IKEV2] Using Windows VPN service");
          await _windowsVpn.prepare();
        }
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
    String password, {
    String vpnServerDomain = '',
    String vpnServerName = 'VPN Server',
  }) async {
    try {
      print("🔧 [IKEV2] Initializing IKEv2 engine...");
      await initIkev2();
      print("✅ [IKEV2] Engine initialized");
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? isKillSwitch = prefs.getBool('killSwitchEnabled');
      List<String>? selectedApps = prefs.getStringList('blocked_apps');

      print("🔌 [IKEV2] Attempting IKEv2 connection...");
      print("🔧 [IKEV2] Server: $server");
      print("🔧 [IKEV2] Username: $username");
      print("🔧 [IKEV2] Platform: ${Platform.operatingSystem}");
      print("🔧 [IKEV2] Kill Switch: ${isKillSwitch ?? false}");
      
      try {
        // Route to appropriate platform implementation
        if (Platform.isWindows) {
          print("🪟 [IKEV2] Using Windows implementation (WireGuard-based IKEv2)");
          final success = await _windowsVpn.connectIkev2EAP(
            server: server,
            username: username,
            password: password,
            vpnServerDomain: vpnServerDomain,
            vpnServerName: vpnServerName,
            selectedApps: selectedApps,
            killSwitch: isKillSwitch ?? false,
          );
          
          if (success) {
            print("✅ [IKEV2] Windows VPN connection established");
            log('IKEv2 connection successful on Windows');
          } else {
            print("❌ [IKEV2] Windows VPN connection failed: ${_windowsVpn.lastError}");
            log('IKEv2 failed on Windows: ${_windowsVpn.lastError}');
          }
          return success;
        } else if (Platform.isAndroid || Platform.isIOS) {
          // Use native flutter_vpn on Android/iOS
          print("📱 [IKEV2] Using native flutter_vpn (Android/iOS)");
          await FlutterVpn.connectIkev2EAP(
            server: server,
            username: username,
            password: password,
            selectedApps: selectedApps,
            killSwitch: isKillSwitch ?? false,
          );

          print("✅ [IKEV2] Connect method called successfully");
          
          // Wait a bit for connection to establish
          print("⏳ [IKEV2] Waiting for connection to establish...");
          await Future.delayed(const Duration(seconds: 1));
          
          // Check connection state
          try {
            final state = await FlutterVpn.currentState;
            print("📊 [IKEV2] Current VPN state: $state");
          } catch (e) {
            print("⚠️  [IKEV2] Could not check state: $e");
          }
          
          print("✅ [IKEV2] IKEv2 connection initiated");
          log('IKEv2 connection initiated: $server');
          return true;
        } else {
          print("❌ [IKEV2] Unsupported platform: ${Platform.operatingSystem}");
          return false;
        }
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('MissingPluginException')) {
          print("❌ [IKEV2] CRITICAL: flutter_vpn plugin not implemented for this platform!");
          print("❌ [IKEV2] IKEv2/VPN support is only available on Android and iOS");
          print("❌ [IKEV2] For Windows, using WireGuard-based VPN implementation");
          log('CRITICAL: VPN not supported on this platform - flutter_vpn plugin missing');
        } else {
          print("❌ [IKEV2] Connection failed: $errorMsg");
        }
        rethrow;
      }
    } catch (e) {
      print("❌ [IKEV2] Exception: $e");
      log('Error connecting to IKEv2: $e');
      rethrow;
    }
  }

  Future<bool> disconnect() async {
    try {
      if (Platform.isWindows) {
        print("🪟 [IKEV2] Disconnecting Windows VPN...");
        return await _windowsVpn.disconnect();
      } else if (Platform.isAndroid || Platform.isIOS) {
        print("📱 [IKEV2] Disconnecting native VPN...");
        await FlutterVpn.disconnect();
        return true;
      }
      return false;
    } catch (e) {
      log('Error disconnecting IKEv2: $e');
      return false;
    }
  }
}
