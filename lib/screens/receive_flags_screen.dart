import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/flag.dart';
import '../services/site_service.dart';

class ReceiveFlagsScreen extends StatefulWidget {
  const ReceiveFlagsScreen({super.key});

  @override
  State<ReceiveFlagsScreen> createState() =>
      _ReceiveFlagsScreenState();
}

class _ReceiveFlagsScreenState extends State<ReceiveFlagsScreen> {
  final SiteService siteService = SiteService();

  final Map<String, int> receiveQuantities = {};

  bool loading = false;

  String _key(String type, String size) => '$type|$size';

  Future<void> _submit(List<Flag> pendingFlags) async {
    final List<Flag> toReceive = [];

    for (var flag in pendingFlags) {
      final key = _key(flag.type, flag.size);
      final qty = receiveQuantities[key] ?? 0;

      if (qty > 0) {
        if (qty > flag.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot receive more than available for ${flag.type} ${flag.size}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        toReceive.add(
          Flag(type: flag.type, size: flag.size, quantity: qty),
        );
      }
    }

    if (toReceive.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one quantity'),
        ),
      );
      return;
    }

    try {
      setState(() => loading = true);

      await siteService
          .receiveFlagsFromPendingToOffice(toReceive);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flags received successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Flags'),
      ),
      body: StreamBuilder<List<Site>>(
        stream: siteService.getSites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final sites = snapshot.data!;
          final pendingSite = sites.firstWhere(
            (s) => s.name.toLowerCase() == 'pending',
            orElse: () => Site(
              id: 'pending',
              name: 'Pending',
              activeFlags: [],
              washingFlags: [],
            ),
          );

          if (pendingSite.activeFlags.isEmpty) {
            return const Center(
              child: Text('No pending flags'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount:
                        pendingSite.activeFlags.length,
                    itemBuilder: (context, index) {
                      final flag =
                          pendingSite.activeFlags[index];
                      final key =
                          _key(flag.type, flag.size);

                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${flag.type} - ${flag.size}',
                                style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Available: ${flag.quantity}'),
                              const SizedBox(height: 8),
                              TextField(
                                keyboardType:
                                    TextInputType.number,
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Receive Quantity',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  receiveQuantities[key] =
                                      int.tryParse(val) ??
                                          0;
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
                    onPressed: loading
                        ? null
                        : () => _submit(
                            pendingSite.activeFlags),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Confirm Receive'),
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
