// ignore_for_file: file_names, use_build_context_synchronously
import 'dart:convert';
import 'package:get/get.dart';
import 'dart:async' show Timer;
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter_vpn/state.dart';
import 'package:http/http.dart' as http;
import 'package:dart_ping/dart_ping.dart';
import 'package:http/http.dart' show post;
import 'dart:io' show Platform, InternetAddress;
import 'package:safenetvpn/Views/premium/premium.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vpn/flutter_vpn.dart' show FlutterVpn;
import 'package:safenetvpn/Defaults/defaults.dart' show Defaults;
import 'package:safenetvpn/Models/server.dart' show Server, ServerResponse;
import 'package:safenetvpn/Engines/wireguardEngine.dart' show WireguardEngine;
import 'package:safenetvpn/Engines/ikeav2Engine.dart' show Ikeav2EngineAndIpSec;
import 'package:safenetvpn/Widgets/customSnackBar.dart' show showCustomSnackBar;
import 'package:wireguard_flutter/wireguard_flutter.dart' show WireGuardFlutter;
import 'package:safenetvpn/Models/plan.dart' show ActivePlanResponse, PlanDetail, Subscription;
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart' show VpnStage, WireGuardFlutterInterface;

enum Protocol { wireguard, ikeav2 }

enum VpnConnectedStates { connecting, connected, disconnected, disconnecting }

class HomeRepo extends GetxController {
  var servers = <Server>[].obs;
  var filteredServers = <Server>[].obs;
  var serverModel = ServerResponse(servers: [], status: true).obs;
  var isGettingConfig = false.obs;
  var selectedServerIndex = 0.obs;
  var selectedSubServerIndex = 0.obs;
  var protocol = Protocol.ikeav2.obs;
  var ikeav2Engine = Ikeav2EngineAndIpSec();
  var vpnConnectionState = VpnConnectedStates.disconnected.obs;
  var searchText = ''.obs;
  var isSearching = false.obs;
  var isAutoConnectEnabled = false.obs;
  var killSwitchEnabled = false.obs;
  var isloading = false.obs;
  var isPremium = false.obs;
  var expiryDate = DateTime.now().obs;
  var plan = Rxn<PlanDetail>();
  var subscription= Rxn<Subscription>();
  var isAdblock = false.obs;
  var subjectController = TextEditingController().obs;
  var messageController = TextEditingController().obs;

  Protocol selectedProtocol = Protocol.ikeav2;

  bool _autoSelectProtocol = false;
  bool get autoSelectProtocol => _autoSelectProtocol;
  var selectedBottomIndex = 0.obs;

  final WireGuardFlutterInterface _wireguard = WireGuardFlutter.instance;
  final WireguardEngine _wireguardEngine = WireguardEngine();

  // Reactive speeds for fine-grained rebuilds
  final RxString downloadSpeed = "0.0".obs;
  final RxString uploadSpeed = "0.0".obs;
  final RxString pingSpeed = "0.0".obs;

  Timer? speedUpdateTimer;
  Timer? _stageTimer;

  onItemTapped(int index) {
    selectedBottomIndex.value = index;
    update();
  }

  setProtocol(Protocol protocol) async {
    selectedProtocol = protocol;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'selectedProtocol',
      protocol == Protocol.ikeav2 ? 'ikeav2' : 'wireguard',
    );
    update();

    // Ensure stage polling reacts to protocol change
    startGettingStages();
  }

  void setSearchText(String text, String selectedTab) {
    searchText.value = text;
    filterServers(selectedTab);
  }

  // Pass in the selected tab (like "All Servers", "Premium", "Free", "Favourites")
  void filterServers(String selectedTab) {
    // Start with all servers
    var results = servers.toList();

    //  Filter by tab
    if (selectedTab == "Premium") {
      results = results
          .where((s) => s.type.toLowerCase() == "premium")
          .toList();
    } else if (selectedTab == "Free") {
      results = results.where((s) => s.type.toLowerCase() == "free").toList();
    }

    //  Filter by search text
    if (searchText.value.trim().isNotEmpty) {
      results = results
          .where(
            (s) =>
                s.name.toLowerCase().contains(searchText.value.toLowerCase()),
          )
          .toList();
      isSearching.value = true;
    } else {
      isSearching.value = false;
    }

    // Update filtered list
    filteredServers.assignAll(results);
  }

  setAutoSelectProtocol(bool value) async {
    _autoSelectProtocol = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoSelectProtocol', value);
    if (value) {
      await setProtocol(Protocol.ikeav2);
    }
    update();
  }

  Future<void> loadProtocolFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? proto = prefs.getString('selectedProtocol');
    bool autoSelect = prefs.getBool('autoSelectProtocol') ?? false;
    if (proto == 'wireguard') {
      selectedProtocol = Protocol.wireguard;
    } else {
      selectedProtocol = Protocol.ikeav2;
    }
    _autoSelectProtocol = autoSelect;
    update();

    startGettingStages();
  }

  loadserverFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedServer = prefs.getInt('selectedServer') ?? 0;
    final savedSubServer = prefs.getInt('selectedSubServer') ?? 0;

    selectedServerIndex.value = savedServer;
    selectedSubServerIndex.value = savedSubServer;
  }

  autoConnect(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAutoConnectEnabled.value = prefs.getBool('autoConnect') ?? false;
    log(isAutoConnectEnabled.value.toString());
    if (isAutoConnectEnabled.value &&
        vpnConnectionState.value == VpnConnectedStates.disconnected) {
      await toggleVpn(context);
      log(isAutoConnectEnabled.value.toString());
      update();
    } else if (vpnConnectionState.value == VpnConnectedStates.connected) {
      return;
    }
  }

  toggleAutoConnectState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAutoConnectEnabled.value = !isAutoConnectEnabled.value;
    log(isAutoConnectEnabled.value.toString());
    prefs.setBool('autoConnect', isAutoConnectEnabled.value);
    update();
  }

  toggleKillSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    killSwitchEnabled.value = !killSwitchEnabled.value;
    log(killSwitchEnabled.value.toString());
    prefs.setBool('killSwitchEnabled', killSwitchEnabled.value);
    log("KillSwitch toggled: $killSwitchEnabled.value");
    update();
  }

  myKillSwitch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    killSwitchEnabled.value = prefs.getBool('killSwitchEnabled') ?? false;
    update();
  }

  Future<int> pingIPAddress(String ip) async {
    try {
      final ping = Ping(ip, count: 1, timeout: 2);
      final response = await ping.stream.first;
      if (response.response != null && response.response!.time != null) {
        return response.response!.time!.inMilliseconds;
      }
      return 999; // Return a high value if ping fails
    } catch (e) {
      log("Ping error for $ip: $e");
      return 999;
    }
  }

  // Ping all servers and update their latency
  Future<void> pingAllServers() async {
    try {
      isloading.value = true;
      log("Pinging all servers...");

      for (var server in servers) {
        for (var subServer in server.subServers) {
          final ip = subServer.vpsServer.domain;
          if (ip.isNotEmpty) {
            int latency = await pingIPAddress(ip);
            subServer.vpsServer.latency = latency;
          } else {
            subServer.vpsServer.latency = 999;
          }
        }
      }
      // Optionally, sort servers by latency or update filteredServers
      // filteredServers = [...servers];
    } catch (e) {
      log("Error pinging servers: $e");
    } finally {
      isloading.value = false;
    }
  }

  changeCountry(int value, int val, BuildContext context) async {
    // Check if this server is premium
    final server = servers[value]; // assuming servers list is available here
    if (server.type.toLowerCase() == "premium" && !isPremium.value) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => Premium()));
      return; 
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    log("Changing server to index: $value, sub-index: $val");

    selectedServerIndex.value = value;
    selectedSubServerIndex.value = val;

    await prefs.setInt('selectedServer', value);
    await prefs.setInt('selectedSubServer', val);

    // Wait for values to properly reflect
    await Future.delayed(Duration(milliseconds: 700));

    // If vpn is connected then first disconnect then toggle vpn
    if (vpnConnectionState.value == VpnConnectedStates.connected ||
        vpnConnectionState.value == VpnConnectedStates.connecting) {
      toggleVpn(context);
      await Future.delayed(Duration(seconds: 1));
    }

    onItemTapped(0);
    update();

    await toggleVpn(context);
  }

  Future<void> getPremium() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  String? token = preferences.getString('access_token');

  log("=== PREMIUM CHECK START ===");
  log("Token: $token");

  if (token == null) {
    log("Token is null. Redirecting to login.");
    isPremium.value = false;
    subscription.value = null;
    update();
    return;
  }

  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  try {
    final response = await http.get(
      Uri.parse(Defaults.PURCHASE_URL),
      headers: headers,
    );
    log("Response premium body: ${response.body}");

    if (response.statusCode != 200) {
      log("Error fetching premium data.");
      isPremium.value = false;
      subscription.value = null;
      update();
      return;
    }

    final data = jsonDecode(response.body);
    final activePlanResponse = ActivePlanResponse.fromJson(data);

    if (activePlanResponse.status && activePlanResponse.subscription != null) {
      final sub = activePlanResponse.subscription!;
      subscription.value = sub;

      // Parse expiry date from ends_at
      DateTime expiry = DateTime.tryParse(sub.endsAt) ?? DateTime.now();
      DateTime graceExpiry = DateTime.tryParse(sub.graceEndsAt) ?? expiry; // fallback

      expiryDate.value = expiry;

      if (graceExpiry.isAfter(DateTime.now())) {
        isPremium.value = true;
        // log(
        //   "Premium active. Ends at: ${expiry.toIso8601String()} | Grace until: ${graceExpiry.toIso8601String()}",
        // );
        // log(
        //   "Days left (including grace): ${graceExpiry.difference(DateTime.now()).inDays}",
        // );
      } else {
        isPremium.value = false;
        log("Premium expired completely.");
      }
    } else {
      isPremium.value = false;
      subscription.value = null;
      log("No active plan found.");
    }

    update();
  } catch (e) {
    log("Exception occurred while fetching premium data: $e");
    isPremium.value = false;
    subscription.value = null;
    update();
  }
}


  getServers(bool net) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('access_token');
    log("Token $token");

    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var platform = Platform.isAndroid
        ? "android"
        : Platform.isIOS
        ? "ios"
        : Platform.isWindows
        ? "windows"
        : Platform.isMacOS
        ? "macos"
        : "linux";

    if (net) {
      var response = await http.get(
        Uri.parse("${Defaults.GET_SERVERS}?platform=$platform"),
        headers: headers,
      );
      log("Data ${response.body}");
      var data = jsonDecode(response.body);

      if (data["status"] == true) {
        servers.clear();
        log("Data $data");

        for (var server in data["servers"]) {
          servers.add(Server.fromJson(server));
        }

        log("Servers fetched successfully");

        /// FIX: update filteredServers properly
        filteredServers.assignAll(servers);

        log(servers.length.toString());
        await pingAllServers();
        if (vpnConnectionState.value == VpnConnectedStates.connected) {
          startSpeedMonitoring();
        }
      }
    } else {
      servers.clear();
      filteredServers.clear(); // keep them in sync
    }
  }

  // getVpsServers() async {
  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   var headers = {
  //     'Content-Type': 'application/json',
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${preferences.getString('access_token')}',
  //   };

  //   var platform = Platform.isAndroid
  //       ? "android"
  //       : Platform.isIOS
  //       ? "ios"
  //       : Platform.isWindows
  //       ? "windows"
  //       : Platform.isMacOS
  //       ? "macos"
  //       : "linux";

  //   var response = await http.get(
  //     Uri.parse(Defaults.VPS_SERVERS),
  //     headers: headers,
  //   );

  //   var data = jsonDecode(response.body);
  //   if (data["status"] == true) {
  //     // Handle successful response
  //     _vpsServers.clear();
  //     for (var server in data["data"]) {
  //       _vpsServers.add(VpsServer.fromJson(server));
  //     }
  //     notifyListeners();
  //   } else {
  //     log("Failed to fetch VPS servers");
  //   }
  // }

  Future<bool> registerUserInVPS(String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('name');
      final String? password = prefs.getString('password');

      log("Name is $name");
      log("Password is $password");

      if (name == null || password == null) {
        log("Name or password is missing");
        return false;
      }

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isLinux
          ? 'linux'
          : 'desktop';

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      log("Name_platform is that ${name}_$platform");
      log("Password is that $password");

      final firstResponse = await post(
        Uri.parse("$serverUrl/api/ikev2/clients/generate"),
        headers: headers,
        body: jsonEncode({"name": "${name}_$platform", "password": password}),
      );

      final secondResponse = await post(
        Uri.parse("$serverUrl/api/clients/generate"),
        headers: headers,
        body: jsonEncode({"name": "${name}_$platform"}),
      );

      final firstBody = jsonDecode(firstResponse.body);
      final secondBody = jsonDecode(secondResponse.body);

      if (firstBody["error"] != null) {
        final deleteResponse = await http.delete(
          Uri.parse("$serverUrl/api/ikev2/clients/${name}_$platform"),
          headers: headers,
        );

        log("Status ikev2 ${deleteResponse.statusCode}");
        log("Status body ${deleteResponse.body}");

        if (deleteResponse.statusCode == 200) {
          final newResponse = await http.post(
            Uri.parse("$serverUrl/api/ikev2/clients/generate"),
            headers: headers,
            body: jsonEncode({
              "name": "${name}_$platform",
              "password": password,
            }),
          );

          log("Response is that ${newResponse.body}");

          final responseBody = jsonDecode(newResponse.body);
          if (responseBody["success"] == true) {
            log("Registered successfully on $serverUrl");
            return true;
          } else {
            log("Registration failed on $serverUrl");
            return false;
          }
        }
      }

      if (secondBody["error"] != null) {
        final deleteResponse = await http.delete(
          Uri.parse("$serverUrl/api/clients/${name}_$platform"),
          headers: headers,
        );
        log("Status wireguard ${deleteResponse.statusCode}");
        log("Status body ${deleteResponse.body}");
        if (deleteResponse.statusCode == 200) {
          final newResponse = await http.post(
            Uri.parse("$serverUrl/api/clients/generate"),
            headers: headers,
            body: jsonEncode({
              "name": "${name}_$platform",
              "password": password,
            }),
          );
          log("Response is that ${newResponse.body}");

          final responseBody = jsonDecode(newResponse.body);
          if (responseBody["success"] == true) {
            log("Registered successfully on $serverUrl");
            return true;
          } else {
            log("Registration failed on $serverUrl");
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      log("Exception during registration on $serverUrl: $e");
      return false;
    }
  }

  Future<void> toggleVpn(BuildContext context) async {
    // Logic to toggle VPN connection
    var domain = gettingTheDomain();
    log("Domain $domain");
    if (selectedProtocol == Protocol.wireguard) {
      if (vpnConnectionState.value == VpnConnectedStates.connected ||
          vpnConnectionState.value == VpnConnectedStates.connecting) {
        await disconnectWireguard();
      } else if (vpnConnectionState.value == VpnConnectedStates.disconnected) {
        await connectWireguard(domain, context);
      }
    } else if (selectedProtocol == Protocol.ikeav2) {
      if (vpnConnectionState.value == VpnConnectedStates.connected ||
          vpnConnectionState.value == VpnConnectedStates.connecting) {
        await disconnectIkeav2(context);
      } else if (vpnConnectionState.value == VpnConnectedStates.disconnected) {
        await connectIkeav2(domain, context);
      }
    }
  }

  gettingTheDomain() {
    return servers[selectedServerIndex.value]
        .subServers[selectedSubServerIndex.value]
        .vpsServer
        .domain;
  }

  startGettingStages() {
    // Avoid spawning multiple timers
    _stageTimer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (selectedProtocol == Protocol.wireguard) {
        await listenWireguard();
      } else if (selectedProtocol == Protocol.ikeav2) {
        await listenIkeav2andIpsecStages();
      }
    });
  }

  Future<void> listenIkeav2andIpsecStages() async {
    FlutterVpn.currentState.then((FlutterVpnState status) {
      if (isGettingConfig.value) {
        vpnConnectionState.value = VpnConnectedStates.connecting;
        return;
      } else {
        switch (status) {
          case FlutterVpnState.connecting:
            vpnConnectionState.value = VpnConnectedStates.connecting;
            break;
          case FlutterVpnState.connected:
            vpnConnectionState.value = VpnConnectedStates.connected;
            break;
          case FlutterVpnState.disconnecting:
            vpnConnectionState.value = VpnConnectedStates.disconnecting;
            break;
          case FlutterVpnState.disconnected:
            vpnConnectionState.value = VpnConnectedStates.disconnected;
            break;
          default:
            vpnConnectionState.value = VpnConnectedStates.disconnected;
            break;
        }
        log("IKEv2 Stage: $vpnConnectionState");
        update();
      }
    });
  }

  Future<VpnConnectedStates> listenWireguard() async {
    try {
      VpnConnectedStates newStage = vpnConnectionState.value;
      final value = await _wireguard.stage();
      if (value == VpnStage.connected) {
        newStage = VpnConnectedStates.connected;
      } else if (value == VpnStage.connecting || isGettingConfig.value) {
        newStage = VpnConnectedStates.connecting;
      } else if (value == VpnStage.disconnected) {
        newStage = VpnConnectedStates.disconnected;
      } else if (value == VpnStage.disconnecting) {
        newStage = VpnConnectedStates.disconnecting;
      } else {
        newStage = VpnConnectedStates.disconnected;
      }
      vpnConnectionState.value = newStage;
      log("WireGuard Stage: $vpnConnectionState");
      update();

      return newStage;
    } catch (e) {
      log("Error getting WireGuard stage: $e");
      vpnConnectionState.value = VpnConnectedStates.disconnected;
      update();
      return VpnConnectedStates.disconnected;
    }
  }

  Future<String?> getSelectedWireguardVPNConfig(
    String serverUrl,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('name');

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'macos';

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      final response = await http.get(
        Uri.parse("$serverUrl/api/clients/${name}_$platform"),
        headers: headers,
      );

      log("Response status code: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final String wireguardConfig = responseData['config'];
        final String ipAddress = responseData['ip'];
        final String clientName = responseData['name'];
        final String qrCode = responseData['qr_code'];

        await prefs.setString('current_wireguard_config', wireguardConfig);
        await prefs.setString('current_wireguard_ip', ipAddress);
        await prefs.setString('current_wireguard_client', clientName);
        await prefs.setString('current_wireguard_qr', qrCode);
        await prefs.setString('current_wireguard_server_url', serverUrl);

        log("WireGuard config received: $wireguardConfig");
        log("WireGuard config saved successfully");

        return wireguardConfig;
      } else {
        log("Failed to get WireGuard config: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("Error getting WireGuard config: $e");
      return null;
    }
  }

  Future<bool> connectWireguard(String ip, BuildContext context) async {
    try {
      isloading.value = true;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());

      isGettingConfig.value = true;
      vpnConnectionState.value = VpnConnectedStates.connecting;
      update();

      // Add a short delay to allow UI to show 'connecting' state
      await Future.delayed(const Duration(milliseconds: 700));

      var isRegistered = await registerUserInVPS('http://$ip:5000');
      if (!isRegistered) {
        log("Failed to register user in VPS");
        isGettingConfig.value = false;
        isloading.value = false;
        update();

        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connecting Error',
          'Failed to connect server is not responding!',
          Colors.red,
        );
        return false;
      }
      final config = await getSelectedWireguardVPNConfig(
        'http://$ip:5000',
        context,
      );

      final success = await _wireguardEngine.startWireguard(
        server: ip,
        serverName: 'United States',
        wireguardConfig: config!,
      );
      startSpeedMonitoring();

      isGettingConfig.value = false;
      isloading.value = false;
      update();

      return success;
    } catch (e) {
      log("Error in connectWireguard: $e");
      isloading.value = false;
      update();

      return false;
    }
  }

  Future<bool> disconnectWireguard() async {
    try {
      isloading.value = true;
      vpnConnectionState.value = VpnConnectedStates.disconnecting;
      update();

      final success = await _wireguardEngine.stopWireguard();

      if (success) {
        log("Disconnected from WireGuard VPN");
        isloading.value = false;
        vpnConnectionState.value = VpnConnectedStates.disconnected;
        stopSpeedMonitoring();
        update();

        return true;
      } else {
        isloading.value = false;
        vpnConnectionState.value = VpnConnectedStates.disconnected;
        update();

        return false;
      }
    } catch (e) {
      log("Error in disconnectWireguard: $e");
      isloading.value = false;
      vpnConnectionState.value = VpnConnectedStates.disconnected;
      update();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update();
      });
      return false;
    }
  }

  Future<void> connectIkeav2(String ip, BuildContext context) async {
    try {
      log("Connecting to IKEv2 VPN at $ip");
      isGettingConfig.value = true;
      vpnConnectionState.value = VpnConnectedStates.connecting;
      update();

      bool isRegistered = await registerUserInVPS('http://$ip:5000');
      if (!isRegistered) {
        log("Failed to register user in VPS");
        isGettingConfig.value = false;
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connecting Error',
          'Failed to connect server is not responding!',
          Colors.red,
        );
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());
      // Keep _isGettingConfig true until after initiating connection

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'macos';

      var name = prefs.getString('name') ?? '';
      var password = prefs.getString('password') ?? '';

      var username = "${name}_$platform";
      log("Username is $username");
      log("Password is $password");

      if (username.isEmpty || password.isEmpty) {
        log("Username or password is missing");
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connection Error',
          'Username or password is missing',
          Colors.red,
        );
        return;
      }

      await ikeav2Engine.connectTheIKEAV2(ip, username, password);
      startSpeedMonitoring();

      log("IKEv2 VPN connected successfully");
      isGettingConfig.value = false;
      update();
    } catch (e) {
      log("Error connecting IKEv2: $e");
      isGettingConfig.value = false;
      vpnConnectionState.value = VpnConnectedStates.disconnected;
      update();

      showCustomSnackBar(
        context,
        EvaIcons.infoOutline,
        'Connection Error',
        e.toString(),
        Colors.red,
      );
    }
  }

  Future<void> disconnectIkeav2(BuildContext context) async {
    try {
      log("Disconnecting IKEv2");
      vpnConnectionState.value = VpnConnectedStates.disconnecting;
      update();

      await ikeav2Engine.disconnect();
      stopSpeedMonitoring();

      // Add a short delay to ensure engine is ready for next connection
      await Future.delayed(const Duration(milliseconds: 700));

      log("IKEv2 disconnected successfully");
      vpnConnectionState.value = VpnConnectedStates.disconnected;
      update();

      showCustomSnackBar(
        context,
        EvaIcons.checkmarkCircle2Outline,
        'Disconnection Success',
        'IKEv2 disconnected successfully',
        Colors.red,
      );
    } catch (e) {
      log("Error disconnecting IKEv2: $e");
      vpnConnectionState.value = VpnConnectedStates.disconnected;
      update();

      showCustomSnackBar(
        context,
        EvaIcons.infoOutline,
        'Disconnection Error',
        e.toString(),
        Colors.red,
      );
    }
  }

  // Check network speed
  Future<Map<String, String>> checkNetworkSpeed() async {
    var speed = {'download': "0", 'upload': "0"};
    final url = 'https://youtube.com';
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final elapsed = stopwatch.elapsedMilliseconds;
        // Calculate speed in Mbps (Megabits per second)
        final speedInMbps =
            ((response.bodyBytes.length / 1024 / 1024) / (elapsed / 1000)) *
            8 /
            3;
        String download = speedInMbps.toStringAsFixed(2);
        String upload = (speedInMbps + 1.36).toStringAsFixed(2);
        speed = {'download': download, 'upload': upload};
      }
      return speed;
    } catch (e) {
      log(e.toString());
      return speed;
    }
  }

  void startSpeedMonitoring() {
    log("Starting speed monitoring");
    stopSpeedMonitoring(); // Stop any existing timer

    speedUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (vpnConnectionState.value == VpnConnectedStates.connected) {
        log("Monitoring speeds...");
        var speeds = await checkNetworkSpeed();
        log("Speeds (Mbps): $speeds");

        // Convert Mbps to Kbps
        double downloadMbps =
            double.tryParse(speeds['download'] ?? "0.0") ?? 0.0;
        double uploadMbps = double.tryParse(speeds['upload'] ?? "0.0") ?? 0.0;

        downloadSpeed.value = (downloadMbps * 1000).toStringAsFixed(2); // kbps
        uploadSpeed.value = (uploadMbps * 1000).toStringAsFixed(2); // kbps

        // Log the speeds in kbps
        log("Download Speed: $downloadSpeed Kbps");
        log("Upload Speed: $uploadSpeed Kbps");

        // Get ping measurement
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            final stopwatch = Stopwatch()..start();
            await http.get(Uri.parse('https://google.com'));
            stopwatch.stop();
            pingSpeed.value = stopwatch.elapsedMilliseconds.toString();
          }
        } catch (_) {
          pingSpeed.value = "0";
        }
        log("Ping Speed: $pingSpeed ms");
        update();
        // Ensure UI updates to reflect new speeds
      } else {
        // Reset values when not connected
        downloadSpeed.value = "0.0";
        uploadSpeed.value = "0.0";
        pingSpeed.value = "0";
        // Notify UI of reset values
        update();
      }
    });
  }

  // Method to stop monitoring when disconnected
  void stopSpeedMonitoring() {
    speedUpdateTimer?.cancel();
    speedUpdateTimer = null;
  }

  getPlans() async {
    try {
      log("Fetching plans...");
      isloading.value = true;
      update();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      // Implement plan fetching logic here
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      var response = await http.get(
        Uri.parse(Defaults.ALL_PLANS),
        headers: headers,
      );
      log(response.body);
      var data = jsonDecode(response.body);
      log("Plans response: $data");
      if (data["status"] == true) {
        // Handle successful response
        log("Plans fetched successfully");
        plan.value = PlanDetail.fromJson(data["plans"]);
        update();

        // Parse and store plans as needed
      } else {
        log("Failed to fetch plans");
      }
      isloading.value = false;
      update();
    } catch (error) {
      log("Exception occurred while fetching plans: $error");
    }
  }
}
