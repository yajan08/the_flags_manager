import 'package:flutter/material.dart';
import '../models/purchase_order.dart';
import 'package:intl/intl.dart';

class PODetailsScreen extends StatelessWidget {
  final PurchaseOrder po;
  const PODetailsScreen({super.key, required this.po});

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
  static const Color bgColor = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    final pendingQty = po.pendingFlags.fold(0, (sum, f) => sum + f.quantity);
    final deliveredQty = po.deliveredFlags.fold(0, (sum, f) => sum + f.quantity);
    final createdDate = DateFormat('dd MMM yyyy, hh:mm a').format(po.createdAt);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          'PO Details',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PO HEADER INFO
            _buildHeaderInfo(createdDate),
            const SizedBox(height: 24),

            /// SUMMARY CARDS
            Row(
              children: [
                _buildSummaryStat(
                  "Pending",
                  pendingQty.toString(),
                  [const Color(0xFFFFA726), primaryOrange],
                ),
                const SizedBox(width: 16),
                _buildSummaryStat(
                  "Delivered",
                  deliveredQty.toString(),
                  [const Color(0xFF66BB6A), const Color(0xFF43A047)],
                ),
              ],
            ),
            const SizedBox(height: 32),

            /// PENDING FLAGS LIST
            _sectionHeader("Items to be Received", Icons.hourglass_bottom_rounded),
            _buildFlagList(po.pendingFlags, isPending: true),

            const SizedBox(height: 32),

            /// DELIVERED FLAGS LIST
            _sectionHeader("Delivered Items", Icons.verified_outlined),
            _buildFlagList(po.deliveredFlags, isPending: false),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)), // replaced 0.03
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tag_rounded, size: 18, color: primaryOrange),
              const SizedBox(width: 8),
              Text(
                po.poNumber,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline_rounded, "Created by", po.createdBy),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today_rounded, "Ordered on", date),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textMuted),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withAlpha(77), // replaced 0.3
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12, fontWeight: FontWeight.w600), // replaced 0.8
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
            ),
          ],
        ),
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

  Widget _buildFlagList(List flags, {required bool isPending}) {
    if (flags.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(128), // replaced 0.5
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withAlpha(5)), // replaced 0.02
        ),
        child: Center(
          child: Text(
            'No items in this category',
            style: TextStyle(color: textMuted.withAlpha(128), fontSize: 13, fontStyle: FontStyle.italic), // replaced 0.5
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flags.length,
      itemBuilder: (context, index) {
        final flag = flags[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(8)), // replaced 0.03
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPending ? primaryOrange.withAlpha(26) : Colors.green.withAlpha(26), // replaced 0.1
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_rounded,
                color: isPending ? primaryOrange : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              flag.type,
              style: const TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 15),
            ),
            subtitle: Text(
              "Size: ${flag.size}",
              style: const TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              '${flag.quantity}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textDark,
              ),
            ),
          ),
        );
      },
    );
  }
}