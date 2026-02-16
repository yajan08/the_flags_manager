// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for logging
import '../models/flag.dart';
import '../models/site.dart';
import '../services/site_service.dart';
import '../widgets/my_button.dart'; 
import '../widgets/my_text_field.dart'; 

class TransferFlagsScreen extends StatefulWidget {
  const TransferFlagsScreen({super.key});

  @override
  State<TransferFlagsScreen> createState() => _TransferFlagsScreenState();
}

class _TransferFlagsScreenState extends State<TransferFlagsScreen> {
  final SiteService _siteService = SiteService();

  String? _fromSiteId;
  String? _toSiteId;

  final Map<String, TextEditingController> _qtyControllers = {};
  bool _isLoading = false;

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  @override
  void dispose() {
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prepareControllers(List<Site> sites) {
    _qtyControllers.clear();
    if (_fromSiteId == null) return;
    final fromSite = sites.firstWhere((s) => s.id == _fromSiteId);
    for (var flag in fromSite.activeFlags) {
      final key = "${flag.type}_${flag.size}";
      _qtyControllers[key] = TextEditingController();
    }
  }

  Future<void> _transfer(List<Site> sites) async {
    if (_fromSiteId == null || _toSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select both source and destination sites")),
      );
      return;
    }

    if (_fromSiteId == _toSiteId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Source and Destination cannot be the same")),
      );
      return;
    }

    final fromSite = sites.firstWhere((s) => s.id == _fromSiteId);
    List<Flag> flagsToTransfer = [];

    for (var flag in fromSite.activeFlags) {
      final key = "${flag.type}_${flag.size}";
      final enteredQty = int.tryParse(_qtyControllers[key]?.text ?? "0") ?? 0;

      if (enteredQty > 0) {
        if (enteredQty > flag.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Quantity exceeds available for ${flag.type} ${flag.size}")),
          );
          return;
        }
        flagsToTransfer.add(Flag(type: flag.type, size: flag.size, quantity: enteredQty));
      }
    }

    if (flagsToTransfer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least one quantity to transfer")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ Logged-in user email added for history tracking
      final String userEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown User";

      await _siteService.transferFlags(
        fromSiteId: _fromSiteId!,
        toSiteId: _toSiteId!,
        flagsToTransfer: flagsToTransfer,
        userEmail: userEmail, // ✅ Passed to service for logging
        toWashing: false,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        title: const Text(
          "Move Inventory",
          style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<Site>>(
        stream: _siteService.getSites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryOrange));
          }

          final sites = snapshot.data!;
          final filteredSites = sites.where((s) => s.id != 'pending').toList();

          Site? fromSite;
          if (_fromSiteId != null) {
            fromSite = filteredSites.firstWhere((s) => s.id == _fromSiteId);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSiteSelectionBridge(filteredSites),
                    const SizedBox(height: 32),
                    if (fromSite != null) ...[
                      _buildSectionHeader("Select Items to Transfer", Icons.checklist_rtl_rounded),
                      if (fromSite.activeFlags.isEmpty)
                        _buildEmptyState()
                      else
                        ...fromSite.activeFlags.map((flag) => _buildTransferItemCard(flag)),
                    ] else 
                      _buildInstructionState(),
                  ],
                ),
              ),
              _buildBottomAction(filteredSites),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSiteSelectionBridge(List<Site> sites) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildDropdown(
            label: "FROM SOURCE",
            value: _fromSiteId,
            icon: Icons.outbox_rounded,
            sites: sites,
            onChanged: (val) {
              setState(() {
                _fromSiteId = val;
                _prepareControllers(sites);
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward_rounded, size: 16, color: primaryOrange),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
          _buildDropdown(
            label: "TO DESTINATION",
            value: _toSiteId,
            icon: Icons.move_to_inbox_rounded,
            sites: sites,
            onChanged: (val) => setState(() => _toSiteId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required List<Site> sites,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1)),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryOrange, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          hint: Text("Select Site", style: TextStyle(color: textMuted.withAlpha(128), fontSize: 14)),
          items: sites.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTransferItemCard(Flag flag) {
    final key = "${flag.type}_${flag.size}";
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(flag.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Size: ${flag.size}", style: const TextStyle(color: textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text("${flag.quantity} available", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryOrange)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 100,
            child: MyTextField(
              hintText: "0",
              obscureText: false,
              controller: _qtyControllers[key]!,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
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
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Text("No flags available at this site", style: TextStyle(color: textMuted.withAlpha(128))),
      ),
    );
  }

  Widget _buildInstructionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.touch_app_outlined, size: 40, color: textMuted.withAlpha(51)),
            const SizedBox(height: 16),
            Text("Select a source site to begin", style: TextStyle(color: textMuted.withAlpha(102), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(List<Site> sites) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: MyButton(
          text: _isLoading ? "Processing..." : "Confirm Transfer",
          onTap: _isLoading ? null : () => _transfer(sites),
          prefixIcon: _isLoading 
            ? const SizedBox(
                height: 20, 
                width: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              ) 
            : const Icon(Icons.check_circle_outline, color: Colors.white),
        ),
      ),
    );
  }
}