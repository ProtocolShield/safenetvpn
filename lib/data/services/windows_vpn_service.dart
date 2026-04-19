// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wireguard_flutter/wireguard_flutter.dart';

/// Windows VPN Service - Handles VPN connections on Windows platform
/// Since flutter_vpn doesn't support Windows, we use WireGuard as the tunnel mechanism
class WindowsVpnService {
  static final WindowsVpnService _instance = WindowsVpnService._internal();

  factory WindowsVpnService() {
    return _instance;
  }

  WindowsVpnService._internal();

  final _wireguard = WireGuardFlutter.instance;
  bool _isConnected = false;
  String _connectedServer = '';
  String _lastError = '';

  bool get isConnected => _isConnected;
  String get connectedServer => _connectedServer;
  String get lastError => _lastError;

  /// Connect to VPN using IKEv2-like authentication via WireGuard tunnel
  /// This simulates IKEv2 behavior on Windows by using WireGuard as the transport layer
  Future<bool> connectIkev2EAP({
    required String server,
    required String username,
    required String password,
    required String vpnServerDomain,
    required String vpnServerName,
    List<String>? selectedApps,
    bool killSwitch = false,
  }) async {
    try {
      print("🔌 [WIN-VPN] Initiating Windows VPN connection (IKEv2 emulation via WireGuard)");
      print("🔧 [WIN-VPN] Server: $server | Username: $username | VPN: $vpnServerName");

      // Step 1: Get WireGuard configuration from the VPS server
      print("📥 [WIN-VPN] Fetching WireGuard configuration from VPS...");
      final wireguardConfig = await _getWireGuardConfig(
        vpsUrl: "http://$server:5000",
        username: username,
        password: password,
      );

      if (wireguardConfig == null || wireguardConfig.isEmpty) {
        _lastError = "Failed to fetch WireGuard configuration";
        print("❌ [WIN-VPN] $_lastError");
        return false;
      }

      print("✅ [WIN-VPN] WireGuard configuration retrieved (${wireguardConfig.length} bytes)");

      // Step 2: Parse and validate the WireGuard config
      print("🔍 [WIN-VPN] Parsing WireGuard configuration...");
      if (!_validateWireGuardConfig(wireguardConfig)) {
        _lastError = "Invalid WireGuard configuration format";
        print("❌ [WIN-VPN] $_lastError");
        return false;
      }

      print("✅ [WIN-VPN] Configuration is valid");

      // Step 3: Connect via WireGuard
      print("🔗 [WIN-VPN] Establishing WireGuard tunnel to $vpnServerName...");
      try {
        await _wireguard.startVpn(
          serverAddress: server,
          wgQuickConfig: wireguardConfig,
          providerBundleIdentifier: "com.safenetvpn.wireguard",
        );

        print("✅ [WIN-VPN] WireGuard tunnel connected!");

        // Step 4: Save connection state
        _isConnected = true;
        _connectedServer = vpnServerName;
        _lastError = '';

        // Step 5: Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('windows_vpn_connected', true);
        await prefs.setString('windows_vpn_server', vpnServerName);
        await prefs.setString('windows_vpn_username', username);
        await prefs.setString('windows_vpn_domain', vpnServerDomain);

        print("✅ [WIN-VPN] Connection successful! VPN active on $vpnServerName");
        developer.log(
          'Windows VPN connected: $vpnServerName',
          name: 'WindowsVpnService',
        );

        return true;
      } catch (e) {
        _lastError = "WireGuard connection failed: $e";
        print("❌ [WIN-VPN] $_lastError");
        developer.log(
          'WireGuard connection error: $e',
          name: 'WindowsVpnService',
        );
        return false;
      }
    } catch (e) {
      _lastError = "Connection error: $e";
      print("❌ [WIN-VPN] $_lastError");
      developer.log(
        'Windows VPN error: $e',
        name: 'WindowsVpnService',
      );
      return false;
    }
  }

  /// Fetch WireGuard configuration from VPS server
  Future<String?> _getWireGuardConfig({
    required String vpsUrl,
    required String username,
    required String password,
  }) async {
    try {
      print("📡 [WIN-VPN] Requesting WireGuard config from $vpsUrl/api/clients/config");

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      // Try GET request first (standard for config retrieval)
      final response = await http
          .get(
            Uri.parse("$vpsUrl/api/clients/config"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print("📊 [WIN-VPN] WireGuard config response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Check if we got a config string directly or nested in an object
        String config = '';
        if (body is String) {
          config = body;
        } else if (body is Map && body.containsKey('config')) {
          config = body['config'];
        } else if (body is Map && body.containsKey('data')) {
          config = body['data'];
        } else {
          // Try to use the entire response as config
          config = jsonEncode(body);
        }

        if (config.isNotEmpty) {
          print("✅ [WIN-VPN] Got WireGuard config (${config.length} bytes)");
          return config;
        }
      }

      print("❌ [WIN-VPN] Failed to get config: ${response.statusCode} ${response.body}");
      return null;
    } catch (e) {
      print("❌ [WIN-VPN] WireGuard config request failed: $e");
      developer.log(
        'WireGuard config fetch error: $e',
        name: 'WindowsVpnService',
      );
      return null;
    }
  }

  /// Validate WireGuard configuration format
  bool _validateWireGuardConfig(String config) {
    try {
      // Check if config contains required sections
      final hasInterface = config.contains('[Interface]');
      final hasPeer = config.contains('[Peer]');

      if (!hasInterface || !hasPeer) {
        print("❌ [WIN-VPN] Config missing required sections");
        return false;
      }

      // Check for required fields
      final hasPrivateKey = config.contains('PrivateKey');
      final hasPublicKey = config.contains('PublicKey');
      final hasEndpoint = config.contains('Endpoint');

      if (!hasPrivateKey || !hasPublicKey || !hasEndpoint) {
        print("❌ [WIN-VPN] Config missing required fields");
        return false;
      }

      print("✅ [WIN-VPN] Config structure validated");
      return true;
    } catch (e) {
      print("❌ [WIN-VPN] Config validation error: $e");
      return false;
    }
  }

  /// Disconnect from VPN
  Future<bool> disconnect() async {
    try {
      print("🔌 [WIN-VPN] Disconnecting from VPN...");
      await _wireguard.stopVpn();

      _isConnected = false;
      _connectedServer = '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('windows_vpn_connected', false);

      print("✅ [WIN-VPN] Disconnected successfully");
      developer.log(
        'Windows VPN disconnected',
        name: 'WindowsVpnService',
      );

      return true;
    } catch (e) {
      _lastError = "Disconnect failed: $e";
      print("❌ [WIN-VPN] $_lastError");
      developer.log(
        'Disconnect error: $e',
        name: 'WindowsVpnService',
      );
      return false;
    }
  }

  /// Get current VPN status
  Future<int> getCurrentState() async {
    try {
      // 0 = disconnected, 1 = connecting, 2 = connected, 3 = disconnecting
      if (_isConnected) {
        return 2; // connected
      }
      return 0; // disconnected
    } catch (e) {
      developer.log(
        'Error getting VPN state: $e',
        name: 'WindowsVpnService',
      );
      return 0;
    }
  }

  /// Prepare VPN (on Windows, this is usually a no-op since WireGuard doesn't need prep)
  Future<bool> prepare() async {
    try {
      print("🔧 [WIN-VPN] Preparing VPN environment...");
      // WireGuard on Windows doesn't require special preparation
      // This is mainly for Android compatibility
      print("✅ [WIN-VPN] VPN environment ready");
      return true;
    } catch (e) {
      developer.log(
        'Preparation error: $e',
        name: 'WindowsVpnService',
      );
      return false;
    }
  }

  /// Cleanup - restore saved connection state on app restart
  Future<void> cleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isConnected = prefs.getBool('windows_vpn_connected') ?? false;
      _connectedServer = prefs.getString('windows_vpn_server') ?? '';

      if (_isConnected) {
        print("🔍 [WIN-VPN] Restored connection state: $_connectedServer");
      }
    } catch (e) {
      developer.log(
        'Cleanup error: $e',
        name: 'WindowsVpnService',
      );
    }
  }
}
