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
import 'package:safenetvpn/domain/models/plan.dart';
import 'package:safenetvpn/ui/core/ui/auth/auth.dart';
import 'dart:io' show Platform, InternetAddress;

import 'package:safenetvpn/utils/utils.dart' show Utils;
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_vpn/flutter_vpn.dart' show FlutterVpn;
import 'package:safenetvpn/ui/core/ui/premium/premium.dart' show Premium;
import 'package:wireguard_flutter/wireguard_flutter.dart' show WireGuardFlutter;
import 'package:safenetvpn/domain/models/server.dart'
    show Server, ServerResponse;
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

  Proto selectedProtocol = Proto.ikeav2;

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

  onItemTapped(int index) {
    selectedBottomIndex.value = index;
    update();
  }

  setProtocol(Proto protocol) async {
    selectedProtocol = protocol;
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
      selectedProtocol = Proto.wireguard;
    } else {
      selectedProtocol = Proto.ikeav2;
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

      if (response.statusCode != 200) {
        log("Error fetching premium data. Status: ${response.statusCode}");
        proActive.value = false;
        subscription.value = null;
        update();
        return;
      }

      // if message is unthenticated then logout user

      final data = jsonDecode(response.body);

      // if (data["message"] == "unauthenticated") {
      //   log("Unauthenticated. Logging out user.");
      //   // ERASE  the storage
      //   SharedPreferences prefs = await SharedPreferences.getInstance();
      //   await prefs.clear();
      //   // navigate the user to login screen
      //   Get.to(Auth());

      //   // authProvider.shatter();
      //   // call the logout function from CipherGateModel
      // }
      final subscriptionResponse = ActivePlanResponse.fromJson(data);

      if (subscriptionResponse.status &&
          subscriptionResponse.subscription != null) {
        final sub = subscriptionResponse.subscription!;
        subscription.value = sub;

        // Parse expiry dates
        DateTime expiry = sub.endsAt ?? DateTime.now();
        DateTime graceExpiry = sub.graceEndsAt ?? expiry;

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

  Future<bool> ruinvps(String serverUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? name = prefs.getString('n');
      final String? password = prefs.getString('p');

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

  Future<bool> cWireguard(String domain, BuildContext context) async {
    try {
      busyFlag.value = true;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('connectTime', DateTime.now().toString());

      cfgLoading.value = true;
      vpnConnectionState.value = MyVpnConnectState.connecting;
      update();

      // Add a short delay to allow UI to show 'connecting' state
      await Future.delayed(const Duration(milliseconds: 700));

      var isRegistered = await ruinvps('http://$domain:5000');
      if (!isRegistered) {
        log("Failed to register user in VPS");
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

      final success = await _wireguardEngine.startWireguard(
        server: domain,
        serverName: 'United States',
        wireguardConfig: config!,
      );
      speedMonitor();

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

      bool isRegistered = await ruinvps('http://$ip:5000');
      if (!isRegistered) {
        log("Failed to register user in VPS");
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
      // Keep _isGettingConfig true until after initiating connection

      final String platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : Platform.isWindows
          ? 'windows'
          : 'macos';

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
}
