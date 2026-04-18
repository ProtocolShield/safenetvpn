// ignore_for_file: file_names, use_build_context_synchronously
import 'dart:convert';
import 'package:get/get.dart';
import 'dart:async' show Timer, TimeoutException;
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:flutter_vpn/state.dart';
import 'package:http/http.dart' as http;
import 'package:dart_ping/dart_ping.dart';

import 'package:safenetvpn/domain/models/plan.dart';
import 'package:safenetvpn/ui/core/ui/auth/auth.dart' show Auth;
import 'dart:io' show Platform, InternetAddress;

import 'package:safenetvpn/utils/utils.dart' show Utils;
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vpn/flutter_vpn.dart' show FlutterVpn;
import 'package:safenetvpn/ui/core/ui/premium/premium.dart' show Premium;
import 'package:wireguard_flutter/wireguard_flutter.dart' show WireGuardFlutter;
import 'package:safenetvpn/domain/models/server.dart'
    show Server, ServerResponse, VpsServer, SubServer;
import 'package:safenetvpn/ui/widgets/customSnackBar.dart'
    show showCustomSnackBar;
import 'package:safenetvpn/data/services/wireguardServices.dart'
    show Wireguardservices;
import 'package:safenetvpn/data/services/ikeav2Services.dart'
    show Ikeav2EngineAndIpSecServices;
import 'package:safenetvpn/domain/models/subscription.dart'
    show ActivePlanResponse, Subscription;
import 'package:wireguard_flutter/wireguard_flutter_platform_interface.dart'
    show VpnStage, WireGuardFlutterInterface;
import 'package:safenetvpn/services/analytics_service.dart';

enum Proto { wireguard, ikeav2 }

enum MyVpnConnectState { connecting, connected, disconnected, disconnecting }

class HomeGateModel extends GetxController {
  var srvList = <Server>[].obs;
  var srvFiltered = <Server>[].obs;
  var serverModel = ServerResponse(servers: [], status: true).obs;
  var cfgLoading = false.obs;
  var srvIndex = 0.obs;
  var subSrvIndex = 0.obs;
  var protocol = Proto.wireguard.obs;
  var ikeav2Engine = Ikeav2EngineAndIpSecServices();
  var vpnConnectionState = MyVpnConnectState.disconnected.obs;
  var queryText = ''.obs;
  var queryActive = false.obs;
  var autoConnectOn = false.obs;
  var killSwitchOn = false.obs;
  var busyFlag = false.obs;
  var proActive = false.obs;
  var expiryAt = DateTime.now().obs;
  var plans = <PlanModel>[].obs;

  var subscription = Rxn<Subscription>();
  var isAdblock = false.obs;
  var fbSubjectCtrl = TextEditingController().obs;
  var fbMessageCtrl = TextEditingController().obs;
  var serversLoading = false.obs;
  var serversError = ''.obs;

  Rx<Proto> selectedProtocol = Proto.wireguard.obs;

  bool _autoSelectProtocol = false;
  bool get autoSelectProtocol => _autoSelectProtocol;
  var selectedBottomIndex = 0.obs;

  final WireGuardFlutterInterface _wireguard = WireGuardFlutter.instance;
  final Wireguardservices _wireguardEngine = Wireguardservices();
  var authProvider = Get.find<CipherGateModel>();
  // Reactive speeds for fine-grained rebuilds
  final RxString dS = "0.0".obs;
  final RxString uS = "0.0".obs;
  final RxString pS = "0.0".obs;

  Timer? speedUpdateTimer;
  Timer? _stageTimer;
  Timer? _premiumCheckTimer;

  // Helper method to get consistent platform name
  String getPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'desktop';
    }
  }

  onItemTapped(int index) {
    selectedBottomIndex.value = index;
    update();
  }

  setProtocol(Proto protocol) async {
    selectedProtocol.value = protocol;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
      'selectedProtocol',
      protocol == Proto.ikeav2 ? 'ikeav2' : 'wireguard',
    );
    update();

    // Ensure stage polling reacts to protocol change
    sGettingStages();
  }

  void setqueryText(String text, String selectedTab) {
    queryText.value = text;
    filtersrvList(selectedTab);
  }

  // Pass in the selected tab (like "All srvList", "Premium", "Free", "Favourites")
  void filtersrvList(String selectedTab) {
    // Start with all srvList
    var results = srvList.toList();

    //  Filter by tab
    if (selectedTab == "Premium") {
      results = results
          .where((s) => s.type.toLowerCase() == "premium")
          .toList();
    } else if (selectedTab == "Free") {
      results = results.where((s) => s.type.toLowerCase() == "free").toList();
    }

    //  Filter by search text
    if (queryText.value.trim().isNotEmpty) {
      results = results
          .where(
            (s) => s.name.toLowerCase().contains(queryText.value.toLowerCase()),
          )
          .toList();
      queryActive.value = true;
    } else {
      queryActive.value = false;
    }

    // Update filtered list
    srvFiltered.assignAll(results);
  }

  setAutoSelectProtocol(bool value) async {
    _autoSelectProtocol = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoSelectProtocol', value);
    if (value) {
      await setProtocol(Proto.ikeav2);
    }
    update();
  }

  Future<void> lProtocolFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? proto = prefs.getString('selectedProtocol');
    bool autoSelect = prefs.getBool('autoSelectProtocol') ?? false;
    if (proto == 'wireguard') {
      selectedProtocol.value = Proto.wireguard;
    } else if (proto == 'ikeav2') {
      selectedProtocol.value = Proto.ikeav2;
    } else {
      // Default to WireGuard on first install
      selectedProtocol.value = Proto.wireguard;
    }
    _autoSelectProtocol = autoSelect;
    update();

    sGettingStages();
  }

  lServerFromLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedServer = prefs.getInt('selectedServer') ?? 0;
    final savedSubServer = prefs.getInt('selectedSubServer') ?? 0;

    srvIndex.value = savedServer;
    subSrvIndex.value = savedSubServer;
  }

  autoC(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoConnectOn.value = prefs.getBool('autoConnect') ?? false;
    log(autoConnectOn.value.toString());
    if (autoConnectOn.value &&
        vpnConnectionState.value == MyVpnConnectState.disconnected) {
      await tVpn(context);
      log(autoConnectOn.value.toString());
      update();
    } else if (vpnConnectionState.value == MyVpnConnectState.connected) {
      return;
    }
  }

  toggleAutoConnectState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoConnectOn.value = !autoConnectOn.value;
    log(autoConnectOn.value.toString());
    prefs.setBool('autoConnect', autoConnectOn.value);
    update();
  }

  toggleKillSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    killSwitchOn.value = !killSwitchOn.value;
    log(killSwitchOn.value.toString());
    prefs.setBool('killSwitchOn', killSwitchOn.value);
    log("KillSwitch toggled: $killSwitchOn.value");
    update();
  }

  myKillSwitch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    killSwitchOn.value = prefs.getBool('killSwitchOn') ?? false;
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

  // Ping all srvList and update their latency
  Future<void> pingAllsrvList() async {
    try {
      busyFlag.value = true;
      log("Pinging all srvList...");

      for (var server in srvList) {
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
      // Optionally, sort srvList by latency or update srvFiltered
      // srvFiltered = [...srvList];
    } catch (e) {
      log("Error pinging srvList: $e");
    } finally {
      busyFlag.value = false;
    }
  }

  cG(int value, int val, BuildContext context) async {
    // Check if this server is premium
    final server = srvList[value]; // assuming srvList list is available here
    if (server.type.toLowerCase() == "premium" && !proActive.value) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => Premium()));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    log("Changing server to index: $value, sub-index: $val");

    srvIndex.value = value;
    subSrvIndex.value = val;

    await prefs.setInt('selectedServer', value);
    await prefs.setInt('selectedSubServer', val);

    // Wait for values to properly reflect
    await Future.delayed(Duration(milliseconds: 700));

    // If vpn is connected then first disconnect then toggle vpn
    if (vpnConnectionState.value == MyVpnConnectState.connected ||
        vpnConnectionState.value == MyVpnConnectState.connecting) {
      tVpn(context);
      await Future.delayed(Duration(seconds: 1));
    }

    onItemTapped(0);
    update();

    await tVpn(context);
  }

  // i want to call a funntion every 3 seconds latter

  Future<void> getPre() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('t');

    log("=== PREMIUM CHECK START ===");
    log("Token: $token");

    if (token == null) {
      log("Token is null. Redirecting to login.");
      proActive.value = false;
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
        Uri.parse(Utils.PURCHASE_URL),
        headers: headers,
      );

      log("Response premium body: ${response.body}");

      // if (response.statusCode != 200) {
      //   log("Error fetching premium data. Status: ${response.statusCode}");
      //   proActive.value = false;
      //   subscription.value = null;
      //   update();
      //   return;
      // }

      final data = jsonDecode(response.body);

      // Check if the response indicates unauthenticated user
      if (data['message'] != null) {
        String message = data['message'].toString().toLowerCase();
        log("Checking message: '$message' for unauthenticated");
        if (message.contains('unauthenticated')) {
          log(
            "User is unauthenticated. Clearing storage and redirecting to auth.",
          );
          await _clearStorageAndRedirectToAuth();
          return;
        }
      }

      final subscriptionResponse = ActivePlanResponse.fromJson(data);

      if (subscriptionResponse.status &&
          subscriptionResponse.subscription != null) {
        final sub = subscriptionResponse.subscription!;
        subscription.value = sub;

        // Parse expiry dates
        DateTime expiry = sub.endsAt;
        DateTime graceExpiry = sub.graceEndsAt;

        expiryAt.value = expiry;

        if (graceExpiry.isAfter(DateTime.now())) {
          proActive.value = true;
          log("Premium active. Ends at: $expiry | Grace until: $graceExpiry");
        } else {
          proActive.value = false;
          log("Premium expired completely.");
        }
      } else {
        proActive.value = false;
        subscription.value = null;
        log("No active plan found.");
      }

      update();
    } catch (e) {
      log("Exception occurred while fetching premium data: $e");
      proActive.value = false;
      subscription.value = null;
      update();
    }
  }

  // Start periodic premium check every 3 seconds
  void startPremiumCheck() {
    stopPremiumCheck(); // Stop any existing timer
    log("Starting periodic premium check every 3 seconds");
    _premiumCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      await getPre();
    });
  }

  // Stop premium check timer
  void stopPremiumCheck() {
    _premiumCheckTimer?.cancel();
    _premiumCheckTimer = null;
  }

  Future<void> _clearStorageAndRedirectToAuth() async {
    try {
      // Clear all stored preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset all relevant reactive values
      proActive.value = false;
      subscription.value = null;
      srvList.clear();
      srvFiltered.clear();

      // Reset VPN state
      // disconnect both pns

      if (selectedProtocol == Proto.wireguard) {
        await dWireguard();
      } else {
        await dIkeav2(Get.context!);
      }

      // Stop all running timers
      stopMonitor();
      stopPremiumCheck();
      _stageTimer?.cancel();
      _stageTimer = null;

      update();

      // Navigate to auth screen
      Get.offAll(() => Auth());

      log("Storage cleared and user redirected to auth screen.");
    } catch (e) {
      log("Error clearing storage and redirecting: $e");
    }
  }

  getsrvList(bool net) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('t');
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
        Uri.parse("${Utils.GET_SERVERS}?platform=$platform"),
        headers: headers,
      );
      log("Data ${response.body}");
      var data = jsonDecode(response.body);

      if (data["status"] == true) {
        srvList.clear();
        log("Data $data");

        for (var server in data["servers"]) {
          srvList.add(Server.fromJson(server));
        }

        log("srvList fetched successfully");

        /// FIX: update srvFiltered properly
        srvFiltered.assignAll(srvList);

        log("Length is ${srvList.length}");
        await pingAllsrvList();
        if (vpnConnectionState.value == MyVpnConnectState.connected) {
          speedMonitor();
        }
      }
    } else {
      srvList.clear();
      srvFiltered.clear(); // keep them in sync
    }
  }

  // getVpssrvList() async {
  //   SharedPreferences preferences = await SharedPreferences.getInstance();
  //   var headers = {
  //     'Content-Type': 'application/json',
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${preferences.getString('t')}',
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
  //     Uri.parse(Defaults.VPS_srvList),
  //     headers: headers,
  //   );

  //   var data = jsonDecode(response.body);
  //   if (data["status"] == true) {
  //     // Handle successful response
  //     _vpssrvList.clear();
  //     for (var server in data["data"]) {
  //       _vpssrvList.add(VpsServer.fromJson(server));
  //     }
  //     notifyListeners();
  //   } else {
  //     log("Failed to fetch VPS srvList");
  //   }
  // }

  // Future<bool> ruinvps(String serverUrl) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final String? name = prefs.getString('n');
  //     final String? password = prefs.getString('p');

  //     log("Name is $name");
  //     log("Password is $password");

  //     if (name == null || password == null) {
  //       log("Name or password is missing");
  //       return false;
  //     }

  //     final String platform = getPlatformName();

  //     const headers = {
  //       'Content-Type': 'application/json',
  //       'Accept': 'application/json',
  //       'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
  //     };

  //     log("Name_platform is that ${name}_$platform");
  //     log("Password is that $password");

  //     final firstResponse = await post(
  //       Uri.parse("$serverUrl/api/ikev2/clients/generate"),
  //       headers: headers,
  //       body: jsonEncode({"name": "${name}_$platform", "password": password}),
  //     );

  //     final secondResponse = await post(
  //       Uri.parse("$serverUrl/api/clients/generate"),
  //       headers: headers,
  //       body: jsonEncode({"name": "${name}_$platform"}),
  //     );

  //     final firstBody = jsonDecode(firstResponse.body);
  //     final secondBody = jsonDecode(secondResponse.body);

  //     if (firstBody["error"] != null) {
  //       final deleteResponse = await http.delete(
  //         Uri.parse("$serverUrl/api/ikev2/clients/${name}_$platform"),
  //         headers: headers,
  //       );

  //       log("Status ikev2 ${deleteResponse.statusCode}");
  //       log("Status body ${deleteResponse.body}");

  //       if (deleteResponse.statusCode == 200) {
  //         final newResponse = await http.post(
  //           Uri.parse("$serverUrl/api/ikev2/clients/generate"),
  //           headers: headers,
  //           body: jsonEncode({
  //             "name": "${name}_$platform",
  //             "password": password,
  //           }),
  //         );

  //         log("Response is that ${newResponse.body}");

  //         final responseBody = jsonDecode(newResponse.body);
  //         if (responseBody["success"] == true) {
  //           log("Registered successfully on $serverUrl");
  //           return true;
  //         } else {
  //           log("Registration failed on $serverUrl");
  //           return false;
  //         }
  //       }
  //     }

  //     if (secondBody["error"] != null) {
  //       final deleteResponse = await http.delete(
  //         Uri.parse("$serverUrl/api/clients/${name}_$platform"),
  //         headers: headers,
  //       );
  //       log("Status wireguard ${deleteResponse.statusCode}");
  //       log("Status body ${deleteResponse.body}");
  //       if (deleteResponse.statusCode == 200) {
  //         final newResponse = await http.post(
  //           Uri.parse("$serverUrl/api/clients/generate"),
  //           headers: headers,
  //           body: jsonEncode({
  //             "name": "${name}_$platform",
  //             "password": password,
  //           }),
  //         );
  //         log("Response is that ${newResponse.body}");

  //         final responseBody = jsonDecode(newResponse.body);
  //         if (responseBody["success"] == true) {
  //           log("Registered successfully on $serverUrl");
  //           return true;
  //         } else {
  //           log("Registration failed on $serverUrl");
  //           return false;
  //         }
  //       }
  //     }

  //     return true;
  //   } catch (e) {
  //     log("Exception during registration on $serverUrl: $e");
  //     return false;
  //   }
  // }

  Future<void> tVpn(BuildContext context) async {
    // Logic to toggle VPN connection
    var domain = gtd();
    if (selectedProtocol == Proto.wireguard) {
      if (vpnConnectionState.value == MyVpnConnectState.connected ||
          vpnConnectionState.value == MyVpnConnectState.connecting) {
        await dWireguard();
      } else if (vpnConnectionState.value == MyVpnConnectState.disconnected) {
        await cWireguard(domain, context);
      }
    } else if (selectedProtocol == Proto.ikeav2) {
      if (vpnConnectionState.value == MyVpnConnectState.connected ||
          vpnConnectionState.value == MyVpnConnectState.connecting) {
        await dIkeav2(context);
      } else if (vpnConnectionState.value == MyVpnConnectState.disconnected) {
        await cIkeav2(domain, context);
      }
    }
  }

  gtd() {
    return srvList[srvIndex.value]
        .subServers[subSrvIndex.value]
        .vpsServer
        .domain;
  }

  sGettingStages() {
    // Avoid spawning multiple timers
    _stageTimer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (selectedProtocol == Proto.wireguard) {
        await listenWire();
      } else if (selectedProtocol == Proto.ikeav2) {
        await lIkeav2Stages();
      }
    });
  }

  Future<void> lIkeav2Stages() async {
    FlutterVpn.currentState.then((FlutterVpnState status) {
      if (cfgLoading.value) {
        vpnConnectionState.value = MyVpnConnectState.connecting;
        return;
      } else {
        switch (status) {
          case FlutterVpnState.connecting:
            vpnConnectionState.value = MyVpnConnectState.connecting;
            break;
          case FlutterVpnState.connected:
            vpnConnectionState.value = MyVpnConnectState.connected;
            break;
          case FlutterVpnState.disconnecting:
            vpnConnectionState.value = MyVpnConnectState.disconnecting;
            break;
          case FlutterVpnState.disconnected:
            vpnConnectionState.value = MyVpnConnectState.disconnected;
            break;
          default:
            vpnConnectionState.value = MyVpnConnectState.disconnected;
            break;
        }
        log("IKEv2 Stage: $vpnConnectionState");
        update();
      }
    });
  }

  Future<MyVpnConnectState> listenWire() async {
    try {
      MyVpnConnectState newStage = vpnConnectionState.value;
      final value = await _wireguard.stage();
      if (value == VpnStage.connected) {
        newStage = MyVpnConnectState.connected;
      } else if (value == VpnStage.connecting || cfgLoading.value) {
        newStage = MyVpnConnectState.connecting;
      } else if (value == VpnStage.disconnected) {
        newStage = MyVpnConnectState.disconnected;
      } else if (value == VpnStage.disconnecting) {
        newStage = MyVpnConnectState.disconnecting;
      } else {
        newStage = MyVpnConnectState.disconnected;
      }
      vpnConnectionState.value = newStage;
      log("WireGuard Stage: $vpnConnectionState");
      update();

      return newStage;
    } catch (e) {
      log("Error getting WireGuard stage: $e");
      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update();
      return MyVpnConnectState.disconnected;
    }
  }

  Future<String?> selectedWirVPNConfig(
    String serverUrl,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('n');

      final String platform = getPlatformName();

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

  Future<bool> cWireguard(String domain, BuildContext context) async {
    try {
      busyFlag.value = true;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());

      // Track session start
      AnalyticsService().trackEvent(
        'vpn_session_start',
        parameters: {
          'protocol': 'WireGuard',
          'server': domain,
          'platform': getPlatformName(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      cfgLoading.value = true;
      vpnConnectionState.value = MyVpnConnectState.connecting;
      update();

      // Add a short delay to allow UI to show 'connecting' state
      await Future.delayed(const Duration(milliseconds: 700));

      var isRegistered = await registerUserInVPS('http://$domain:5000');
      if (!isRegistered) {
        log("Failed to register user in VPS");

        // Track connection failure
        AnalyticsService().trackVpnConnection(
          protocol: 'WireGuard',
          serverLocation: domain,
          success: false,
        );

        cfgLoading.value = false;
        busyFlag.value = false;
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
      final config = await selectedWirVPNConfig('http://$domain:5000', context);
      log("WireGuard config: $config");
      final success = await _wireguardEngine.startWireguard(
        server: domain,
        serverName: 'United States',
        wireguardConfig: config!,
      );
      speedMonitor();

      // Track VPN connection success
      AnalyticsService().trackVpnConnection(
        protocol: 'WireGuard',
        serverLocation: domain,
        success: true,
      );

      // Track server usage
      AnalyticsService().trackEvent(
        'vpn_server_used',
        parameters: {
          'server_name': domain,
          'protocol': 'WireGuard',
          'platform': getPlatformName(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      cfgLoading.value = false;
      busyFlag.value = false;
      update();

      return success;
    } catch (e) {
      log("Error in connectWireguard: $e");
      busyFlag.value = false;
      update();

      return false;
    }
  }

  Future<bool> dWireguard() async {
    try {
      busyFlag.value = true;
      vpnConnectionState.value = MyVpnConnectState.disconnecting;
      update();

      final success = await _wireguardEngine.stopWireguard();

      if (success) {
        log("Disconnected from WireGuard VPN");

        // Calculate session duration
        final prefs = await SharedPreferences.getInstance();
        final connectTimeStr = prefs.getString('connectTime');
        if (connectTimeStr != null) {
          final connectTime = DateTime.parse(connectTimeStr);
          final duration = DateTime.now().difference(connectTime);

          // Track session end with duration
          AnalyticsService().trackEvent(
            'vpn_session_end',
            parameters: {
              'protocol': 'WireGuard',
              'server': srvList[srvIndex.value].name,
              'platform': getPlatformName(),
              'duration_seconds': duration.inSeconds.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }

        // Track VPN disconnection
        AnalyticsService().trackVpnDisconnection(
          protocol: 'WireGuard',
          serverLocation: srvList[srvIndex.value].name,
        );

        busyFlag.value = false;
        vpnConnectionState.value = MyVpnConnectState.disconnected;
        stopMonitor();
        update();

        return true;
      } else {
        busyFlag.value = false;
        vpnConnectionState.value = MyVpnConnectState.disconnected;
        update();

        return false;
      }
    } catch (e) {
      log("Error in disconnectWireguard: $e");
      busyFlag.value = false;
      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        update();
      });
      return false;
    }
  }

  Future<void> cIkeav2(String ip, BuildContext context) async {
    try {
      log("Connecting to IKEv2 VPN at $ip");
      cfgLoading.value = true;
      vpnConnectionState.value = MyVpnConnectState.connecting;
      update();

      bool isRegistered = await registerUserInVPS('http://$ip:5000');
      if (!isRegistered) {
        log("Failed to register user in VPS");

        // Track connection failure
        AnalyticsService().trackVpnConnection(
          protocol: 'IKEv2',
          serverLocation: ip,
          success: false,
        );

        cfgLoading.value = false;
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

      // Track session start
      AnalyticsService().trackEvent(
        'vpn_session_start',
        parameters: {
          'protocol': 'IKEv2',
          'server': ip,
          'platform': getPlatformName(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Keep _isGettingConfig true until after initiating connection

      final String platform = getPlatformName();

      var name = prefs.getString('n') ?? '';
      var password = prefs.getString('p') ?? '';

      var username = "${name}_$platform";
      log("Ip is $ip");
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
      speedMonitor();

      // Track VPN connection success
      AnalyticsService().trackVpnConnection(
        protocol: 'IKEv2',
        serverLocation: ip,
        success: true,
      );

      // Track server usage
      AnalyticsService().trackEvent(
        'vpn_server_used',
        parameters: {
          'server_name': ip,
          'protocol': 'IKEv2',
          'platform': getPlatformName(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log("IKEv2 VPN connected successfully");
      cfgLoading.value = false;
      update();
    } catch (e) {
      log("Error connecting IKEv2: $e");
      cfgLoading.value = false;
      vpnConnectionState.value = MyVpnConnectState.disconnected;
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

  Future<void> dIkeav2(BuildContext context) async {
    try {
      log("Disconnecting IKEv2");
      vpnConnectionState.value = MyVpnConnectState.disconnecting;
      update();

      await ikeav2Engine.disconnect();
      stopMonitor();

      // Add a short delay to ensure engine is ready for next connection
      await Future.delayed(const Duration(milliseconds: 700));

      log("IKEv2 disconnected successfully");

      // Calculate session duration
      final prefs = await SharedPreferences.getInstance();
      final connectTimeStr = prefs.getString('connectTime');
      if (connectTimeStr != null) {
        final connectTime = DateTime.parse(connectTimeStr);
        final duration = DateTime.now().difference(connectTime);

        // Track session end with duration
        AnalyticsService().trackEvent(
          'vpn_session_end',
          parameters: {
            'protocol': 'IKEv2',
            'server': srvList[srvIndex.value].name,
            'platform': getPlatformName(),
            'duration_seconds': duration.inSeconds.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      // Track VPN disconnection
      AnalyticsService().trackVpnDisconnection(
        protocol: 'IKEv2',
        serverLocation: srvList[srvIndex.value].name,
      );

      vpnConnectionState.value = MyVpnConnectState.disconnected;
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
      vpnConnectionState.value = MyVpnConnectState.disconnected;
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
  Future<Map<String, String>> networkSpeed() async {
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

  void speedMonitor() {
    log("Starting speed monitoring");
    stopMonitor(); // Stop any existing timer

    speedUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (vpnConnectionState.value == MyVpnConnectState.connected) {
        log("Monitoring speeds...");
        var speeds = await networkSpeed();
        log("Speeds (Mbps): $speeds");

        // Convert Mbps to Kbps
        double downloadMbps =
            double.tryParse(speeds['download'] ?? "0.0") ?? 0.0;
        double uploadMbps = double.tryParse(speeds['upload'] ?? "0.0") ?? 0.0;

        dS.value = (downloadMbps * 1000).toStringAsFixed(2); // kbps
        uS.value = (uploadMbps * 1000).toStringAsFixed(2); // kbps

        // Log the speeds in kbps
        log("Download Speed: $dS Kbps");
        log("Upload Speed: $uS Kbps");

        // Get ping measurement
        try {
          final result = await InternetAddress.lookup('google.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            final stopwatch = Stopwatch()..start();
            await http.get(Uri.parse('https://google.com'));
            stopwatch.stop();
            pS.value = stopwatch.elapsedMilliseconds.toString();
          }
        } catch (_) {
          pS.value = "0";
        }
        log("Ping Speed: $pS ms");
        update();
        // Ensure UI updates to reflect new speeds
      } else {
        // Reset values when not connected
        dS.value = "0.0";
        uS.value = "0.0";
        pS.value = "0";
        // Notify UI of reset values
        update();
      }
    });
  }

  // Method to stop monitoring when disconnected
  void stopMonitor() {
    speedUpdateTimer?.cancel();
    speedUpdateTimer = null;
  }

  Future<void> gPlans() async {
    try {
      log("Fetching plans...");
      busyFlag.value = true;
      update();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('t');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      var response = await http.get(
        Uri.parse(Utils.ALL_PLANS),
        headers: headers,
      );

      log("Plans raw response: ${response.body}");

      if (response.statusCode != 200) {
        log("Failed with status: ${response.statusCode}");
        busyFlag.value = false;
        update();
        return;
      }

      var data = jsonDecode(response.body);
      log("Plans response decoded: $data");

      // Use model
      final plansResponse = PlansModelResponse.fromJson(data);

      if (plansResponse.status && plansResponse.plans.isNotEmpty) {
        plans.assignAll(plansResponse.plans);

        log("Plans fetched successfully: ${plans.length} plans");
        for (var p in plans) {
          log("Plan: ${p.name} | Price: ${p.discountPrice}");
        }
      } else {
        log("No plans found or invalid response.");
      }

      busyFlag.value = false;
      update();
    } catch (error) {
      log("Exception occurred while fetching plans: $error");
      busyFlag.value = false;
      update();
    }
  }

  Future<bool> registerUserInVPS(String serverUrl) async {
    log("Registering user in VPS server: $serverUrl");
    try {
      log("Registering user in VPS server: $serverUrl");
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('n');
      final String? password = prefs.getString('p');

      if (name == null || password == null) {
        log("Name or password is missing");
        return false;
      }

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'desktop';

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      final firstResponse = await http.post(
        Uri.parse("$serverUrl/api/ikev2/clients/generate"),
        headers: headers,
        body: jsonEncode({"name": "${name}_$platform", "password": password}),
      );

      final secondResponse = await http.post(
        Uri.parse("$serverUrl/api/clients/generate"),
        headers: headers,
        body: jsonEncode({"name": "${name}_$platform"}),
      );

      log("firstResponse: ${firstResponse.body}");
      log("secondResponse: ${secondResponse.body}");

      final firstBody = jsonDecode(firstResponse.body);
      final secondBody = jsonDecode(secondResponse.body);

      if (firstBody["error"] != null) {
        var response = await http.delete(
          Uri.parse(
            "$serverUrl/api/ikev2/clients/${name.replaceAll(' ', '-')}_$platform",
          ),
          headers: headers,
        );
        if (response.statusCode == 200) {
          final newResponse = await http.post(
            Uri.parse("$serverUrl/api/ikev2/clients/generate"),
            headers: headers,
            body: jsonEncode({
              "name": "${name.replaceAll(' ', '-')}_$platform",
              "password": password,
            }),
          );

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

  /// Fetch VPS servers list from the backend API
  Future<void> fetchVpsServers() async {
    try {
      log("🔄 Fetching VPS servers list...");
      busyFlag.value = true;
      serversLoading.value = true;
      serversError.value = '';
      update();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('t');

      if (token == null || token.isEmpty) {
        log("❌ No authentication token. Cannot fetch VPS servers.");
        serversError.value = 'Authentication required. Please login again.';
        busyFlag.value = false;
        serversLoading.value = false;
        update();
        return;
      }

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final url = Utils.VPS_SERVERS;
      log("📍 Fetching from: $url");

      var response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('VPS servers fetch timed out'),
      );

      log("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        log("✅ VPS Response received: ${data.toString().substring(0, 500)}...");
        log("📊 Full response structure: $data");

        if (data["status"] == true && data["vps_servers"] != null) {
          List<dynamic> vpsServers = data["vps_servers"];
          log("✅ Found ${vpsServers.length} VPS servers");

          // Debug: Log first VPS server structure
          if (vpsServers.isNotEmpty) {
            log("📋 First VPS server structure: ${vpsServers[0]}");
          }

          // Update srvList with VPS server data
          for (var server in srvList) {
            List<dynamic> matchingVps = vpsServers
                .where((vps) => vps["server_id"] == server.id)
                .toList();

            if (matchingVps.isNotEmpty) {
              server.subServers.clear();
              for (var vpsData in matchingVps) {
                log("🔍 Processing VPS data: $vpsData");
                
                // Extract fields with multiple possible names
                String ipAddress = vpsData["ip_address"] ?? vpsData["ip"] ?? vpsData["ipAddress"] ?? "";
                String domain = vpsData["domain"] ?? vpsData["host"] ?? vpsData["server_url"] ?? "";
                
                SubServer subServer = SubServer(
                  id: vpsData["id"] ?? 0,
                  serverId: server.id,
                  name: vpsData["name"] ?? "VPS-${vpsData['id']}",
                  status: vpsData["status"] ?? 1,
                  vpsServer: VpsServer(
                    id: vpsData["id"] ?? 0,
                    name: vpsData["name"] ?? "VPS-${vpsData['id']}",
                    ipAddress: ipAddress,
                    domain: domain,
                    username: vpsData["username"],
                    password: vpsData["password"],
                    port: vpsData["port"],
                    privateKey: vpsData["private_key"],
                  ),
                );
                server.subServers.add(subServer);
                log("✅ Added VPS: ${vpsData['name']} | IP: $ipAddress | Domain: $domain | User: ${vpsData['username']}");
              }
            }
          }

          serversError.value = '';
          log("✅ VPS servers updated successfully");
          update();
        } else {
          serversError.value = data['message'] ?? 'No VPS servers found';
          log("⚠️  No VPS servers found in response");
          log("📊 Response keys: ${data.keys.toList()}");
        }
      } else {
        serversError.value = 'Failed to fetch VPS servers (Status: ${response.statusCode})';
        log("❌ Failed to fetch VPS servers. Status: ${response.statusCode}");
        log("   Response: ${response.body}");
      }

      busyFlag.value = false;
      serversLoading.value = false;
      update();
    } on TimeoutException catch (e) {
      log("⏱️  Timeout fetching VPS servers: $e");
      serversError.value = 'Request timeout. Please try again.';
      busyFlag.value = false;
      serversLoading.value = false;
      update();
    } catch (e) {
      log("❌ Error fetching VPS servers: $e");
      serversError.value = 'Error: $e';
      busyFlag.value = false;
      serversLoading.value = false;
      update();
    }
  }

  /// Get VPS server details by ID
  Future<VpsServer?> getVpsServerById(int vpsId) async {
    try {
      log("🔍 Looking for VPS server with ID: $vpsId");

      for (var server in srvList) {
        for (var subServer in server.subServers) {
          if (subServer.vpsServer.id == vpsId) {
            log("✅ Found VPS server: ${subServer.vpsServer.name}");
            return subServer.vpsServer;
          }
        }
      }

      log("❌ VPS server with ID $vpsId not found");
      return null;
    } catch (e) {
      log("Error getting VPS server by ID: $e");
      return null;
    }
  }

  /// Load test VPS servers (for testing purposes)
  Future<void> loadTestServers() async {
    try {
      log("📊 Loading test VPS servers...");
      busyFlag.value = true;
      update();

      // Create test data
      final testVpsServers = [
        VpsServer(
          id: 1,
          name: "US-East-1",
          ipAddress: "192.168.1.1",
          domain: "us-east-1.vpn.test",
        ),
        VpsServer(
          id: 2,
          name: "US-West-1",
          ipAddress: "192.168.1.2",
          domain: "us-west-1.vpn.test",
        ),
      ];

      // Add test VPS servers to first server's subServers
      if (srvList.isNotEmpty) {
        srvList[0].subServers.clear();
        for (var vps in testVpsServers) {
          SubServer subServer = SubServer(
            id: vps.id,
            serverId: srvList[0].id,
            name: vps.name,
            status: 1,
            vpsServer: vps,
          );
          srvList[0].subServers.add(subServer);
        }
      }

      log("✅ Test servers loaded successfully");
      busyFlag.value = false;
      update();
    } catch (e) {
      log("❌ Error loading test servers: $e");
      busyFlag.value = false;
      update();
    }
  }

  /// Check VPS server health/availability
  Future<bool> checkVpsServerHealth(String domain) async {
    try {
      log("🏥 Checking health of VPS server: $domain");

      final stopwatch = Stopwatch()..start();
      final response = await http.get(
        Uri.parse('http://$domain:5000/health'),
      ).timeout(const Duration(seconds: 5));

      stopwatch.stop();
      log("   Response time: ${stopwatch.elapsedMilliseconds}ms");

      if (response.statusCode == 200) {
        log("✅ VPS server $domain is healthy");
        return true;
      } else {
        log("⚠️  VPS server $domain returned status ${response.statusCode}");
        return false;
      }
    } catch (e) {
      log("❌ VPS server $domain is unreachable: $e");
      return false;
    }
  }

  /// Get VPS server statistics
  Future<Map<String, dynamic>?> getVpsServerStats(String domain) async {
    try {
      log("📈 Fetching stats for VPS server: $domain");

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      final response = await http.get(
        Uri.parse('http://$domain:5000/api/stats'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("✅ VPS server stats retrieved successfully");
        return data;
      } else {
        log("❌ Failed to get VPS stats. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("❌ Error fetching VPS server stats: $e");
      return null;
    }
  }

  /// Disconnect from current VPS server
  Future<bool> disconnectVpsServer() async {
    try {
      log("🔌 Disconnecting from VPS server...");

      if (selectedProtocol == Proto.wireguard) {
        return await dWireguard();
      } else if (selectedProtocol == Proto.ikeav2) {
        await dIkeav2(Get.context!);
        return true;
      }

      return false;
    } catch (e) {
      log("❌ Error disconnecting from VPS server: $e");
      return false;
    }
  }

  /// Test connection to a specific VPS server
  Future<bool> testVpsConnection(String serverUrl) async {
    try {
      log("🧪 Testing connection to VPS server: $serverUrl");

      final response = await http.get(
        Uri.parse('http://$serverUrl:5000/api/test'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        log("✅ Connection test passed for $serverUrl");
        return true;
      } else {
        log("❌ Connection test failed for $serverUrl");
        return false;
      }
    } catch (e) {
      log("❌ Connection test error for $serverUrl: $e");
      return false;
    }
  }

  /// Check backend connection and server availability
  Future<bool> checkBackendConnection() async {
    try {
      log("🔍 Checking backend connection...");
      
      final response = await http.get(
        Uri.parse(Utils.GET_SERVERS),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        log("✅ Backend connection successful");
        return true;
      } else {
        log("❌ Backend returned status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      log("❌ Backend connection failed: $e");
      return false;
    }
  }

  /// Connect to a specific VPS server using its credentials
  Future<bool> connectToVpsServer(VpsServer vps, BuildContext context) async {
    try {
      log("🔌 Connecting to VPS server: ${vps.name} (${vps.domain})");
      busyFlag.value = true;
      update();

      // Validate VPS server has required connection info
      if (vps.domain.isEmpty || vps.ipAddress.isEmpty) {
        log("❌ VPS server missing domain or IP address");
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connection Error',
          'VPS server configuration incomplete',
          Colors.red,
        );
        busyFlag.value = false;
        update();
        return false;
      }

      // Register user in VPS if needed (using domain as server URL)
      log("📝 Registering user in VPS: ${vps.domain}");
      bool isRegistered = await registerUserInVPS('http://${vps.domain}:5000');
      
      if (!isRegistered) {
        log("❌ Failed to register user in VPS");
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Registration Error',
          'Failed to register on VPS server',
          Colors.red,
        );
        busyFlag.value = false;
        update();
        return false;
      }

      // Save current VPS server info
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selectedVpsId', vps.id);
      await prefs.setString('selectedVpsDomain', vps.domain);
      await prefs.setString('selectedVpsName', vps.name);
      
      // Store credentials if available
      if (vps.username != null) {
        await prefs.setString('vpsUsername', vps.username!);
      }
      if (vps.port != null) {
        await prefs.setInt('vpsPort', vps.port!);
      }

      log("✅ VPS connection info saved. Starting VPN connection...");

      // Initiate VPN connection using the VPS domain
      await tVpn(context);

      log("✅ Connected to VPS server: ${vps.name}");
      showCustomSnackBar(
        context,
        EvaIcons.checkmarkCircle2Outline,
        'Connection Success',
        'Connected to ${vps.name}',
        Colors.green,
      );

      busyFlag.value = false;
      update();
      return true;

    } catch (e) {
      log("❌ Error connecting to VPS server: $e");
      showCustomSnackBar(
        context,
        EvaIcons.infoOutline,
        'Connection Error',
        e.toString(),
        Colors.red,
      );
      busyFlag.value = false;
      update();
      return false;
    }
  }

  /// Get currently connected VPS server info
  Future<Map<String, dynamic>?> getCurrentVpsServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? vpsId = prefs.getInt('selectedVpsId');
      final String? vpsDomain = prefs.getString('selectedVpsDomain');
      final String? vpsName = prefs.getString('selectedVpsName');

      if (vpsId != null && vpsDomain != null) {
        return {
          'id': vpsId,
          'domain': vpsDomain,
          'name': vpsName ?? 'Unknown',
        };
      }
      return null;
    } catch (e) {
      log("Error getting current VPS server: $e");
      return null;
    }
  }

  /// Disconnect from VPS server and clear saved info
  Future<bool> disconnectFromVpsServer(BuildContext context) async {
    try {
      log("🔌 Disconnecting from VPS server...");
      
      // Disconnect VPN
      bool disconnected = await disconnectVpsServer();

      if (disconnected) {
        // Clear saved VPS info
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('selectedVpsId');
        await prefs.remove('selectedVpsDomain');
        await prefs.remove('selectedVpsName');
        await prefs.remove('vpsUsername');
        await prefs.remove('vpsPort');

        log("✅ Disconnected from VPS server");
        return true;
      } else {
        log("⚠️  Disconnect request sent but status uncertain");
        return true;
      }
    } catch (e) {
      log("❌ Error disconnecting from VPS server: $e");
      return false;
    }
  }
}
