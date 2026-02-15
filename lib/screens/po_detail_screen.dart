import 'package:flutter/material.dart';
import '../models/purchase_order.dart';
import 'package:intl/intl.dart';

class PODetailsScreen extends StatelessWidget {
  final PurchaseOrder po;
  const PODetailsScreen({super.key, required this.po});

  static const Color primaryOrange = Color(0xFFFF6F00);

  @override
  Widget build(BuildContext context) {
    final pendingQty = po.pendingFlags.fold(0, (sum, f) => sum + f.quantity);
    final deliveredQty = po.deliveredFlags.fold(0, (sum, f) => sum + f.quantity);
    final createdDate = DateFormat('dd MMM yyyy, hh:mm a').format(po.createdAt);

    Widget buildFlagList(String title, List flags) {
      if (flags.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('No flags in this category', style: TextStyle(color: Colors.grey[600])),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: flags.length,
        itemBuilder: (context, index) {
          final flag = flags[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: flag.type == 'Tiranga'
                    ? Colors.orange.shade50
                    : Colors.deepOrange.shade50,
                child: Icon(
                  Icons.flag,
                  color: flag.type == 'Tiranga' ? Colors.orange : Colors.deepOrange,
                ),
              ),
              title: Text('${flag.type} - Size: ${flag.size}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text(
                '${flag.quantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        title: const Text('PO Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PO Number
            Text('PO Number', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(po.poNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            /// Created info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Created By: ${po.createdBy}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                Text(createdDate, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 24),

            /// Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFF6F00)]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Flags', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('$pendingQty', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Delivered Flags', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('$deliveredQty', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// Pending Flags List
            const Text('Pending Flags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            buildFlagList('Pending', po.pendingFlags),

            const SizedBox(height: 24),

            /// Delivered Flags List
            const Text('Delivered Flags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            buildFlagList('Delivered', po.deliveredFlags),
          ],
        ),
      ),
    );
  }
}
