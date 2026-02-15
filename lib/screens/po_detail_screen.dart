import 'package:flutter/material.dart';
import '../models/purchase_order.dart';

class PODetailsScreen extends StatelessWidget {
  final PurchaseOrder po;
  const PODetailsScreen({super.key, required this.po});

  @override
  Widget build(BuildContext context) {
    final totalQty = po.flags.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('PO: ${po.poNumber}'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Flags Ordered', 
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('$totalQty', 
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.inventory, color: Colors.white24, size: 48),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Order Items Breakdown', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: po.flags.length,
              itemBuilder: (context, index) {
                final flag = po.flags[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: flag.type == 'Tiranga' ? Colors.orange.shade50 : Colors.deepOrange.shade50,
                      child: Icon(Icons.flag, 
                          color: flag.type == 'Tiranga' ? Colors.orange : Colors.deepOrange),
                    ),
                    title: Text('${flag.type} - Size: ${flag.size}', 
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Status: Pending Production'),
                    trailing: Text('${flag.quantity}', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BulletSeparator extends StatelessWidget {
  const BulletSeparator({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 8.0),
    child: Text('•', style: TextStyle(color: Colors.grey)),
  );
}