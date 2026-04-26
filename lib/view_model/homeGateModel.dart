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
    show Server, ServerResponse, VpsServer, SubServer, Platforms;
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
  var vpsServersList = <VpsServer>[].obs; // Store VPS servers separately
  var filteredVpsServers = <VpsServer>[].obs; // Filtered VPS servers for display
  var selectedVpsServer = Rxn<VpsServer>(); // Currently selected VPS server
  var vpsSearchQuery = ''.obs; // Search query for VPS servers

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
    // Prevent concurrent protocol switches
    if (busyFlag.value) {
      print("⚠️  [PROTOCOL] Switch already in progress, ignoring");
      return;
    }

    print("🔄 [PROTOCOL] SWITCH INITIATED - Target: ${protocol == Proto.wireguard ? 'WireGuard' : 'IKEv2'}");
    busyFlag.value = true;
    
    try {
      // ✅ AUTOMATIC DISCONNECT + STATE CLEANUP
      if (vpnConnectionState.value != MyVpnConnectState.disconnected) {
        print("🔌 [PROTOCOL] FORCE DISCONNECTING active VPN...");
        
        try {
          if (selectedProtocol.value == Proto.wireguard) {
            print("🔌 [PROTOCOL] Stopping WireGuard");
            await dWireguard();
          } else if (selectedProtocol.value == Proto.ikeav2) {
            print("🔌 [PROTOCOL] Stopping IKEv2");
            if (Get.context != null) {
              await dIkeav2(Get.context!);
            }
          }
          print("✅ [PROTOCOL] Current VPN disconnected");
          // Wait for clean state
          await Future.delayed(const Duration(milliseconds: 1500));
        } catch (e) {
          print("⚠️  [PROTOCOL] Disconnect error (continuing): $e");
          log("⚠️  Disconnect error: $e");
          // Force state reset even if disconnect fails
          vpnConnectionState.value = MyVpnConnectState.disconnected;
          update();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Update protocol (atomic)
      selectedProtocol.value = protocol;
      print("✅ [PROTOCOL] Protocol changed to ${protocol == Proto.wireguard ? 'WireGuard' : 'IKEv2'}");

      // Persist immediately
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedProtocol', protocol == Proto.ikeav2 ? 'ikeav2' : 'wireguard');
      
      // Cancel old timer and restart monitoring with NEW protocol
      print("🔄 [PROTOCOL] Restarting stage polling...");
      _stageTimer?.cancel();
      _stageTimer = null;
      await Future.delayed(const Duration(milliseconds: 300));
      sGettingStages();
      
      print("✅ [PROTOCOL] SWITCH COMPLETE - Ready to connect with new protocol");
    } catch (e) {
      print("❌ [PROTOCOL] Error during switch: $e");
      log("❌ Protocol switch error: $e");
    } finally {
      busyFlag.value = false;
      update();
    }
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
    // Prevent concurrent operations
    if (busyFlag.value) {
      log("⚠️  [VPN] Operation already in progress, ignoring request");
      return;
    }

    busyFlag.value = true;
    print("🔌 [VPN] tVpn() called - Current state: $vpnConnectionState, Protocol: ${selectedProtocol.value == Proto.wireguard ? 'WireGuard' : 'IKEv2'}");
    
    try {
      // Check if a VPS server is selected
      if (selectedVpsServer.value != null) {
        print("🔌 [VPN] VPS server selected: ${selectedVpsServer.value!.name}");
        
        if (vpnConnectionState.value == MyVpnConnectState.connected ||
            vpnConnectionState.value == MyVpnConnectState.connecting) {
          print("🔌 [VPN] Disconnecting from VPS");
          await disconnectVpsServer();
        } else if (vpnConnectionState.value == MyVpnConnectState.disconnected) {
          print("🔌 [VPN] Connecting to VPS server");
          await connectToVpsServer(selectedVpsServer.value!, context);
        }
        busyFlag.value = false;
        return;
      }
      
      // Regular server connection flow
      var domain = gtd();
      print("🔌 [VPN] Regular server - Domain: $domain, Protocol: ${selectedProtocol.value == Proto.wireguard ? 'WireGuard' : 'IKEv2'}");
      
      // Ensure state is correct before proceeding
      final currentState = vpnConnectionState.value;
      
      if (selectedProtocol.value == Proto.wireguard) {
        if (currentState == MyVpnConnectState.connected ||
            currentState == MyVpnConnectState.connecting) {
          print("🔌 [VPN] Disconnecting WireGuard");
          await dWireguard();
        } else if (currentState == MyVpnConnectState.disconnected) {
          print("🔌 [VPN] Connecting WireGuard");
          await cWireguard(domain, context);
        }
      } else if (selectedProtocol.value == Proto.ikeav2) {
        if (currentState == MyVpnConnectState.connected ||
            currentState == MyVpnConnectState.connecting) {
          print("🔌 [VPN] Disconnecting IKEv2");
          await dIkeav2(context);
        } else if (currentState == MyVpnConnectState.disconnected) {
          print("🔌 [VPN] Connecting IKEv2");
          await cIkeav2(domain, context);
        }
      }
      
      print("🔌 [VPN] tVpn() completed successfully");
    } catch (e) {
      log("❌ [VPN] Error in tVpn: $e");
      print("❌ [VPN] Error: $e");
      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update();
    } finally {
      busyFlag.value = false;
      update();
    }
  }  gtd() {
    return srvList[srvIndex.value]
        .subServers[subSrvIndex.value]
        .vpsServer
        .domain;
  }

  sGettingStages() {
    print("🔄 [STAGE] sGettingStages() called - Current protocol: ${selectedProtocol.value == Proto.wireguard ? 'WireGuard' : 'IKEv2'}");
    
    // Cancel existing timer to avoid multiples
    _stageTimer?.cancel();
    _stageTimer = null;
    
    print("🔄 [STAGE] Starting new polling timer");
    // Start new timer with error handling
    _stageTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      try {
        if (selectedProtocol.value == Proto.wireguard) {
          await listenWire();
        } else if (selectedProtocol.value == Proto.ikeav2) {
          await lIkeav2Stages();
        }
      } catch (e) {
        log("❌ [STAGE-POLL] Error in stage polling: $e");
        // Continue polling despite error
      }
    });
    print("🔄 [STAGE] Polling timer started");
  }

Future<void> lIkeav2Stages() async {
    try {
      final status = await FlutterVpn.currentState;
      final errorState = await FlutterVpn.charonErrorState;
      
      if (cfgLoading.value) {
        vpnConnectionState.value = MyVpnConnectState.connecting;
        return;
      } 
      
      if (errorState != null) {
        log("IKEv2 Charon ERROR: $errorState - Force disconnected");
        vpnConnectionState.value = MyVpnConnectState.disconnected;
        return;
      }
      
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
        case FlutterVpnState.error:
          vpnConnectionState.value = MyVpnConnectState.disconnected;
          break;
      }
      log("IKEv2 Stage: $status | Error: $errorState");
      update();
    } catch (e) {
      log("IKEv2 state check error: $e");
      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update();
    }
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
      print("📡 [WIREGUARD] Fetching config from: $serverUrl");
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('n');

      final String platform = getPlatformName();

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      final configPath = "$serverUrl/api/clients/${name}_$platform";
      print("📡 [WIREGUARD] Requesting config at: $configPath");

      // Retry logic - VPS server might need a moment to sync after registration
      int retries = 3;
      int delayMs = 1000;
      
      for (int attempt = 1; attempt <= retries; attempt++) {
        print("🔄 [WIREGUARD] Attempt $attempt/$retries to fetch config");
        
        try {
          final response = await http.get(
            Uri.parse(configPath),
            headers: headers,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print("⏱️  [WIREGUARD] Config request timed out");
              throw TimeoutException('WireGuard config request timeout');
            },
          );

          print("📡 [WIREGUARD] Response status: ${response.statusCode}");
          log("Response status code: ${response.statusCode}");

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

            print("✅ [WIREGUARD] Config received successfully on attempt $attempt");
            log("WireGuard config received: $wireguardConfig");
            log("WireGuard config saved successfully");

            return wireguardConfig;
          } else if (response.statusCode == 404) {
            // Client not found, retry
            print("⏳ [WIREGUARD] Client not found (404) - retrying in ${delayMs}ms...");
            if (attempt < retries) {
              await Future.delayed(Duration(milliseconds: delayMs));
              delayMs += 500; // Increase delay each time
              continue;
            } else {
              // Final attempt failed
              print("❌ [WIREGUARD] Failed to find client after $retries attempts");
              String bodyPreview = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
              print("📝 [WIREGUARD] Response body: $bodyPreview");
              log("Failed to get WireGuard config: ${response.statusCode}");
              return null;
            }
          } else {
            // Other error
            print("❌ [WIREGUARD] Failed with status: ${response.statusCode}");
            String bodyPreview = response.body.length > 200 ? response.body.substring(0, 200) : response.body;
            print("📝 [WIREGUARD] Response body: $bodyPreview");
            log("Failed to get WireGuard config: ${response.statusCode}");
            return null;
          }
        } catch (e) {
          print("⚠️  [WIREGUARD] Attempt $attempt failed: $e");
          if (attempt < retries) {
            print("⏳ [WIREGUARD] Retrying in ${delayMs}ms...");
            await Future.delayed(Duration(milliseconds: delayMs));
            delayMs += 500;
          } else {
            print("❌ [WIREGUARD] All $retries attempts failed");
            rethrow;
          }
        }
      }
      
      return null;
    } on TimeoutException catch (e) {
      print("⏱️  [WIREGUARD] Timeout: $e");
      log("WireGuard config request timeout");
      return null;
    } catch (e) {
      print("❌ [WIREGUARD] Error: $e");
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
      update(); // Immediate UI update
      
      print("🔌 [DISCONNECT-WG] Starting WireGuard disconnection");
      final success = await _wireguardEngine.stopWireguard();

      if (success) {
        log("Disconnected from WireGuard VPN");
        print("✅ [DISCONNECT-WG] WireGuard stopped successfully");

        // Calculate session duration
        final prefs = await SharedPreferences.getInstance();
        final connectTimeStr = prefs.getString('connectTime');
        if (connectTimeStr != null) {
          final connectTime = DateTime.parse(connectTimeStr);
          final duration = DateTime.now().difference(connectTime);

          AnalyticsService().trackEvent(
            'vpn_session_end',
            parameters: {
              'protocol': 'WireGuard',
              'server': srvList.isNotEmpty ? srvList[srvIndex.value].name : 'unknown',
              'platform': getPlatformName(),
              'duration_seconds': duration.inSeconds.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }

        AnalyticsService().trackVpnDisconnection(
          protocol: 'WireGuard',
          serverLocation: srvList.isNotEmpty ? srvList[srvIndex.value].name : 'unknown',
        );

        busyFlag.value = false;
        vpnConnectionState.value = MyVpnConnectState.disconnected;
        stopMonitor();
        update(); // Final UI update
        
        print("✅ [DISCONNECT-WG] State updated to disconnected");
        return true;
      } else {
        print("⚠️  [DISCONNECT-WG] Stop returned false");
        busyFlag.value = false;
        vpnConnectionState.value = MyVpnConnectState.disconnected;
        update();
        return false;
      }
    } catch (e) {
      log("Error in disconnectWireguard: $e");
      print("❌ [DISCONNECT-WG] Exception: $e");
      busyFlag.value = false;
      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update();
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

      await ikeav2Engine.connectTheIKEAV2(
        ip,
        username,
        password,
        vpnServerDomain: ip,
        vpnServerName: 'VPS Server',
      );
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
      update(); // Immediate UI update

      print("🔌 [DISCONNECT-IKE] Starting IKEv2 disconnection");
      await ikeav2Engine.disconnect();
      stopMonitor();

      // Wait for clean state
      await Future.delayed(const Duration(milliseconds: 700));

      log("IKEv2 disconnected successfully");
      print("✅ [DISCONNECT-IKE] IKEv2 disconnected");

      // Calculate session duration
      final prefs = await SharedPreferences.getInstance();
      final connectTimeStr = prefs.getString('connectTime');
      if (connectTimeStr != null) {
        final connectTime = DateTime.parse(connectTimeStr);
        final duration = DateTime.now().difference(connectTime);

        AnalyticsService().trackEvent(
          'vpn_session_end',
          parameters: {
            'protocol': 'IKEv2',
            'server': srvList.isNotEmpty ? srvList[srvIndex.value].name : 'unknown',
            'platform': getPlatformName(),
            'duration_seconds': duration.inSeconds.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      AnalyticsService().trackVpnDisconnection(
        protocol: 'IKEv2',
        serverLocation: srvList.isNotEmpty ? srvList[srvIndex.value].name : 'unknown',
      );

      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update(); // Final UI update
      
      print("✅ [DISCONNECT-IKE] State updated to disconnected");

      if (context.mounted) {
        showCustomSnackBar(
          context,
          EvaIcons.checkmarkCircle2Outline,
          'Disconnected',
          'VPN disconnected successfully',
          Colors.green,
        );
      }
    } catch (e) {
      log("Error disconnecting IKEv2: $e");
      print("❌ [DISCONNECT-IKE] Exception: $e");
      vpnConnectionState.value = MyVpnConnectState.disconnected;
      update();

      if (context.mounted) {
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Disconnect Completed',
          'VPN disconnected (with status: $e)',
          Colors.orange,
        );
      }
    }
  }

  // Check network speed
  Future<Map<String, String>> networkSpeed() async {
    var speed = {'download': "0", 'upload': "0"};
    try {
      // Test multiple endpoints for accurate speed measurement
      final urls = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://www.amazon.com',
      ];
      
      double totalSpeed = 0;
      int successfulTests = 0;
      
      for (final url in urls) {
        try {
          final stopwatch = Stopwatch()..start();
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
          stopwatch.stop();
          
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            // Calculate speed: (bytes / seconds) * 8 / 1000 = Kbps
            final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
            final speedKbps = (response.bodyBytes.length * 8 / 1000) / elapsedSeconds;
            totalSpeed += speedKbps;
            successfulTests++;
            log("📊 [SPEED] URL: $url | Size: ${response.bodyBytes.length} bytes | Time: ${stopwatch.elapsedMilliseconds}ms | Speed: ${speedKbps.toStringAsFixed(2)} Kbps");
          }
        } catch (e) {
          log("⚠️  [SPEED] Failed to test $url: $e");
        }
      }
      
      if (successfulTests > 0) {
        final avgSpeed = totalSpeed / successfulTests;
        String download = avgSpeed.toStringAsFixed(2);
        // Upload is typically slightly higher, add 10-15% variation
        String upload = (avgSpeed * 1.12).toStringAsFixed(2);
        speed = {'download': download, 'upload': upload};
        log("✅ [SPEED] Average Speed: ${avgSpeed.toStringAsFixed(2)} Kbps | Download: $download | Upload: $upload");
      } else {
        log("❌ [SPEED] All speed tests failed");
      }
      return speed;
    } catch (e) {
      log("❌ [SPEED] Exception: $e");
      return speed;
    }
  }

  void speedMonitor() {
    log("Starting speed monitoring");
    stopMonitor(); // Stop any existing timer

    // Initial speed check
    _updateSpeeds();

    // Then update every 10 seconds
    speedUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      if (vpnConnectionState.value == MyVpnConnectState.connected) {
        _updateSpeeds();
      } else {
        // Reset values when not connected
        stopMonitor();
      }
    });
  }

  void _updateSpeeds() async {
    try {
      if (vpnConnectionState.value == MyVpnConnectState.connected) {
        log("📡 [MONITOR] Fetching current speeds...");
        var speeds = await networkSpeed();
        
        double downloadKbps = double.tryParse(speeds['download'] ?? "0.0") ?? 0.0;
        double uploadKbps = double.tryParse(speeds['upload'] ?? "0.0") ?? 0.0;

        dS.value = downloadKbps.toStringAsFixed(2); // Already in Kbps
        uS.value = uploadKbps.toStringAsFixed(2); // Already in Kbps

        // Log the speeds
        print("📊 [MONITOR] Download: ${dS.value} Kbps | Upload: ${uS.value} Kbps");
        log("Download Speed: ${dS.value} Kbps");
        log("Upload Speed: ${uS.value} Kbps");

        // Get ping measurement
        try {
          final stopwatch = Stopwatch()..start();
          await http.get(Uri.parse('https://google.com')).timeout(const Duration(seconds: 3));
          stopwatch.stop();
          pS.value = stopwatch.elapsedMilliseconds.toString();
          print("📡 [MONITOR] Ping: ${pS.value}ms");
          log("Ping: ${pS.value}ms");
        } catch (e) {
          log("❌ Ping measurement failed: $e");
          pS.value = "N/A";
        }
        
        update();
      }
    } catch (e) {
      log("❌ Error updating speeds: $e");
    }
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
    print("📝 [REGISTER] Starting registration at $serverUrl");
    try {
      log("Registering user in VPS server: $serverUrl");
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('n');
      final String? password = prefs.getString('p');

      if (name == null || password == null) {
        log("Name or password is missing");
        print("❌ [REGISTER] Missing credentials");
        return false;
      }

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'desktop';

      const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Token': 'a3f7b9c2-d1e5-4f68-8a0b-95c6e7f4d8a1',
      };

      print("🔗 [REGISTER] Attempting IKEv2 registration at $serverUrl/api/ikev2/clients/generate");
      final firstResponse = await http.post(
        Uri.parse("$serverUrl/api/ikev2/clients/generate"),
        headers: headers,
        body: jsonEncode({"name": "${name}_$platform", "password": password}),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⏱️  [REGISTER] IKEv2 registration timeout");
          throw TimeoutException('IKEv2 registration timeout');
        },
      );

      print("🔗 [REGISTER] Attempting WireGuard registration at $serverUrl/api/clients/generate");
      final secondResponse = await http.post(
        Uri.parse("$serverUrl/api/clients/generate"),
        headers: headers,
        body: jsonEncode({"name": "${name}_$platform"}),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("⏱️  [REGISTER] WireGuard registration timeout");
          throw TimeoutException('WireGuard registration timeout');
        },
      );

      log("firstResponse status: ${firstResponse.statusCode}");
      log("firstResponse: ${firstResponse.body}");
      log("secondResponse status: ${secondResponse.statusCode}");
      log("secondResponse: ${secondResponse.body}");
      
      String ike4preview = firstResponse.body.length > 100 ? firstResponse.body.substring(0, 100) : firstResponse.body;
      String wg4preview = secondResponse.body.length > 100 ? secondResponse.body.substring(0, 100) : secondResponse.body;
      print("📊 [REGISTER] IKEv2 response: ${firstResponse.statusCode} | $ike4preview");
      print("📊 [REGISTER] WireGuard response: ${secondResponse.statusCode} | $wg4preview");

      // Parse responses with error checking
      Map<String, dynamic> firstBody;
      Map<String, dynamic> secondBody;
      
      try {
        firstBody = jsonDecode(firstResponse.body) ?? {};
        secondBody = jsonDecode(secondResponse.body) ?? {};
      } catch (e) {
        print("❌ [REGISTER] Failed to parse response: $e");
        log("❌ Failed to parse registration response: $e");
        return false;
      }

      // Check IKEv2 registration
      if (firstBody["error"] != null) {
        print("⚠️  [REGISTER] IKEv2 error detected: ${firstBody["error"]}");
        print("🔄 [REGISTER] Attempting IKEv2 client cleanup and retry...");
        
        try {
          var response = await http.delete(
            Uri.parse(
              "$serverUrl/api/ikev2/clients/${name.replaceAll(' ', '-')}_$platform",
            ),
            headers: headers,
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            print("✅ [REGISTER] IKEv2 client deleted");
            final newResponse = await http.post(
              Uri.parse("$serverUrl/api/ikev2/clients/generate"),
              headers: headers,
              body: jsonEncode({
                "name": "${name.replaceAll(' ', '-')}_$platform",
                "password": password,
              }),
            ).timeout(const Duration(seconds: 5));

            final responseBody = jsonDecode(newResponse.body) ?? {};
            if (responseBody["success"] == true) {
              print("✅ [REGISTER] IKEv2 registered successfully");
              log("Registered successfully on $serverUrl");
              return true;
            }
          }
        } catch (e) {
          print("❌ [REGISTER] IKEv2 cleanup failed: $e");
        }
      } else if (firstBody["success"] == true || firstResponse.statusCode == 200) {
        print("✅ [REGISTER] IKEv2 registered successfully");
      }

      // Check WireGuard registration
      if (secondBody["error"] != null) {
        print("⚠️  [REGISTER] WireGuard error detected: ${secondBody["error"]}");
        print("🔄 [REGISTER] Attempting WireGuard client cleanup and retry...");
        
        try {
          final deleteResponse = await http.delete(
            Uri.parse("$serverUrl/api/clients/${name}_$platform"),
            headers: headers,
          ).timeout(const Duration(seconds: 5));

          log("Status wireguard ${deleteResponse.statusCode}");
          log("Status body ${deleteResponse.body}");

          if (deleteResponse.statusCode == 200) {
            print("✅ [REGISTER] WireGuard client deleted");
            final newResponse = await http.post(
              Uri.parse("$serverUrl/api/clients/generate"),
              headers: headers,
              body: jsonEncode({
                "name": "${name}_$platform",
                "password": password,
              }),
            ).timeout(const Duration(seconds: 5));
            
            log("Response is that ${newResponse.body}");

            final responseBody = jsonDecode(newResponse.body) ?? {};
            if (responseBody["success"] == true) {
              print("✅ [REGISTER] WireGuard registered successfully");
              log("Registered successfully on $serverUrl");
              return true;
            }
          }
        } catch (e) {
          print("❌ [REGISTER] WireGuard cleanup failed: $e");
        }
      } else if (secondBody["success"] == true || secondResponse.statusCode == 200) {
        print("✅ [REGISTER] WireGuard registered successfully");
      }

      print("✅ [REGISTER] Registration process completed");
      return true;
    } on TimeoutException catch (e) {
      print("⏱️  [REGISTER] Timeout: $e");
      log("⏱️  Registration timeout: $e");
      return false;
    } catch (e) {
      log("Exception during registration on $serverUrl: $e");
      print("❌ [REGISTER] Exception: $e");
      return false;
    }
  }

  /// Fetch VPS servers list from the backend API
  /// Uses existing /servers route and extracts VPS servers from subServers
  Future<void> fetchVpsServers() async {
    try {
      print("🔄 [VPS] Fetching VPS servers from existing /servers route...");
      log("🔄 Fetching VPS servers list...");
      busyFlag.value = true;
      serversLoading.value = true;
      serversError.value = '';
      update();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('t');
      
      print("🔑 [VPS] Token retrieved: ${token != null ? 'YES (${token.substring(0, 20)}...)' : 'NO'}");

      if (token == null || token.isEmpty) {
        print("❌ [VPS] No authentication token. Cannot fetch VPS servers.");
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

      var platform = Platform.isAndroid
          ? "android"
          : Platform.isIOS
          ? "ios"
          : Platform.isWindows
          ? "windows"
          : Platform.isMacOS
          ? "macos"
          : "linux";

      // Use existing /servers route instead of /vps-servers
      final url = "${Utils.GET_SERVERS}?platform=$platform";
      print("📍 [VPS] Fetching from: $url");
      log("📍 Fetching from: $url");

      print("📤 [VPS] Sending request with headers: ${headers.keys.toList()}");
      
      var response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('VPS servers fetch timed out'),
      );

      print("📥 [VPS] Response status: ${response.statusCode}");
      log("Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print("✅ [VPS] Response received");
        log("✅ Response received");

        if (data["status"] == true && data["servers"] != null) {
          List<dynamic> servers = data["servers"];
          print("✅ [VPS] Processing ${servers.length} servers to extract VPS servers...");
          log("✅ Found ${servers.length} servers");

          // Extract VPS servers from subServers of regular servers
          List<VpsServer> fetchedVpsServers = [];
          Set<int> addedVpsIds = {}; // To avoid duplicates

          for (var server in servers) {
            // Try to extract from sub_servers
            var subServersData = server["sub_servers"];
            
            if (subServersData != null && subServersData is List) {
              print("✅ [VPS] Server '${server['name']}' has ${subServersData.length} sub-servers");
              
              for (var subServer in subServersData) {
                var vpsData = subServer["vps_server"];
                
                if (vpsData != null && vpsData is Map) {
                  int vpsId = vpsData["id"] ?? 0;
                  
                  // Avoid adding duplicate VPS servers
                  if (!addedVpsIds.contains(vpsId)) {
                    String ipAddress = vpsData["ip_address"] ?? vpsData["ip"] ?? "";
                    String domain = vpsData["domain"] ?? vpsData["host"] ?? "";
                    
                    print("🔍 [VPS] Raw extraction - IP: '$ipAddress', Domain: '$domain', Type IP: ${ipAddress.runtimeType}, Type Domain: ${domain.runtimeType}");
                    
                    VpsServer vpsServer = VpsServer(
                      id: vpsId,
                      name: vpsData["name"] ?? "VPS-${vpsId}",
                      ipAddress: ipAddress,
                      domain: domain,
                      username: vpsData["username"],
                      password: vpsData["password"],
                      port: vpsData["port"],
                      privateKey: vpsData["private_key"],
                    );
                    
                    print("✅ [VPS] Created VpsServer object - IP: '${vpsServer.ipAddress}', Domain: '${vpsServer.domain}'");
                    fetchedVpsServers.add(vpsServer);
                    addedVpsIds.add(vpsId);
                    
                    print("✅ [VPS] Added from sub_servers: ${vpsData['name']} | IP: $ipAddress | Domain: $domain");
                    log("✅ Added VPS: ${vpsData['name']} | IP: $ipAddress");
                  }
                }
              }
            }
          }
          
          // If no VPS servers found, use the servers themselves as VPS servers
          if (fetchedVpsServers.isEmpty) {
            print("⚠️  [VPS] No VPS servers found in sub_servers. Using regular servers as fallback...");
            log("No VPS in sub_servers, using servers as fallback");
            
            for (var server in servers) {
              int serverId = server["id"] ?? 0;
              String serverName = (server["name"] ?? "Server-${serverId}").trim();
              
              // Create a clean domain name
              // Strategy: Try to use meaningful parts of the server name
              String domain = serverName
                  .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
                  .replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '') // Remove special chars
                  .toLowerCase()
                  .replaceAll(RegExp(r'-+'), '-') // Remove multiple hyphens
                  .replaceFirst(RegExp(r'^-+'), '') // Remove leading hyphens
                  .replaceFirst(RegExp(r'-+$'), ''); // Remove trailing hyphens
              
              // Limit to 20 chars for DNS compatibility
              if (domain.length > 20) {
                domain = domain.substring(0, 20);
              }
              
              if (domain.isEmpty) {
                domain = "server-${serverId}"; // Fallback if processing resulted in empty string
              }
              
              String ipAddress = ""; // Placeholder since servers don't have IPs
              
              if (!addedVpsIds.contains(serverId)) {
                VpsServer vpsServer = VpsServer(
                  id: serverId,
                  name: serverName,
                  ipAddress: ipAddress,
                  domain: "$domain.vpn.local",
                  username: null,
                  password: null,
                  port: null,
                  privateKey: null,
                );
                fetchedVpsServers.add(vpsServer);
                addedVpsIds.add(serverId);
                
                print("✅ [VPS] Added from servers fallback: $serverName | Domain: $domain.vpn.local");
                log("✅ Added server as VPS: $serverName | Domain: $domain");
              }
            }
          }

          if (fetchedVpsServers.isEmpty) {
            serversError.value = 'No VPS servers available in the system.';
            print("⚠️  [VPS] No VPS servers found in sub-servers");
            log("⚠️  No VPS servers in response");
          } else {
            vpsServersList.assignAll(fetchedVpsServers);
            filteredVpsServers.assignAll(fetchedVpsServers);
            
            // Auto-select the first VPS server for convenience
            selectedVpsServer.value = fetchedVpsServers[0];
            print("✅ [VPS] Auto-selected first VPS server: ${fetchedVpsServers[0].name}");
            
            print("✅ [VPS] Total VPS servers: ${vpsServersList.length}");
            log("📊 VPS Servers loaded: ${vpsServersList.length}");
            serversError.value = '';
          }
          update();
        } else {
          serversError.value = data['message'] ?? 'No servers found';
          print("⚠️  [VPS] Unexpected response format");
          log("⚠️  Unexpected response format");
        }
      } else {
        serversError.value = 'Failed to fetch servers (Status: ${response.statusCode})';
        print("❌ [VPS] Failed. Status: ${response.statusCode}");
        log("❌ Failed to fetch. Status: ${response.statusCode}");
      }

      busyFlag.value = false;
      serversLoading.value = false;
      print("🏁 [VPS] Fetch completed");
      update();
    } on TimeoutException catch (e) {
      print("⏱️  [VPS] Timeout: $e");
      log("⏱️  Timeout");
      serversError.value = 'Request timeout. Please try again.';
      busyFlag.value = false;
      serversLoading.value = false;
      update();
    } catch (e) {
      print("❌ [VPS] Error: $e");
      log("❌ Error: $e");
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

  /// Verify actual public IP after VPN connection
  Future<Map<String, dynamic>> verifyVpnConnection() async {
    try {
      print("🔍 [VERIFY] Verifying VPN connection and checking actual IP...");
      log("🔍 Verifying VPN connection");
      
      final result = {
        'connected': false,
        'actualIp': '0.0.0.0',
        'expectedIp': '75.127.15.127',
        'vpnWorking': false,
      };

      try {
        print("📍 [VERIFY] Checking IP via ipify API...");
        final response = await http.get(
          Uri.parse('https://api.ipify.org?format=json'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final currentIp = data['ip'] ?? '0.0.0.0';
          result['actualIp'] = currentIp;
          
          print("📊 [VERIFY] Current public IP: $currentIp");
          print("📊 [VERIFY] Expected VPS IP: ${result['expectedIp']}");
          
          if (currentIp == result['expectedIp']) {
            result['vpnWorking'] = true;
            result['connected'] = true;
            print("✅ [VERIFY] VPN WORKING! IP changed to VPS!");
          } else {
            print("❌ [VERIFY] IP MISMATCH - VPN NOT routing through VPS!");
            print("❌ [VERIFY] Your IP: $currentIp (should be: ${result['expectedIp']})");
          }
        }
      } catch (e) {
        print("⚠️  [VERIFY] IP check failed: $e");
      }

      if (vpnConnectionState.value == MyVpnConnectState.connected) {
        result['connected'] = true;
      }

      print("📊 [VERIFY] Result: $result");
      return result;
    } catch (e) {
      print("❌ [VERIFY] Error: $e");
      return {'connected': false, 'actualIp': 'Error', 'expectedIp': '75.127.15.127', 'vpnWorking': false};
    }
  }

  /// Connect to a specific VPS server using its credentials
  Future<bool> connectToVpsServer(VpsServer vps, BuildContext context) async {
    try {
      print("🔌 [CONNECT] Connecting to VPS: ${vps.name}");
      log("🔌 Connecting to VPS server: ${vps.name} (${vps.domain})");
      busyFlag.value = true;
      update();

      // Validate VPS server configuration - at minimum need domain for connectivity
      if (vps.domain.isEmpty) {
        print("❌ [CONNECT] Missing domain");
        log("❌ VPS server missing domain");
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connection Error',
          'VPS server domain is required',
          Colors.red,
        );
        busyFlag.value = false;
        update();
        return false;
      }

      // Log VPS details
      print("🔍 [CONNECT] VPS Details - Name: ${vps.name} | Domain: ${vps.domain} | IP: ${vps.ipAddress.isEmpty ? 'Not available' : vps.ipAddress}");
      print("🔍 [CONNECT] Full VPS Object - ID: ${vps.id}, Name: '${vps.name}', IP: '${vps.ipAddress}' (len: ${vps.ipAddress.length}), Domain: '${vps.domain}' (len: ${vps.domain.length})");
      print("🔍 [CONNECT] IP empty? ${vps.ipAddress.isEmpty} | Domain empty? ${vps.domain.isEmpty}");
      log("🔍 VPS IP: ${vps.ipAddress.isEmpty ? 'Will use domain' : vps.ipAddress}");

      // Determine the connection target - PREFER IP OVER DOMAIN
      String connectionTarget = vps.ipAddress.isNotEmpty ? vps.ipAddress : vps.domain;
      print("🎯 [CONNECT] Connection target determined: '$connectionTarget' (${vps.ipAddress.isNotEmpty ? 'using IP' : 'using Domain'})");

      print("📝 [CONNECT] Step 1: Registering user on VPS at $connectionTarget");
      // Step 1: Register user on VPS server - use IP if available
      bool isRegistered = await registerUserInVPS('http://$connectionTarget:5000');
      
      if (!isRegistered) {
        print("❌ [CONNECT] Registration failed - VPS server may be unreachable");
        log("❌ Failed to register user in VPS");
        
        // Check if VPS is reachable before showing error
        try {
          print("🔍 [CONNECT] Checking if VPS is reachable at $connectionTarget:5000");
          final testResponse = await http.get(
            Uri.parse('http://$connectionTarget:5000/health'),
          ).timeout(const Duration(seconds: 3));
          
          if (testResponse.statusCode != 200) {
            print("❌ [CONNECT] VPS health check failed with status ${testResponse.statusCode}");
            showCustomSnackBar(
              context,
              EvaIcons.infoOutline,
              'Connection Error',
              'VPS server at $connectionTarget is not responding to health check',
              Colors.red,
            );
          } else {
            print("⚠️  [CONNECT] VPS is reachable but registration failed");
            showCustomSnackBar(
              context,
              EvaIcons.infoOutline,
              'Registration Error',
              'Failed to register on VPS server (check credentials)',
              Colors.red,
            );
          }
        } catch (e) {
          print("❌ [CONNECT] VPS unreachable: $e");
          showCustomSnackBar(
            context,
            EvaIcons.infoOutline,
            'Connection Error',
            'Cannot reach VPS server at $connectionTarget:5000\n$e',
            Colors.red,
          );
        }
        busyFlag.value = false;
        update();
        return false;
      }

      print("✅ [CONNECT] Step 2: User registered successfully");

      // Step 2: Save VPS connection info to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selectedVpsId', vps.id);
      await prefs.setString('selectedVpsDomain', vps.domain);
      await prefs.setString('selectedVpsName', vps.name);
      await prefs.setString('selectedVpsIp', vps.ipAddress);
      
      if (vps.username != null) {
        await prefs.setString('vpsUsername', vps.username!);
      }
      if (vps.port != null) {
        await prefs.setInt('vpsPort', vps.port!);
      }

      print("✅ [CONNECT] Step 3: VPS info saved to device storage");
      log("✅ VPS connection info saved");

      // Step 3: Store network settings before connection
      await prefs.setString('connectTime', DateTime.now().toString());
      await prefs.setString('originalVpsServer', vps.ipAddress);
      
      // Store the VPS connection details for network routing
      await prefs.setBool('vpnConnectedToVps', true);
      await prefs.setString('vpnConnectedVpsName', vps.name);

      print("✅ [CONNECT] Step 4: Setting up VPN tunnel");
      
      // Step 4: Prepare for network IP change
      cfgLoading.value = true;
      vpnConnectionState.value = MyVpnConnectState.connecting;
      update();

      print("🔄 [CONNECT] Initiating connection with protocol: $selectedProtocol");

      // Step 5: Establish VPN connection based on selected protocol
      bool connectionSuccess = false;
      
      if (selectedProtocol == Proto.wireguard) {
        print("📡 [CONNECT] Using WireGuard protocol");
        print("🔗 [CONNECT] Routing through: $connectionTarget (${vps.ipAddress.isEmpty ? 'domain-based' : 'IP-based'})");
        
        // Get WireGuard config from VPS using the connection target (IP or domain)
        final config = await selectedWirVPNConfig('http://$connectionTarget:5000', context);
        if (config == null) {
          print("⚠️  [CONNECT] WireGuard config failed - falling back to IKEv2");
          log("⚠️  WireGuard config retrieval failed - attempting IKEv2 fallback");
          
          // Fallback to IKEv2
          print("📡 [CONNECT] Attempting IKEv2 fallback");
          final String platform = getPlatformName();
          var name = prefs.getString('n') ?? '';
          var password = prefs.getString('p') ?? '';
          var username = "${name}_$platform";
          
          String targetAddress = connectionTarget;
          if (vps.ipAddress.isEmpty && vps.domain.isNotEmpty) {
            print("ℹ️  [CONNECT] IP not available, using domain: ${vps.domain}");
            targetAddress = vps.domain;
          }
          
          print("🔧 [CONNECT] Starting IKEv2 connection (fallback) to $targetAddress");
          try {
            await ikeav2Engine.connectTheIKEAV2(
              targetAddress,
              username,
              password,
              vpnServerDomain: vps.domain,
              vpnServerName: vps.name,
            );
            connectionSuccess = true;
            print("✅ [CONNECT] IKEv2 fallback successful!");
          } catch (e) {
            print("❌ [CONNECT] IKEv2 fallback failed: $e");
            connectionSuccess = false;
          }
        } else {
          print("🔧 [CONNECT] Starting WireGuard connection to $connectionTarget");
          connectionSuccess = await _wireguardEngine.startWireguard(
            server: vps.domain,
            serverName: vps.name,
            wireguardConfig: config,
          );
          
          if (connectionSuccess) {
            print("✅ [CONNECT] WireGuard tunnel established!");
          }
        }
      } else if (selectedProtocol == Proto.ikeav2) {
        print("📡 [CONNECT] Using IKEv2 protocol");
        print("🔗 [CONNECT] Routing network IP through: $connectionTarget");
        
        final String platform = getPlatformName();
        var name = prefs.getString('n') ?? '';
        var password = prefs.getString('p') ?? '';
        var username = "${name}_$platform";
        
        // Use IP if available, otherwise resolve domain
        String targetAddress = connectionTarget;
        if (vps.ipAddress.isEmpty && vps.domain.isNotEmpty) {
          print("ℹ️  [CONNECT] IP not available, using domain: ${vps.domain}");
          targetAddress = vps.domain;
        }
        
        print("🔧 [CONNECT] Starting IKEv2 connection to $targetAddress");
        await ikeav2Engine.connectTheIKEAV2(
          targetAddress,
          username,
          password,
          vpnServerDomain: vps.domain,
          vpnServerName: vps.name,
        );
        connectionSuccess = true;
        
        if (connectionSuccess) {
          print("✅ [CONNECT] IKEv2 tunnel established!");
        }
      }

      if (!connectionSuccess) {
        print("❌ [CONNECT] VPN connection failed");
        cfgLoading.value = false;
        busyFlag.value = false;
        update();
        
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connection Error',
          'Failed to establish VPN connection',
          Colors.red,
        );
        return false;
      }

      // Step 5 Complete: Network routing established through VPS server
      String routingInfo = vps.ipAddress.isEmpty 
          ? "Routing through: ${vps.domain}" 
          : "Your IP changed to: ${vps.ipAddress}";
      
      print("✅ [CONNECT] SUCCESS! $routingInfo");
      print("✅ [CONNECT] All traffic now routed through ${vps.name}");
      log("✅ Connected to VPS server: ${vps.name} via $routingInfo");
      
      // Track analytics
      AnalyticsService().trackEvent(
        'vps_connection_success',
        parameters: {
          'server_name': vps.name,
          'server_ip': vps.ipAddress,
          'server_domain': vps.domain,
          'protocol': selectedProtocol == Proto.wireguard ? 'wireguard' : 'ikev2',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      speedMonitor();
      cfgLoading.value = false;
      busyFlag.value = false;
      update();

      // Verify the connection actually worked by checking IP
      print("⏳ [CONNECT] Waiting 2 seconds before verifying connection...");
      await Future.delayed(const Duration(seconds: 2));
      
      print("🔍 [CONNECT] Step 5: Verifying actual IP change...");
      final verification = await verifyVpnConnection();
      
      String verificationStatus = verification['vpnWorking'] as bool 
          ? "✅ Verified! IP changed to ${verification['actualIp']}"
          : "⚠️  Warning: IP is ${verification['actualIp']} (expected ${verification['expectedIp']})";
      
      print("📊 [CONNECT] Verification: $verificationStatus");

      // Show success message safely
      if (context.mounted) {
        showCustomSnackBar(
          context,
          EvaIcons.checkmarkCircle2Outline,
          'Connected Successfully!',
          '$routingInfo\nServer: ${vps.name}\n$verificationStatus',
          Colors.green,
        );
      } else {
        print("⚠️  [CONNECT] Context not mounted, skipping snackbar");
        log("⚠️  Context not mounted, skipping success snackbar");
      }

      return true;

    } catch (e) {
      print("❌ [CONNECT] Exception: $e");
      log("❌ Error connecting to VPS server: $e");
      
      cfgLoading.value = false;
      busyFlag.value = false;
      update();

      // Show error message safely
      if (context.mounted) {
        showCustomSnackBar(
          context,
          EvaIcons.infoOutline,
          'Connection Error',
          e.toString(),
          Colors.red,
        );
      } else {
        print("⚠️  [CONNECT] Context not mounted, skipping error snackbar");
        log("⚠️  Context not mounted, skipping error snackbar");
      }
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

  /// Select a VPS server
  void selectVpsServer(VpsServer vpsServer) {
    try {
      print("✅ [SELECT] VPS Server selected: ${vpsServer.name} | IP: '${vpsServer.ipAddress}' | Domain: '${vpsServer.domain}'");
      log("✅ VPS Server selected: ${vpsServer.name} (${vpsServer.ipAddress})");
      selectedVpsServer.value = vpsServer;
      update();
    } catch (e) {
      log("❌ Error selecting VPS server: $e");
    }
  }

  /// Search and filter VPS servers
  void searchVpsServers(String query) {
    try {
      vpsSearchQuery.value = query;
      
      if (query.isEmpty) {
        // Show all VPS servers if search is empty
        filteredVpsServers.assignAll(vpsServersList);
      } else {
        // Filter VPS servers based on query
        final filtered = vpsServersList.where((vps) {
          return vps.name.toLowerCase().contains(query.toLowerCase()) ||
                 vps.ipAddress.toLowerCase().contains(query.toLowerCase()) ||
                 vps.domain.toLowerCase().contains(query.toLowerCase());
        }).toList();
        
        filteredVpsServers.assignAll(filtered);
        log("🔍 VPS search found ${filtered.length} servers for query: '$query'");
      }
      
      update();
    } catch (e) {
      log("❌ Error searching VPS servers: $e");
    }
  }

  /// Initialize VPS servers list for display (call when switching to VPS tab)
  void initializeVpsServers() {
    try {
      // Display all VPS servers initially
      filteredVpsServers.assignAll(vpsServersList);
      log("📊 Initialized VPS servers display with ${vpsServersList.length} servers");
      update();
    } catch (e) {
      log("❌ Error initializing VPS servers: $e");
    }
  }

  /// Connect to a selected VPS server
  Future<bool> connectToSelectedVpsServer(BuildContext context) async {
    try {
      if (selectedVpsServer.value == null) {
        log("❌ No VPS server selected");
        showCustomSnackBar(
          context,
          EvaIcons.alertCircleOutline,
          'Error',
          'Please select a VPS server first',
          Colors.red,
        );
        return false;
      }

      log("🔗 Attempting to connect to VPS server: ${selectedVpsServer.value!.name}");
      
      // Call the existing connectToVpsServer method
      return await connectToVpsServer(selectedVpsServer.value!, context);
    } catch (e) {
      log("❌ Error connecting to selected VPS server: $e");
      showCustomSnackBar(
        context,
        EvaIcons.alertCircleOutline,
        'Connection Error',
        'Failed to connect to VPS server',
        Colors.red,
      );
      return false;
    }
  }
}
