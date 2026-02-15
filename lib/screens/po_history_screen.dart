import 'package:flags_manager/screens/po_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../services/purchase_order_service.dart';
import '../widgets/my_text_field.dart'; // ✅ Integrated
import '../widgets/my_button.dart';     // ✅ Integrated
import 'add_po_screen.dart';

class POHistoryScreen extends StatefulWidget {
  const POHistoryScreen({super.key});

  @override
  State<POHistoryScreen> createState() => _POHistoryScreenState();
}

class _POHistoryScreenState extends State<POHistoryScreen> {
  final PurchaseOrderService _poService = PurchaseOrderService();
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textDark,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
      ),
      body: Column(
        children: [
          // --- SEARCH SECTION ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: MyTextField(
              controller: _searchController,
              hintText: 'Search PO Number...',
              obscureText: false,
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // --- PO LIST SECTION ---
          Expanded(
            child: StreamBuilder<List<PurchaseOrder>>(
              stream: _poService.getPOs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', 
                    style: const TextStyle(color: Colors.red)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryOrange),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_rounded, size: 64, color: textMuted.withAlpha(51)), // replaced 0.2
                        const SizedBox(height: 16),
                        const Text(
                          "No Purchase Orders Found",
                          style: TextStyle(color: textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  physics: const BouncingScrollPhysics(),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: MyButton(
          text: "Create New PO",
          verticalPadding: 14,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPOScreen()),
          ),
          prefixIcon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
    const Color primaryOrange = Color(0xFFFF6F00);
    const Color textDark = Color(0xFF2D3436);
    const Color textMuted = Color(0xFF636E72);

    final totalQty = po.pendingFlags.fold(0, (sum, f) => sum + f.quantity) +
        po.deliveredFlags.fold(0, (sum, f) => sum + f.quantity);
    
    final bool isFullyDelivered = po.pendingFlags.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)), // replaced 0.03
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5), // replaced 0.02
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PODetailsScreen(po: po),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFullyDelivered 
                        ? Colors.green.withAlpha(26) // replaced 0.1
                        : primaryOrange.withAlpha(26), // replaced 0.1
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFullyDelivered ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                    color: isFullyDelivered ? Colors.green : primaryOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        po.poNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMMM yyyy').format(po.createdAt),
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Units Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalQty',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: textDark,
                      ),
                    ),
                    const Text(
                      'UNITS',
                      style: TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}