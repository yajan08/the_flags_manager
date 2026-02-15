import 'dart:ui';
import 'package:flags_manager/models/user.dart';
import 'package:flags_manager/screens/receive_flags_screen.dart';
import 'package:flags_manager/screens/site_detail_screen.dart';
import 'package:flags_manager/screens/transfer_flags_screen.dart';
import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import '../widgets/my_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SiteService siteService = SiteService();
  final UserService userService = UserService();
  AppUser? currentUser;

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color bgColor = Color(0xFFF8F9FA); // Slightly cooler, cleaner white
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
  
  final Set<String> expandedSites = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final userData = await userService.getCurrentUserData(firebaseUser.uid);
      if (!mounted) return;
      setState(() {
        currentUser = userData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true, // Allows content to show behind glass bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          "Flag Inventory",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      drawer: const MyDrawer(),
      body: Stack(
        children: [
          StreamBuilder<List<Site>>(
            stream: siteService.getSites(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: primaryOrange));
              }

              final sites = snapshot.data!;
              final office = _findSite(sites, 'office');
              final godown = _findSite(sites, 'godown');
              final pending = _findSite(sites, 'pending');
              final disposed = _findSite(sites, 'disposed');

              final otherSites = sites.where((s) {
                final n = s.name.toLowerCase();
                return n != 'office' && n != 'godown' && n != 'pending' && n != 'disposed';
              }).toList();

              final totalFlags = sites.fold<int>(
                  0,
                  (sum, s) => sum +
                      s.activeFlags.fold(0, (s2, f) => s2 + f.quantity));

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSummaryCard(totalFlags),
                  const SizedBox(height: 32),
                  _buildSectionHeader("Core Sites", Icons.home_outlined),
                  _buildExpandableCard(office, hasAccent: true),
                  _buildExpandableCard(godown, hasAccent: true),
                  _buildExpandableCard(pending, hasAccent: true),
                  const SizedBox(height: 32),
                  if (otherSites.isNotEmpty) ...[
                    _buildSectionHeader("Other Locations", Icons.place_outlined),
                    ...otherSites.map((s) => _buildExpandableCard(s)),
                    const SizedBox(height: 32),
                  ],
                  _buildSectionHeader("Archives", Icons.delete_outline_rounded),
                  _buildExpandableCard(disposed, isArchive: true),
                ],
              );
            },
          ),
          _buildGlassActionBar(),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textMuted),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalFlags) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withAlpha(77), // 0.3 * 255
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentOrange, primaryOrange],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.flag, size: 120, color: Colors.white.withAlpha(26)), // 0.1 * 255
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Active Inventory",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalFlags.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableCard(Site site, {bool hasAccent = false, bool isArchive = false}) {
    final isExpanded = expandedSites.contains(site.id);
    final total = site.activeFlags.fold<int>(0, (sum, f) => sum + f.quantity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isExpanded ? primaryOrange.withAlpha(77) : Colors.transparent), // 0.3 * 255
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withAlpha(10), // 0.04 * 255
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: hasAccent 
                ? Container(width: 4, height: 24, decoration: BoxDecoration(color: primaryOrange, borderRadius: BorderRadius.circular(2)))
                : null,
              title: Text(
                site.name,
                style: const TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "$total flags in stock",
                  style: TextStyle(color: isArchive ? textMuted : primaryOrange, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
              trailing: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: textDark),
                ),
              ),
              onTap: () {
                if (!mounted) return;
                setState(() {
                  if (isExpanded) {
                    expandedSites.remove(site.id);
                  } else {
                    expandedSites.add(site.id);
                  }
                });
              },
              onLongPress: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SiteDetailsScreen(site: site)));
              },
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              secondChild: const SizedBox.shrink(),
              firstChild: Column(
                children: [
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: site.activeFlags.isEmpty
                        ? const Text("No active inventory", style: TextStyle(color: textMuted, fontStyle: FontStyle.italic))
                        : Column(
                            children: site.activeFlags.map((flag) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                                      child: Text(flag.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(flag.size, style: const TextStyle(color: textMuted, fontSize: 12)),
                                    const Spacer(),
                                    Text(
                                      flag.quantity.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 15),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SiteDetailsScreen(site: site))),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: bgColor.withAlpha(128), // 0.5 * 255
                      child: const Center(
                        child: Text("VIEW FULL DETAILS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassActionBar() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(204), // 0.8 * 255
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(128), width: 1.5), // 0.5 * 255
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 24, offset: const Offset(0, 8)) // 0.08 * 255
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "Add Flags",
                    icon: Icons.add_rounded,
                    isPrimary: true,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiveFlagsScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: "Transfer",
                    icon: Icons.swap_horiz_rounded,
                    isPrimary: false,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferFlagsScreen())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: primaryOrange.withAlpha(128)), // 0.5 * 255
          boxShadow: isPrimary ? [
            BoxShadow(color: primaryOrange.withAlpha(77), blurRadius: 12, offset: const Offset(0, 4)) // 0.3 * 255
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : primaryOrange, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : primaryOrange,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}