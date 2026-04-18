import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safenetvpn/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  String testOutput = 'Tap buttons below to test backend connectivity...\n\n';
  bool isLoading = false;

  void addLog(String message) {
    setState(() {
      testOutput += '${DateTime.now().toString().split('.')[0]} - $message\n';
    });
    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Scroll to bottom
      }
    });
  }

  Future<void> testBackendConnection() async {
    setState(() => isLoading = true);
    addLog('\n========== BACKEND CONNECTION TEST ==========');
    
    try {
      // Check token
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('t');
      
      addLog('1. Checking Authentication Token...');
      if (token == null || token.isEmpty) {
        addLog('❌ ERROR: No token found!');
        addLog('   You must login first before testing server list.');
        addLog('   Token key: "t"');
        setState(() => isLoading = false);
        return;
      }
      addLog('✅ Token found (${token.length} characters)');
      addLog('   Token preview: ${token.substring(0, 30)}...');
      
      // Check backend health
      addLog('\n2. Testing Backend Health...');
      try {
        var healthResponse = await http.get(
          Uri.parse(Utils.BASE_URL),
        ).timeout(const Duration(seconds: 5));
        
        addLog('   Base URL response: ${healthResponse.statusCode}');
      } catch (e) {
        addLog('   ⚠️  Base URL not accessible: $e');
      }
      
      // Test servers endpoint
      addLog('\n3. Fetching Servers from Backend...');
      addLog('   URL: ${Utils.GET_SERVERS}?platform=windows');
      
      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      var response = await http.get(
        Uri.parse('${Utils.GET_SERVERS}?platform=windows'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));
      
      addLog('   Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(response.body);
        addLog('✅ SUCCESS - Backend is responding!');
        addLog('   Response Status: ${data['status']}');
        
        if (data['servers'] != null) {
          List servers = data['servers'] as List;
          addLog('   Servers Count: ${servers.length}');
          
          if (servers.isNotEmpty) {
            addLog('   \n--- Server Details ---');
            for (int i = 0; i < (servers.length > 3 ? 3 : servers.length); i++) {
              var srv = servers[i];
              addLog('   Server ${i + 1}:');
              addLog('      Name: ${srv['name'] ?? 'N/A'}');
              addLog('      Country: ${srv['country'] ?? 'N/A'}');
              addLog('      Image: ${srv['image'] != null ? '✅' : '❌'}');
              addLog('      SubServers: ${srv['sub_servers']?.length ?? 0}');
              if (srv['sub_servers'] != null && (srv['sub_servers'] as List).isNotEmpty) {
                var subSrv = srv['sub_servers'][0];
                addLog('         First SubServer Domain: ${subSrv['vps_server']['domain'] ?? 'N/A'}');
              }
            }
            if (servers.length > 3) {
              addLog('   ... and ${servers.length - 3} more servers');
            }
          } else {
            addLog('❌ ERROR: No servers returned (empty list)');
          }
        } else {
          addLog('❌ ERROR: No servers field in response');
        }
      } else if (response.statusCode == 401) {
        addLog('❌ ERROR 401 - UNAUTHORIZED');
        addLog('   Token may be invalid or expired');
        addLog('   Please login again');
      } else if (response.statusCode == 403) {
        addLog('❌ ERROR 403 - FORBIDDEN');
        addLog('   You may not have permission to access servers');
      } else if (response.statusCode == 404) {
        addLog('❌ ERROR 404 - NOT FOUND');
        addLog('   Backend API endpoint not found');
      } else {
        addLog('❌ ERROR ${response.statusCode}');
        addLog('   Response: ${response.body.substring(0, 200)}');
      }
    } catch (e) {
      addLog('❌ ERROR: Connection failed');
      addLog('   $e');
    }
    
    addLog('\n========== END TEST ==========\n');
    setState(() => isLoading = false);
  }

  Future<void> testWithoutToken() async {
    setState(() => isLoading = true);
    addLog('\n========== TEST WITHOUT TOKEN (No Auth) ==========');
    
    try {
      addLog('Testing servers endpoint without authentication...');
      addLog('URL: ${Utils.GET_SERVERS}?platform=windows');
      
      var response = await http.get(
        Uri.parse('${Utils.GET_SERVERS}?platform=windows'),
      ).timeout(const Duration(seconds: 10));
      
      addLog('Response Status: ${response.statusCode}');
      
      if (response.statusCode == 401 || response.statusCode == 403) {
        addLog('✅ EXPECTED: Backend requires authentication');
        addLog('   Status: ${response.statusCode}');
      } else if (response.statusCode == 200) {
        addLog('⚠️  UNEXPECTED: Backend returned data without auth');
        var data = jsonDecode(response.body);
        addLog('   Servers: ${data['servers']?.length ?? 0}');
      } else {
        addLog('Response: ${response.body.substring(0, 150)}');
      }
    } catch (e) {
      addLog('❌ ERROR: $e');
    }
    
    addLog('========== END TEST ==========\n');
    setState(() => isLoading = false);
  }

  Future<void> runDiagnostics() async {
    setState(() => isLoading = true);
    addLog('\n========== RUNNING FULL DIAGNOSTICS ==========');
    
    try {
      var provider = Get.find<HomeGateModel>();
      
      // Call the diagnostic method
      addLog('Calling HomeGateModel.checkBackendConnection()...');
      await provider.checkBackendConnection();
      
      addLog('✅ Diagnostics completed. Check console logs for detailed output.');
    } catch (e) {
      addLog('❌ ERROR: $e');
    }
    
    addLog('========== END DIAGNOSTICS ==========\n');
    setState(() => isLoading = false);
  }

  Future<void> testVpsServers() async {
    setState(() => isLoading = true);
    addLog('\n========== VPS SERVERS TEST ==========');
    
    try {
      var provider = Get.find<HomeGateModel>();
      
      addLog('Fetching VPS servers...');
      await provider.fetchVpsServers();
      
      addLog('✅ VPS fetch completed.');
      addLog('   Loading state: ${provider.serversLoading.value}');
      addLog('   Error message: ${provider.serversError.value.isEmpty ? "None" : provider.serversError.value}');
      
      // Log server structure
      int totalVps = 0;
      for (var server in provider.srvList) {
        if (server.subServers.isNotEmpty) {
          addLog('Server: ${server.name} (ID: ${server.id})');
          addLog('   SubServers: ${server.subServers.length}');
          for (var sub in server.subServers) {
            addLog('   - ${sub.vpsServer.name}');
            addLog('     Domain: ${sub.vpsServer.domain}');
            addLog('     IP: ${sub.vpsServer.ipAddress}');
            addLog('     User: ${sub.vpsServer.username ?? "N/A"}');
            totalVps++;
          }
        }
      }
      
      addLog('Total VPS servers found: $totalVps');
    } catch (e) {
      addLog('❌ ERROR: $e');
    }
    
    addLog('========== END VPS TEST ==========\n');
    setState(() => isLoading = false);
  }

  void clearLog() {
    setState(() {
      testOutput = 'Logs cleared. Tap buttons to start testing...\n\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Test Console'),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Buttons
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : testBackendConnection,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Test with Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : testWithoutToken,
                        icon: const Icon(Icons.cloud_off),
                        label: const Text('Test No Auth'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : runDiagnostics,
                        icon: const Icon(Icons.construction),
                        label: const Text('Full Diagnostics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : testVpsServers,
                        icon: const Icon(Icons.storage),
                        label: const Text('Test VPS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: clearLog,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          disabledBackgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Log Output
          Expanded(
            child: Container(
              color: const Color(0xFF0F0F12),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: SelectableText(
                  testOutput,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    color: Color(0xFF00FF00),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Loading indicator
          if (isLoading)
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.all(8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Testing...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
