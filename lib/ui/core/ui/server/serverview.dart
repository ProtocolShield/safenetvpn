import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart' show HomeGateModel;

class Serverview extends StatefulWidget {
  const Serverview({super.key});

  @override
  State<Serverview> createState() => _ServerviewState();
}

class _ServerviewState extends State<Serverview> {
  int selectedTabIndex = 1; // 0 = VPS Servers, 1 = Regular Servers
  int selectedFilterIndex = 0; // All Servers selected

  final List<String> filterTabs = [
    "All Servers",
    "Premium",
    "Free",
  ];

  final List<String> mainTabs = [
    "VPS Servers",
    "Regular Servers",
  ];

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<HomeGateModel>(HomeGateModel());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(height: 20),
            Text(
              "Select Server",
              style: GoogleFonts.daysOne(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),

            // Main Tabs (VPS vs Regular Servers)
            Container(
              height: 35,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(mainTabs.length, (index) {
                  bool isSelected = selectedTabIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTabIndex = index;
                          selectedFilterIndex = 0; // Reset filter when changing tabs
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Colors.purple, Colors.blue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            mainTabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF888888),
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              fontFamily: 'Poppins',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: 20),

            // Search Bar
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        if (selectedTabIndex == 0) {
                          // VPS Servers search
                          provider.searchVpsServers(value);
                        } else {
                          // Regular servers search
                          provider.setqueryText(
                            value,
                            filterTabs[selectedFilterIndex],
                          );
                        }
                      },
                      cursorColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Icon(
                    EvaIcons.search,
                    color: Color(0xFF888888),
                    size: 20,
                  ),
                ],
              ),
            ),

            // Filter Tabs - Show only for Regular Servers
            if (selectedTabIndex == 1)
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterTabs.length,
                  itemBuilder: (context, index) {
                    bool isSelected = selectedFilterIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedFilterIndex = index;
                        });
                        provider.filtersrvList(
                          filterTabs[index],
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Colors.purple, Colors.blue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            filterTabs[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFFEEEEEE),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 12),

            // Server List
            Expanded(
              child: Obx(
                () {
                  // Display VPS Servers
                  if (selectedTabIndex == 0) {
                    return _buildVpsServersList(provider);
                  }
                  // Display Regular Servers
                  else {
                    return _buildRegularServersList(provider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build VPS Servers List
  Widget _buildVpsServersList(HomeGateModel provider) {
    final vpsServers = provider.filteredVpsServers;
    
    if (vpsServers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              color: const Color(0xFF888888),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'No VPS Servers Available',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: vpsServers.length,
      itemBuilder: (context, index) {
        final vpsServer = vpsServers[index];
        final isSelected = provider.selectedVpsServer.value?.id == vpsServer.id;

        return GestureDetector(
          onTap: () {
            print("📱 [UI] VPS Server tapped: ${vpsServer.name}");
            provider.selectVpsServer(vpsServer);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 17,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2A2A2A).withValues(alpha: 0.8)
                  : const Color(0xFF1A1A1A),
              border: isSelected
                  ? Border.all(
                      color: Colors.purple.withValues(alpha: 0.5),
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Server Info
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      // Server Icon
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.dns,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Server Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vpsServer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      colors: [Colors.purple, Colors.blue],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(
                                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                    );
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'VPS',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  vpsServer.ipAddress.isNotEmpty 
                                    ? vpsServer.ipAddress 
                                    : vpsServer.domain,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 11,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Select & Connect Button Area
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select Button
                    GestureDetector(
                      onTap: () {
                        provider.selectVpsServer(vpsServer);
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.purple
                                : const Color(0xFF3A3A3A),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue, Colors.purple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              )
                            : null,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Connect Button
                    if (isSelected)
                      GestureDetector(
                        onTap: () {
                          provider.connectToVpsServer(vpsServer, context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Connect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
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
    );
  }

  // Build Regular Servers List
  Widget _buildRegularServersList(HomeGateModel provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.srvFiltered.length,
      itemBuilder: (context, index) {
        final server = provider.srvFiltered[index];
        final originalIndex = provider.srvList.indexOf(server);
        return Obx(
          () => GestureDetector(
            onTap: () {
              provider.cG(originalIndex, 0, context);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 17,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flag and Server Info
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: server.image,
                              height: 20,
                              width: 30,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 20,
                                width: 30,
                                color: const Color(0xFF333333),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 20,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333333),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Color(0xFF888888),
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // Country Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                server.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [Colors.purple, Colors.blue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(
                                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                                  );
                                },
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  server.type,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Signal Strength and Select Button
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.speed,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              server.subServers.isNotEmpty
                                ? "${server.subServers[0].vpsServer.latency} ms"
                                : "-- ms",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 5),
                        
                        // Connect Button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(3.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF3A3A3A),
                                width: 1,
                              ),
                            ),
                            child: provider.srvIndex.value == originalIndex
                              ? Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue,
                                        Colors.purple,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
