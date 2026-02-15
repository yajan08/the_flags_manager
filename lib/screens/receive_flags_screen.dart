// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/flag.dart';
import '../models/purchase_order.dart';
import '../services/site_service.dart';
import '../services/purchase_order_service.dart';
import '../widgets/my_button.dart'; // ✅ Added
import '../widgets/my_text_field.dart'; // ✅ Added

class ReceiveFlagsScreen extends StatefulWidget {
  const ReceiveFlagsScreen({super.key});

  @override
  State<ReceiveFlagsScreen> createState() => _ReceiveFlagsScreenState();
}

class _ReceiveFlagsScreenState extends State<ReceiveFlagsScreen> {
  final SiteService siteService = SiteService();
  final PurchaseOrderService poService = PurchaseOrderService();

  final TextEditingController _poController = TextEditingController();
  final Map<String, int> receiveQuantities = {};

  bool loading = false;
  PurchaseOrder? selectedPO;
  Site? pendingSite;
  List<Flag> flagsToReceive = [];

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  String _key(String type, String size) => '$type|$size';

  Future<void> _fetchPO() async {
    final poNumber = _poController.text.trim();
    if (poNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PO number')),
      );
      return;
    }

    try {
      setState(() => loading = true);
      final po = await poService.getPOById(poNumber);
      if (po == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO not found')),
        );
        setState(() => loading = false);
        return;
      }

      final sites = await siteService.getSites().first;
      final pending = sites.firstWhere(
        (s) => s.name.toLowerCase() == 'pending',
        orElse: () => Site(id: 'pending', name: 'Pending', activeFlags: [], washingFlags: []),
      );

      List<Flag> filteredFlags = [];
      for (var poFlag in po.pendingFlags) {
        final pendingFlag = pending.activeFlags.firstWhere(
            (f) => f.type == poFlag.type && f.size == poFlag.size,
            orElse: () => Flag(type: poFlag.type, size: poFlag.size, quantity: 0));

        final maxReceivable = pendingFlag.quantity > 0
            ? (pendingFlag.quantity < poFlag.quantity ? pendingFlag.quantity : poFlag.quantity)
            : 0;

        if (maxReceivable > 0) {
          filteredFlags.add(
            Flag(type: poFlag.type, size: poFlag.size, quantity: maxReceivable),
          );
        }
      }

      if (filteredFlags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending flags available for this PO')),
        );
        setState(() => loading = false);
        return;
      }

      setState(() {
        selectedPO = po;
        pendingSite = pending;
        flagsToReceive = filteredFlags;
        receiveQuantities.clear();
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching PO: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submit() async {
    Navigator.pop(context);
    if (flagsToReceive.isEmpty || selectedPO == null || pendingSite == null) return;

    final List<Flag> toReceive = [];

    for (var flag in flagsToReceive) {
      final key = _key(flag.type, flag.size);
      final qty = receiveQuantities[key] ?? 0;

      if (qty > 0) {
        if (qty > flag.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot receive more than allowed for ${flag.type} ${flag.size}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        toReceive.add(Flag(type: flag.type, size: flag.size, quantity: qty));
      }
    }

    if (toReceive.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one quantity')),
      );
      return;
    }

    try {
      setState(() => loading = true);
      await siteService.receiveFlagsFromPendingToOffice(toReceive);

      for (var rFlag in toReceive) {
        final pendingFlag = selectedPO!.pendingFlags.firstWhere(
            (f) => f.type == rFlag.type && f.size == rFlag.size,
            orElse: () => Flag(type: rFlag.type, size: rFlag.size, quantity: 0));
        pendingFlag.quantity -= rFlag.quantity;

        final deliveredFlagIndex = selectedPO!.deliveredFlags.indexWhere(
            (f) => f.type == rFlag.type && f.size == rFlag.size);
        if (deliveredFlagIndex >= 0) {
          selectedPO!.deliveredFlags[deliveredFlagIndex].quantity += rFlag.quantity;
        } else {
          selectedPO!.deliveredFlags.add(Flag(
            type: rFlag.type,
            size: rFlag.size,
            quantity: rFlag.quantity,
          ));
        }
      }

      selectedPO!.pendingFlags.removeWhere((f) => f.quantity <= 0);
      await poService.updatePO(selectedPO!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flags received successfully'), backgroundColor: Colors.green),
      );

      setState(() {
        selectedPO = null;
        pendingSite = null;
        flagsToReceive.clear();
        _poController.clear();
        receiveQuantities.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
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
          'Receive Inventory',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: selectedPO == null ? _buildPOSearchView() : _buildReceiveItemsView(),
      ),
    );
  }

  Widget _buildPOSearchView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))
            ]),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: primaryOrange),
                const SizedBox(height: 16),
                const Text("Purchase Order Check-in", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: textDark)),
                const SizedBox(height: 8),
                const Text("Enter the PO number to verify and receive pending flags into office stock.",
                    textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 14)),
                const SizedBox(height: 12),
                MyTextField(
                  controller: _poController,
                  hintText: 'PO Number',
                  obscureText: false,
                  prefixIcon: Icons.tag_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MyButton(
            text: loading ? "Fetching..." : "Fetch Details",
            onTap: loading ? null : _fetchPO,
            prefixIcon: loading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.search_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveItemsView() {
    return Column(
      children: [
        _buildPOHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            itemCount: flagsToReceive.length,
            itemBuilder: (context, index) {
              final flag = flagsToReceive[index];
              final key = _key(flag.type, flag.size);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(flag.type, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark)),
                              Text(flag.size, style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: primaryOrange.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                            child: Text('Max: ${flag.quantity}',
                                style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MyTextField(
                        hintText: 'Quantity to receive',
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final input = int.tryParse(val) ?? 0;
                          receiveQuantities[key] = input > flag.quantity ? flag.quantity : input;
                        },
                        controller: TextEditingController(), 
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomAction(),
      ],
    );
  }

  Widget _buildPOHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [textDark, Color(0xFF434343)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.description_outlined, color: Colors.white)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PO #${selectedPO?.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const Text('Processing delivery to Office', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => selectedPO = null),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
      ),
      child: SafeArea(
        child: MyButton(
          text: loading ? "Updating PO..." : "Confirm Receipt",
          onTap: loading ? null : _submit,
          prefixIcon: loading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.done_all_rounded, color: Colors.white),
        ),
      ),
    );
  }
}