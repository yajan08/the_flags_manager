// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import '../widgets/my_button.dart';      // ✅ Integrated
import '../widgets/my_text_field.dart'; // ✅ Integrated
import 'add_site_screen.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  final SiteService _siteService = SiteService();

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  @override
  void initState() {
    super.initState();
    _siteService.ensureDefaultSitesExist();
  }

  void _showEditDialog(Site site) {
    final controller = TextEditingController(text: site.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text(
          "Rename Site",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: MyTextField(
          controller: controller,
          hintText: "Enter site name",
          obscureText: false,
          prefixIcon: Icons.edit_location_alt_rounded,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: textMuted)),
                ),
              ),
              Expanded(
                child: MyButton(
                  text: "Save",
                  verticalPadding: 12,
                  onTap: () async {
                    try {
                      final updated = Site(
                        id: site.id,
                        name: controller.text.trim(),
                        activeFlags: site.activeFlags,
                        washingFlags: site.washingFlags,
                        stitchingFlags: site.stitchingFlags, // Added safety
                        disposedFlags: site.disposedFlags,   // Added safety
                      );
                      await _siteService.updateSite(updated);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteSite(String id) async {
    try {
      await _siteService.deleteSite(id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Management Sites",
          style: TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
      ),
      body: StreamBuilder<List<Site>>(
        stream: _siteService.getSites(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryOrange));
          }

          final sites = snapshot.data!;
          
          // ✅ Calculate Total Disposed Flags across all sites
          final totalDisposed = sites.fold<int>(
            0, 
            (sum, site) => sum + site.disposedFlags.fold(0, (s, f) => s + f.quantity)
          );

          sites.sort((a, b) => a.name.compareTo(b.name));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // ✅ Added Minimal Disposed Summary Card
              _buildDisposedSummaryCard(totalDisposed),
              
              const SizedBox(height: 24),
              const Text(
                "ALL REGISTERED SITES",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              // Existing Site List logic
              ...sites.map((site) {
                final isSystem = SiteService.systemSiteIds.contains(site.id);
                return _buildSiteTile(site, isSystem);
              }),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MyButton(
        text: "Add New Site",
        verticalPadding: 14,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSiteScreen()),
        ),
        prefixIcon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
      ),
    );
  }

  // ✅ Minimal Modern Disposed Summary Widget
  Widget _buildDisposedSummaryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withAlpha(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Disposed Flags",
                style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                count.toString(),
                style: const TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Helper to keep main build clean while preserving existing tile logic
  Widget _buildSiteTile(Site site, bool isSystem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSystem ? Colors.blueGrey.withAlpha(26) : primaryOrange.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSystem ? Icons.lock_outline_rounded : Icons.place_outlined,
            color: isSystem ? Colors.blueGrey : primaryOrange,
            size: 20,
          ),
        ),
        title: Text(
          site.name,
          style: const TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 16),
        ),
        subtitle: isSystem
            ? Text(
                "Restricted System Site",
                style: TextStyle(color: textMuted.withAlpha(179), fontSize: 12, fontWeight: FontWeight.w500),
              )
            : Text(
                "Custom Location",
                style: TextStyle(color: textMuted.withAlpha(179), fontSize: 12),
              ),
        trailing: isSystem
            ? null
            : PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.more_vert_rounded, color: textMuted),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(site);
                  } else if (value == 'delete') {
                    _deleteSite(site.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 12),
                        Text("Edit"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text("Delete", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}