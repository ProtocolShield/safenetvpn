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
  int selectedTabIndex = 1; // Server tab is selected
  int selectedFilterIndex = 0; // All Servers selected

  final List<String> filterTabs = [
    "All Servers",
    "Premium",
    "Free",
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
                        provider.setqueryText(
                          value,
                          filterTabs[selectedFilterIndex],
                        ); // pass current tab
                      },
                      // onSubmitted: (_) {
                      //   if (provider.searchText.value.isEmpty) {
                      //     provider.filterServers(); // force reset when cleared
                      //   }
                      // },
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
                    onTap: () {
                      setState(() {
                        selectedFilterIndex = index;
                      });
                      provider.filtersrvList(
                        filterTabs[index],
                      ); // pass tab type
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
                () => ListView.builder(
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
                              // Flag
                              Row(
                                children: [
                                  Center(
                                    child: CachedNetworkImage(
                                      imageUrl: server.image,
                                      height: 20,
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 10),
                                  
                                  // Country Name
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        server.name,
                                        style: TextStyle(
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
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Signal Strength
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        "${server.subServers[provider.subSrvIndex.value].vpsServer.latency} ms",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
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
                                      padding: EdgeInsets.all(3.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Color(0xFF3A3A3A),
                                          width: 1,
                                        ),
                                      ),
                                      child:
                                          provider.srvIndex.value ==
                                              originalIndex
                                          ? Container(
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
