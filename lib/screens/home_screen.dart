import 'package:flags_manager/screens/receive_flags_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flag Inventory'),
        centerTitle: true,
      ),
      drawer: const MyDrawer(),

      body: StreamBuilder<List<Site>>(
        stream: siteService.getSites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sites = snapshot.data ?? [];

          final officeSite = sites.firstWhere(
            (s) => s.name.toLowerCase() == 'office',
            orElse: () => Site(id: 'office', name: 'Office', activeFlags: [], washingFlags: []),
          );

          final godownSite = sites.firstWhere(
            (s) => s.name.toLowerCase() == 'godown',
            orElse: () => Site(id: 'godown', name: 'Godown', activeFlags: [], washingFlags: []),
          );

          final pendingSite = sites.firstWhere(
            (s) => s.name.toLowerCase() == 'pending',
            orElse: () => Site(id: 'pending', name: 'Pending', activeFlags: [], washingFlags: []),
          );

          final otherSites = sites.where((s) {
            final name = s.name.toLowerCase();
            return name != 'office' &&
                name != 'godown' &&
                name != 'pending';
          }).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// ===== OFFICE =====
                  const Text(
                    'Office',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSiteCard(officeSite),

                  const SizedBox(height: 28),

                  /// ===== GODOWN =====
                  const Text(
                    'Godown',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSiteCard(godownSite),

                  const SizedBox(height: 28),

                  /// ===== PENDING =====
                  const Text(
                    'Pending',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSiteCard(pendingSite),

                  const SizedBox(height: 32),

                  /// ===== OTHER SITES =====
                  if (otherSites.isNotEmpty) ...[
                    const Text(
                      'Other Sites',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...otherSites.map(
                      (site) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildSiteCard(site),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),

      /// ===== FIXED BOTTOM BUTTONS =====
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReceiveFlagsScreen(),
                      ),
                    );
                  },
                  child: const Text('Add Flags'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Transfer Flags'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ===== SITE CARD (Clean Table Layout) =====
  Widget _buildSiteCard(Site site) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: site.activeFlags.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No flags available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            : Column(
                children: [
                  /// Table Header
                  Row(
                    children: const [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Type',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Size',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Qty',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  /// Table Rows
                  ...site.activeFlags.map(
                    (flag) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(flag.type)),
                          Expanded(flex: 2, child: Text(flag.size)),
                          Expanded(
                            flex: 1,
                            child: Text(
                              flag.quantity.toString(),
                              textAlign: TextAlign.right,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}