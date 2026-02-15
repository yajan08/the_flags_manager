import 'dart:ui';
import 'package:flags_manager/screens/receive_flags_screen.dart';
import 'package:flags_manager/screens/site_detail_screen.dart';
import 'package:flags_manager/screens/transfer_flags_screen.dart';
import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import '../widgets/my_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SiteService siteService = SiteService();

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF6F6F6);

  final Set<String> expandedSites = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Flag Inventory",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      drawer: const MyDrawer(),
      body: Stack(
        children: [

          /// CONTENT
          StreamBuilder<List<Site>>(
            stream: siteService.getSites(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sites = snapshot.data!;
              final office = _findSite(sites, 'office');
              final godown = _findSite(sites, 'godown');
              final pending = _findSite(sites, 'pending');
              final disposed = _findSite(sites, 'disposed');

              final otherSites = sites.where((s) {
                final n = s.name.toLowerCase();
                return n != 'office' &&
                    n != 'godown' &&
                    n != 'pending' &&
                    n != 'disposed';
              }).toList();

              final totalFlags = sites.fold<int>(
                  0,
                  (sum, s) =>
                      sum +
                      s.activeFlags.fold(
                          0, (s2, f) => s2 + f.quantity));

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                child: ListView(
                  children: [

                    /// SUMMARY CARD
                    _buildSummaryCard(totalFlags),

                    const SizedBox(height: 24),

                    _buildSectionTitle("Core Sites"),
                    _buildExpandableCard(office),
                    _buildExpandableCard(godown),
                    _buildExpandableCard(pending),

                    const SizedBox(height: 24),

                    if (otherSites.isNotEmpty) ...[
                      _buildSectionTitle("Other Sites"),
                      ...otherSites.map(_buildExpandableCard),
                      const SizedBox(height: 24),
                    ],

                    _buildSectionTitle("Disposed"),
                    _buildExpandableCard(disposed),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),

          /// FLOATING GLASS ACTION BAR
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black12,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ReceiveFlagsScreen(),
                              ),
                            );
                          },
                          child: const Text("Add Flags"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryOrange,
                            side:
                                const BorderSide(color: primaryOrange),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TransferFlagsScreen(),
                              ),
                            );
                          },
                          child: const Text("Transfer"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Site _findSite(List<Site> sites, String name) {
    return sites.firstWhere(
      (s) => s.name.toLowerCase() == name,
      orElse: () => Site(
        id: name,
        name: name[0].toUpperCase() + name.substring(1),
        activeFlags: [],
        washingFlags: [],
      ),
    );
  }

  Widget _buildSummaryCard(int totalFlags) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Active Flags",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            totalFlags.toString(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildExpandableCard(Site site) {
    final isExpanded = expandedSites.contains(site.id);
    final total = site.activeFlags.fold<int>(
        0, (sum, f) => sum + f.quantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [

          /// HEADER
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            title: Text(
              site.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600),
            ),
            subtitle: Text("$total flags"),

            /// CHEVRON CONTROLS EXPANSION ONLY
            trailing: IconButton(
              icon: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more),
              ),
              onPressed: () {
                setState(() {
                  if (isExpanded) {
                    expandedSites.remove(site.id);
                  } else {
                    expandedSites.add(site.id);
                  }
                });
              },
            ),

            /// TAP ANYWHERE ELSE → GO TO DETAIL
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SiteDetailsScreen(site: site),
                ),
              );
            },
          ),

          /// EXPANDED CONTENT
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding:
                  const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: site.activeFlags.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "No flags available",
                        style:
                            TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: site.activeFlags.map((flag) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(flag.type)),
                              Expanded(child: Text(flag.size)),
                              Text(
                                flag.quantity.toString(),
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                  color: primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}