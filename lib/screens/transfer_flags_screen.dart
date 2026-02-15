// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/flag.dart';
import '../models/site.dart';
import '../services/site_service.dart';

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

    final fromSite =
        sites.firstWhere((s) => s.id == _fromSiteId);

    for (var flag in fromSite.activeFlags) {
      final key = "${flag.type}_${flag.size}";
      _qtyControllers[key] = TextEditingController();
    }
  }

  Future<void> _transfer(List<Site> sites) async {
    if (_fromSiteId == null || _toSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select both sites")),
      );
      return;
    }

    if (_fromSiteId == _toSiteId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot transfer to same site")),
      );
      return;
    }

    final fromSite =
        sites.firstWhere((s) => s.id == _fromSiteId);

    List<Flag> flagsToTransfer = [];

    for (var flag in fromSite.activeFlags) {
      final key = "${flag.type}_${flag.size}";
      final enteredQty =
          int.tryParse(_qtyControllers[key]?.text ?? "0") ?? 0;

      if (enteredQty > 0) {
        if (enteredQty > flag.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Quantity exceeds available for ${flag.type} ${flag.size}",
              ),
            ),
          );
          return;
        }

        flagsToTransfer.add(
          Flag(
            type: flag.type,
            size: flag.size,
            quantity: enteredQty,
          ),
        );
      }
    }

    if (flagsToTransfer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter quantity to transfer")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _siteService.transferFlags(
        fromSiteId: _fromSiteId!,
        toSiteId: _toSiteId!,
        flagsToTransfer: flagsToTransfer,
        toWashing: false,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfer Flags"),
      ),
      body: StreamBuilder<List<Site>>(
        stream: _siteService.getSites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sites = snapshot.data!;
          final filteredSites =
              sites.where((s) => s.id != 'pending').toList();

          Site? fromSite;
          if (_fromSiteId != null) {
            fromSite = filteredSites
                .firstWhere((s) => s.id == _fromSiteId);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// FROM DROPDOWN
                DropdownButtonFormField<String>(
                  initialValue: _fromSiteId,
                  hint: const Text("Select From Site"),
                  items: filteredSites
                      .map(
                        (site) => DropdownMenuItem(
                          value: site.id,
                          child: Text(site.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _fromSiteId = value;
                      _prepareControllers(filteredSites);
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// TO DROPDOWN
                DropdownButtonFormField<String>(
                  initialValue: _toSiteId,
                  hint: const Text("Select To Site"),
                  items: filteredSites
                      .map(
                        (site) => DropdownMenuItem(
                          value: site.id,
                          child: Text(site.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _toSiteId = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                /// FLAGS LIST
                if (fromSite != null)
                  Expanded(
                    child: fromSite.activeFlags.isEmpty
                        ? const Center(
                            child: Text("No flags available"),
                          )
                        : ListView.builder(
                            itemCount:
                                fromSite.activeFlags.length,
                            itemBuilder: (context, index) {
                              final flag =
                                  fromSite!.activeFlags[index];
                              final key =
                                  "${flag.type}_${flag.size}";

                              return Card(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(flag.type),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(flag.size),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "Available: ${flag.quantity}",
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 70,
                                        child: TextField(
                                          controller:
                                              _qtyControllers[key],
                                          keyboardType:
                                              TextInputType
                                                  .number,
                                          decoration:
                                              const InputDecoration(
                                            hintText: "Qty",
                                            border:
                                                OutlineInputBorder(),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _transfer(filteredSites),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text("Transfer"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
