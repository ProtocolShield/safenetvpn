import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:safenetvpn/Repository/homeRepo.dart';
import 'package:get/get.dart';

class Serverview extends StatefulWidget {
  const Serverview({super.key});

  @override
  State<Serverview> createState() => _ServerviewState();
}

class _ServerviewState extends State<Serverview> {
  int selectedTabIndex = 1; // Server tab is selected
  int selectedFilterIndex = 0; // All Servers selected

  final List<String> filterTabs = [
    "All Servers",
    "Premium",
    "Favourites",
    "Free",
  ];

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<HomeRepo>(HomeRepo());
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            SizedBox(height: 20),
            const Text(
              "Select Server",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 20),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        provider.setSearchText(value);
                      },
                      onSubmitted: (_) {
                        if (provider.searchText.value.isEmpty) {
                          provider.filterServers(); // force reset when cleared
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(color: Color(0xFF888888)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFF888888), size: 20),
                ],
              ),
            ),

            // Filter Tabs
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filterTabs.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.blue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.filteredServers.length,

                  itemBuilder: (context, index) {
                    final server = provider.filteredServers[index];
                    final originalIndex = provider.servers.indexOf(server);
                    return Obx(
                      () => GestureDetector(
                        onTap: () {
                          provider.changeCountry(originalIndex, 0, context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 17,

                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Flag
                              Center(
                                child: CachedNetworkImage(imageUrl: server.image, height: 20,),
                              ),

                              const SizedBox(width: 16),

                              // Country Name
                              Expanded(
                                child: Text(
                                  server.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    // // Highlight if selected
                                    // backgroundColor:
                                    //     provider.selectedServerIndex ==
                                    //         originalIndex
                                    //     ? Colors.green.withOpacity(0.2)
                                    //     : Colors.transparent,
                                  ),
                                ),
                              ),

                              // Signal Strength
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${server.subServers[provider.selectedSubServerIndex.value].vpsServer.latency} ms",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 16),

                              // Connect Button
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          provider.selectedServerIndex ==
                                              originalIndex
                                          ? Colors.green
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                    color:
                                        provider.selectedServerIndex ==
                                            originalIndex
                                        ? Colors.green.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                  ),
                                  child:
                                      provider.selectedServerIndex ==
                                          originalIndex
                                      ? Container(
                                          padding: EdgeInsets.all(36.0),
                                          decoration: BoxDecoration(
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
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
