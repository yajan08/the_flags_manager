import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/flag.dart';
import '../services/site_service.dart';

class SiteDetailsScreen extends StatefulWidget {
  final Site site;

  const SiteDetailsScreen({super.key, required this.site});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  final SiteService siteService = SiteService();

  final Map<String, int> selectedActiveQty = {};
  final Map<String, int> selectedWashingQty = {};

  bool isProcessing = false;

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF6F6F6);

  @override
  void initState() {
    super.initState();
    _ensureDefaultSites();
  }

  Future<void> _ensureDefaultSites() async {
    try {
      await siteService.ensureDefaultSitesExist();
    } catch (e) {
      debugPrint("Error ensuring default sites: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryOrange,
        title: Text(widget.site.name),
      ),
      body: StreamBuilder<List<Site>>(
        stream: siteService.getSites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use firstWhere with orElse to avoid crashes
          final updatedSite = snapshot.data!.firstWhere(
            (s) => s.id == widget.site.id,
            orElse: () => snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : Site(id: 'pending', name: 'Pending', activeFlags: [], washingFlags: []),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              /// ================= ACTIVE SECTION =================
              _sectionTitle("Active Flags"),
              const SizedBox(height: 12),

              if (updatedSite.activeFlags.isEmpty)
                _emptyBox("No active flags")
              else
                ...updatedSite.activeFlags.map(
                  (flag) => _buildActiveCard(flag),
                ),

              const SizedBox(height: 30),

              /// ================= WASHING SECTION =================
              _sectionTitle("Washing Flags"),
              const SizedBox(height: 12),

              if (updatedSite.washingFlags.isEmpty)
                _emptyBox("No washing flags")
              else
                ...updatedSite.washingFlags.map(
                  (flag) => _buildWashingCard(flag),
                ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // UI COMPONENTS
  // ==========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  // ==========================================================
  // ACTIVE CARD
  // ==========================================================

  Widget _buildActiveCard(Flag flag) {
    final key = "${flag.type}_${flag.size}";
    final selectedQty = selectedActiveQty[key] ?? 0;

    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _flagTitle(flag),
          const SizedBox(height: 8),
          Text("Available: ${flag.quantity}"),
          const SizedBox(height: 12),

          _quantityRow(
            initialValue: selectedQty,
            max: flag.quantity,
            onChanged: (qty) {
              selectedActiveQty[key] = qty;
            },
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
              ),
              onPressed: isProcessing
                  ? null
                  : () => _moveToWashing(flag, key),
              icon: const Icon(Icons.local_laundry_service),
              label: const Text("Send to Washing"),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WASHING CARD
  // ==========================================================

  Widget _buildWashingCard(Flag flag) {
    final key = "${flag.type}_${flag.size}";
    final selectedQty = selectedWashingQty[key] ?? 0;

    return _cardContainer(
      color: Colors.orange.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _flagTitle(flag),
          const SizedBox(height: 8),
          Text("In Washing: ${flag.quantity}"),
          const SizedBox(height: 12),

          _quantityRow(
            initialValue: selectedQty,
            max: flag.quantity,
            onChanged: (qty) {
              selectedWashingQty[key] = qty;
            },
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: isProcessing
                  ? null
                  : () => _moveToActive(flag, key),
              icon: const Icon(Icons.undo),
              label: const Text("Return to Active"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flagTitle(Flag flag) {
    return Text(
      "${flag.type} (${flag.size})",
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }

  Widget _quantityRow({
    required int initialValue,
    required int max,
    required Function(int) onChanged,
  }) {
    return Row(
      children: [
        const Text("Qty: "),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue:
                initialValue == 0 ? '' : initialValue.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "0",
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              int qty = int.tryParse(value) ?? 0;

              if (qty < 0) qty = 0;
              if (qty > max) qty = max;

              onChanged(qty);
            },
          ),
        ),
      ],
    );
  }

  Widget _cardContainer({
    required Widget child,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Future<void> _moveToWashing(Flag flag, String key) async {
    final qty = selectedActiveQty[key] ?? 0;

    if (qty <= 0) {
      _showSnack("Enter valid quantity");
      return;
    }

    setState(() => isProcessing = true);

    try {
      await siteService.moveActiveToWashing(
        siteId: widget.site.id,
        flags: [
          Flag(
            type: flag.type,
            size: flag.size,
            quantity: qty,
          )
        ],
      );

      selectedActiveQty.remove(key);
      _showSnack("Moved to washing");
    } catch (e) {
      _showSnack(e.toString());
    }

    setState(() => isProcessing = false);
  }

  Future<void> _moveToActive(Flag flag, String key) async {
    final qty = selectedWashingQty[key] ?? 0;

    if (qty <= 0) {
      _showSnack("Enter valid quantity");
      return;
    }

    setState(() => isProcessing = true);

    try {
      await siteService.moveWashingToActive(
        siteId: widget.site.id,
        flags: [
          Flag(
            type: flag.type,
            size: flag.size,
            quantity: qty,
          )
        ],
      );

      selectedWashingQty.remove(key);
      _showSnack("Returned to active");
    } catch (e) {
      _showSnack(e.toString());
    }

    setState(() => isProcessing = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryOrange,
        content: Text(message),
      ),
    );
  }
}
