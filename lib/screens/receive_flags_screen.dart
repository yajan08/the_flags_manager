// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/flag.dart';
import '../models/purchase_order.dart';
import '../services/site_service.dart';
import '../services/purchase_order_service.dart';

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

  String _key(String type, String size) => '$type|$size';

  /// Step 1: Fetch PO and filter only flags that exist in PO pendingFlags & pending site
  Future<void> _fetchPO() async {
    final poNumber = _poController.text.trim();
    if (poNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PO number')),
      );
      return;
    }

    try {
      final po = await poService.getPOById(poNumber);
      if (po == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO not found')),
        );
        return;
      }

      // Get pending site
      final sites = await siteService.getSites().first;
      final pending = sites.firstWhere(
        (s) => s.name.toLowerCase() == 'pending',
        orElse: () =>
            Site(id: 'pending', name: 'Pending', activeFlags: [], washingFlags: []),
      );

      // Only include flags that exist in both PO pendingFlags and pending site
      List<Flag> filteredFlags = [];
      for (var poFlag in po.pendingFlags) {
        final pendingFlag = pending.activeFlags.firstWhere(
            (f) => f.type == poFlag.type && f.size == poFlag.size,
            orElse: () => Flag(type: poFlag.type, size: poFlag.size, quantity: 0));

        // Max receivable is min(PO pendingFlags qty, pending site qty)
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
        return;
      }

      setState(() {
        selectedPO = po;
        pendingSite = pending;
        flagsToReceive = filteredFlags;
        receiveQuantities.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching PO: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Step 2: Submit received quantities
  Future<void> _submit() async {
    if (flagsToReceive.isEmpty || selectedPO == null || pendingSite == null) return;

    final List<Flag> toReceive = [];

    for (var flag in flagsToReceive) {
      final key = _key(flag.type, flag.size);
      final qty = receiveQuantities[key] ?? 0;

      if (qty > 0) {
        if (qty > flag.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Cannot receive more than allowed for ${flag.type} ${flag.size}'),
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

      // 1️⃣ Move flags in Site from Pending → Office
      await siteService.receiveFlagsFromPendingToOffice(toReceive);

      // 2️⃣ Update PO: move from pendingFlags → deliveredFlags
      for (var rFlag in toReceive) {
        // Reduce qty from pendingFlags
        final pendingFlag = selectedPO!.pendingFlags.firstWhere(
            (f) => f.type == rFlag.type && f.size == rFlag.size,
            orElse: () => Flag(type: rFlag.type, size: rFlag.size, quantity: 0));
        pendingFlag.quantity -= rFlag.quantity;

        // Add or update deliveredFlags
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

      // Remove any pendingFlags with qty 0
      selectedPO!.pendingFlags.removeWhere((f) => f.quantity <= 0);

      // Update PO in Firestore
      await poService.updatePO(selectedPO!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flags received successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear state
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
      appBar: AppBar(title: const Text('Receive Flags by PO')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: selectedPO == null
            ? Column(
                children: [
                  TextField(
                    controller: _poController,
                    decoration: const InputDecoration(
                      labelText: 'Enter PO Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _fetchPO,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Fetch PO'),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: flagsToReceive.length,
                      itemBuilder: (context, index) {
                        final flag = flagsToReceive[index];
                        final key = _key(flag.type, flag.size);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${flag.type} - ${flag.size}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Max Receivable: ${flag.quantity}'),
                                const SizedBox(height: 8),
                                TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Receive Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    final input = int.tryParse(val) ?? 0;
                                    receiveQuantities[key] =
                                        input > flag.quantity ? flag.quantity : input;
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm Receive'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
