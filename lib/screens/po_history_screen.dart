import 'package:flags_manager/screens/po_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../services/purchase_order_service.dart';
import 'add_po_screen.dart';

class POHistoryScreen extends StatefulWidget {
  const POHistoryScreen({super.key});

  @override
  State<POHistoryScreen> createState() => _POHistoryScreenState();
}

class _POHistoryScreenState extends State<POHistoryScreen> {
  final PurchaseOrderService _poService = PurchaseOrderService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search PO Number...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PurchaseOrder>>(
              stream: _poService.getPOs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final allPOs = snapshot.data ?? [];

                final displayedPOs = allPOs.where((po) {
                  return po.poNumber
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                }).toList();

                displayedPOs.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
                );

                if (displayedPOs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Purchase Orders Found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayedPOs.length,
                  itemBuilder: (context, index) {
                    return POListItem(po: displayedPOs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddPOScreen(),
          ),
        ),
        label: const Text('New PO'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class POListItem extends StatelessWidget {
  final PurchaseOrder po;

  const POListItem({
    super.key,
    required this.po,
  });

  @override
  Widget build(BuildContext context) {
    final totalQty =
        po.flags.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          po.poNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            '${DateFormat('dd MMM').format(po.createdAt)}  •  $totalQty Units',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PODetailsScreen(po: po),
          ),
        ),
      ),
    );
  }
}
