// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../models/site.dart';
import '../models/flag.dart';
import '../models/inventory_log.dart'; 
import '../services/site_service.dart';
import '../widgets/my_button.dart';
import '../widgets/my_text_field.dart';
import 'package:intl/intl.dart'; 

class SiteDetailsScreen extends StatefulWidget {
  final Site site;

  const SiteDetailsScreen({super.key, required this.site});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  final SiteService siteService = SiteService();

  final Map<String, int> selectedActiveQty = {};
  final Map<String, int> selectedWashingQty = {};
  final Map<String, int> selectedStitchingQty = {}; 
  final Set<String> expandedItems = {}; 

  String searchQuery = "";
  String selectedFilter = "All"; 
  bool isProcessing = false;

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  @override
  void initState() {
    super.initState();
    _ensureDefaultSites();
  }

  Future<void> _ensureDefaultSites() async {
    try {
      await siteService.ensureDefaultSitesExist();
    } catch (e) {
      debugPrint("Error ensuring default sites: $e");
    }
  }

  List<Flag> _filterFlags(List<Flag> flags) {
    return flags.where((flag) {
      final matchesSearch = flag.size.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = selectedFilter == "All" || flag.type == selectedFilter;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          widget.site.name,
          style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterHeader(),
          Expanded(
            child: StreamBuilder<List<Site>>(
              stream: siteService.getSites(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: primaryOrange));
                }

                final updatedSite = snapshot.data!.firstWhere(
                  (s) => s.id == widget.site.id,
                  orElse: () => snapshot.data!.isNotEmpty
                      ? snapshot.data!.first
                      : Site(id: 'pending', name: 'Pending', activeFlags: [], washingFlags: []),
                );

                final filteredActive = _filterFlags(updatedSite.activeFlags);
                final filteredWashing = _filterFlags(updatedSite.washingFlags);
                final filteredStitching = _filterFlags(updatedSite.stitchingFlags); 
                final filteredDisposed = _filterFlags(updatedSite.disposedFlags); 

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _sectionHeader("Active Inventory", Icons.check_circle_outline_rounded),
                    if (filteredActive.isEmpty)
                      _emptyBox("No flags match your filters")
                    else
                      ...filteredActive.map((flag) => _buildActiveCard(flag)),

                    const SizedBox(height: 32),
                    _sectionHeader("Washing Queue", Icons.local_laundry_service_outlined),
                    if (filteredWashing.isEmpty)
                      _emptyBox("No flags in washing match your filters")
                    else
                      ...filteredWashing.map((flag) => _buildWashingCard(flag)),

                    const SizedBox(height: 32), 
                    _sectionHeader("Stitching / Repair", Icons.handyman_outlined),
                    if (filteredStitching.isEmpty)
                      _emptyBox("No flags in stitching match your filters")
                    else
                      ...filteredStitching.map((flag) => _buildStitchingCard(flag)),

                    const SizedBox(height: 32), 
                    _sectionHeader("Disposed / Torn", Icons.delete_outline_rounded),
                    if (filteredDisposed.isEmpty)
                      _emptyBox("No flags disposed yet")
                    else
                      ...filteredDisposed.map((flag) => _buildDisposedCard(flag)),

                    const SizedBox(height: 32),
                    _sectionHeader("Recent Activity", Icons.history_rounded),
                    _buildSiteHistoryList(updatedSite.name),
                    
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDispose(Flag flag, String source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Disposal"),
        content: Text("Are you sure you want to dispose of ${flag.quantity}x ${flag.type} (${flag.size})? This action is permanent."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              String reason = source == 'stitching' ? "Stitching" : source == 'washing' ? "Washing" : "General";
              _handleDisposal(flag, source, reason);
            },
            child: const Text("Dispose", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDisposal(Flag flag, String source, String reason) async {
    setState(() => isProcessing = true);
    try {
      final String userEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown User";
      await siteService.disposeFlags(
        siteId: widget.site.id,
        flags: [Flag(type: flag.type, size: flag.size, quantity: flag.quantity)],
        source: source,
        reason: reason,
        userEmail: userEmail,
      );
      _showSnack("Flags disposed: $reason");
    } catch (e) {
      _showSnack(e.toString());
    }
    setState(() => isProcessing = false);
  }

  Widget _buildActiveCard(Flag flag) {
    final key = "active_${flag.type}_${flag.size}";
    final isWashExp = expandedItems.contains(key);
    final isStitchExp = expandedItems.contains("${key}_stitch");
    
    final washCtrl = TextEditingController(text: selectedActiveQty[key]?.toString() ?? "");
    final stitchCtrl = TextEditingController(text: selectedStitchingQty[key]?.toString() ?? "");

    return _cardContainer(
      borderColor: primaryOrange.withAlpha(26),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _flagInfoBlock(flag, "Available: ${flag.quantity}"),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => isWashExp ? expandedItems.remove(key) : {expandedItems.remove("${key}_stitch"), expandedItems.add(key)}),
                    icon: Icon(isWashExp ? Icons.close : Icons.local_laundry_service_rounded),
                    color: primaryOrange,
                    style: IconButton.styleFrom(backgroundColor: primaryOrange.withAlpha(20)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => setState(() => isStitchExp ? expandedItems.remove("${key}_stitch") : {expandedItems.remove(key), expandedItems.add("${key}_stitch")}),
                    icon: Icon(isStitchExp ? Icons.close : Icons.handyman_rounded),
                    color: Colors.purple,
                    style: IconButton.styleFrom(backgroundColor: Colors.purple.withAlpha(20)),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: textMuted),
                    itemBuilder: (context) => [const PopupMenuItem(value: 'dispose', child: Text("Dispose Flag"))],
                    onSelected: (val) => _confirmDispose(flag, 'active'),
                  ),
                ],
              )
            ],
          ),
          if (isWashExp || isStitchExp) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MyTextField(
                    hintText: isWashExp ? "Qty to Wash" : "Qty to Stitch",
                    obscureText: false,
                    controller: isWashExp ? washCtrl : stitchCtrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.edit_note_rounded,
                    onChanged: (value) {
                      int qty = int.tryParse(value) ?? 0;
                      if (qty > flag.quantity) qty = flag.quantity;
                      if (isWashExp) {
                        selectedActiveQty[key] = qty;
                      } else {
                        selectedStitchingQty[key] = qty;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                MyButton(
                  text: "Send",
                  backgroundColor: isStitchExp ? Colors.purple : primaryOrange,
                  onTap: isProcessing ? null : () => isWashExp ? _moveToWashing(flag, key) : _handleMoveToStitching(flag, key),
                  horizontalPadding: 20,
                  borderRadius: 14,
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildWashingCard(Flag flag) {
    final key = "washing_${flag.type}_${flag.size}";
    final isExpanded = expandedItems.contains(key);
    final ctrl = TextEditingController(text: selectedWashingQty[key]?.toString() ?? "");

    return _cardContainer(
      color: const Color(0xFFF1F4F8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _flagInfoBlock(flag, "In Washing: ${flag.quantity}", labelColor: Colors.blueGrey),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => isExpanded ? expandedItems.remove(key) : expandedItems.add(key)),
                    icon: Icon(isExpanded ? Icons.close : Icons.restore_rounded),
                    color: Colors.green.shade700,
                    style: IconButton.styleFrom(backgroundColor: Colors.green.withAlpha(20)),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: textMuted),
                    itemBuilder: (context) => [const PopupMenuItem(value: 'dispose', child: Text("Dispose Flag"))],
                    onSelected: (val) => _confirmDispose(flag, 'washing'),
                  ),
                ],
              )
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MyTextField(
                    hintText: "Qty to Return",
                    obscureText: false,
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.restore_rounded,
                    onChanged: (value) {
                      int qty = int.tryParse(value) ?? 0;
                      if (qty > flag.quantity) qty = flag.quantity;
                      selectedWashingQty[key] = qty;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                MyButton(
                  text: "Return",
                  backgroundColor: Colors.green.shade600,
                  onTap: isProcessing ? null : () => _moveToActive(flag, key),
                  horizontalPadding: 20,
                  borderRadius: 14,
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStitchingCard(Flag flag) {
    final key = "stitch_${flag.type}_${flag.size}";
    final isExpanded = expandedItems.contains(key);
    final ctrl = TextEditingController(text: selectedStitchingQty[key]?.toString() ?? "");

    return _cardContainer(
      color: Colors.purple.withAlpha(5),
      borderColor: Colors.purple.withAlpha(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _flagInfoBlock(flag, "In Stitching: ${flag.quantity}", labelColor: Colors.purple),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => isExpanded ? expandedItems.remove(key) : expandedItems.add(key)),
                    icon: Icon(isExpanded ? Icons.close : Icons.check_circle_rounded),
                    color: Colors.purple,
                    style: IconButton.styleFrom(backgroundColor: Colors.purple.withAlpha(15)),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: textMuted),
                    itemBuilder: (context) => [const PopupMenuItem(value: 'dispose', child: Text("Repair Failed (Dispose)"))],
                    onSelected: (val) => _confirmDispose(flag, 'stitching'),
                  ),
                ],
              )
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MyTextField(
                    hintText: "Qty Fixed",
                    obscureText: false,
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.thumb_up_alt_rounded,
                    onChanged: (value) {
                      int qty = int.tryParse(value) ?? 0;
                      if (qty > flag.quantity) qty = flag.quantity;
                      selectedStitchingQty[key] = qty;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                MyButton(
                  text: "Fix Done",
                  backgroundColor: Colors.purple.shade400,
                  onTap: isProcessing ? null : () => _handleReturnFromStitching(flag, key),
                  horizontalPadding: 20,
                  borderRadius: 14,
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDisposedCard(Flag flag) {
    return _cardContainer(
      color: Colors.red.withAlpha(5),
      borderColor: Colors.red.withAlpha(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _flagInfoBlock(flag, "Disposed: ${flag.quantity}", labelColor: Colors.red),
          if (flag.reason != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Text(flag.reason!, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            )
        ],
      ),
    );
  }

  Future<void> _handleMoveToStitching(Flag flag, String key) async {
  final qty = selectedStitchingQty[key] ?? 0;
  if (qty <= 0) { _showSnack("Enter valid quantity"); return; } // Added check
  setState(() => isProcessing = true);
  try {
    await siteService.moveActiveToStitching(
      siteId: widget.site.id,
      flags: [Flag(type: flag.type, size: flag.size, quantity: qty)],
      userEmail: FirebaseAuth.instance.currentUser?.email ?? "Unknown",
    );
    // ✅ Add these clean-up lines:
    selectedStitchingQty.remove(key);
    expandedItems.remove("${key}_stitch");
    _showSnack("Moved to stitching");
  } catch (e) { _showSnack(e.toString()); }
  setState(() => isProcessing = false);
}

Future<void> _handleReturnFromStitching(Flag flag, String key) async {
  final qty = selectedStitchingQty[key] ?? 0;
  if (qty <= 0) { _showSnack("Enter valid quantity"); return; } // Added check
  setState(() => isProcessing = true);
  try {
    await siteService.moveStitchingToActive(
      siteId: widget.site.id,
      flags: [Flag(type: flag.type, size: flag.size, quantity: qty)],
      userEmail: FirebaseAuth.instance.currentUser?.email ?? "Unknown",
    );
    // ✅ Add these clean-up lines:
    selectedStitchingQty.remove(key);
    expandedItems.remove(key);
    _showSnack("Repaired and returned to active");
  } catch (e) { _showSnack(e.toString()); }
  setState(() => isProcessing = false);
}

  Widget _buildSiteHistoryList(String siteName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .where(Filter.or(
            Filter('fromSite', isEqualTo: siteName),
            Filter('toSite', isEqualTo: siteName),
          ))
          .orderBy('timestamp', descending: true)
          .limit(15) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _emptyBox("Error loading history");
        if (!snapshot.hasData) return const Center(child: LinearProgressIndicator(color: primaryOrange));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _emptyBox("No transaction history yet");
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withAlpha(8)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.black.withAlpha(5), indent: 20, endIndent: 20),
            itemBuilder: (context, index) {
              final log = InventoryLog.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
              final dateStr = DateFormat('dd MMM, hh:mm a').format(log.timestamp);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(log.userEmail.split('@')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryOrange)),
                        Text(dateStr, style: const TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(log.autoDescription, style: const TextStyle(fontSize: 13, color: textDark, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Column(
        children: [
          MyTextField(
            hintText: "Search size (e.g. 10x10)",
            obscureText: false,
            prefixIcon: Icons.search_rounded,
            onChanged: (val) => setState(() => searchQuery = val),
            controller: TextEditingController()..text = searchQuery..selection = TextSelection.fromPosition(TextPosition(offset: searchQuery.length)),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["All", "Tiranga", "Bhagwa"].map((type) {
                final isSelected = selectedFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedFilter = type),
                    selectedColor: primaryOrange.withAlpha(40),
                    labelStyle: TextStyle(
                      color: isSelected ? primaryOrange : textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: bgColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: isSelected ? primaryOrange : Colors.transparent),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textMuted),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textMuted,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)),
      ),
      child: Center(
        child: Text(text, style: TextStyle(color: textMuted.withAlpha(128), fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _flagInfoBlock(Flag flag, String qtyLabel, {Color labelColor = primaryOrange}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(flag.type, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark)),
        Row(
          children: [
            Text("Size: ${flag.size}", style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Text("•", style: TextStyle(color: labelColor.withAlpha(100))),
            const SizedBox(width: 8),
            Text(qtyLabel, style: TextStyle(color: labelColor, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _cardContainer({required Widget child, Color? color, Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.black.withAlpha(8)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Future<void> _moveToWashing(Flag flag, String key) async {
    final qty = selectedActiveQty[key] ?? 0;
    if (qty <= 0) { _showSnack("Enter valid quantity"); return; }
    setState(() => isProcessing = true);
    try {
      await siteService.moveActiveToWashing(
        siteId: widget.site.id,
        flags: [Flag(type: flag.type, size: flag.size, quantity: qty)],
        userEmail: FirebaseAuth.instance.currentUser?.email ?? "Unknown", 
      );
      selectedActiveQty.remove(key);
      expandedItems.remove(key);
      _showSnack("Moved to washing");
    } catch (e) { _showSnack(e.toString()); }
    setState(() => isProcessing = false);
  }

  Future<void> _moveToActive(Flag flag, String key) async {
    final qty = selectedWashingQty[key] ?? 0;
    if (qty <= 0) { _showSnack("Enter valid quantity"); return; }
    setState(() => isProcessing = true);
    try {
      await siteService.moveWashingToActive(
        siteId: widget.site.id,
        flags: [Flag(type: flag.type, size: flag.size, quantity: qty)],
        userEmail: FirebaseAuth.instance.currentUser?.email ?? "Unknown", 
      );
      selectedWashingQty.remove(key);
      expandedItems.remove(key);
      _showSnack("Returned to active");
    } catch (e) { _showSnack(e.toString()); }
    setState(() => isProcessing = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}