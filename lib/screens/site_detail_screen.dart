import 'package:flutter/material.dart';
import '../models/site.dart';
import '../models/flag.dart';
import '../services/site_service.dart';
import '../widgets/my_button.dart'; // ✅ Added
import '../widgets/my_text_field.dart'; // ✅ Added

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
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

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
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          widget.site.name,
          style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<Site>>(
        stream: siteService.getSites(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryOrange));
          }

          final updatedSite = snapshot.data!.firstWhere(
            (s) => s.id == widget.site.id,
            orElse: () => snapshot.data!.isNotEmpty
                ? snapshot.data!.first
                : Site(id: 'pending', name: 'Pending', activeFlags: [], washingFlags: []),
          );

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              /// ================= ACTIVE SECTION =================
              _sectionHeader("Active Inventory", Icons.check_circle_outline_rounded),
              if (updatedSite.activeFlags.isEmpty)
                _emptyBox("No flags in active stock")
              else
                ...updatedSite.activeFlags.map((flag) => _buildActiveCard(flag)),

              const SizedBox(height: 32),

              /// ================= WASHING SECTION =================
              _sectionHeader("Washing Queue", Icons.local_laundry_service_outlined),
              if (updatedSite.washingFlags.isEmpty)
                _emptyBox("No flags currently in washing")
              else
                ...updatedSite.washingFlags.map((flag) => _buildWashingCard(flag)),

              const SizedBox(height: 40),
            ],
          );
        },
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

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(8)), // 0.03 * 255
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: textMuted.withAlpha(128), fontStyle: FontStyle.italic), // 0.5 * 255
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIVE CARD
  // ==========================================================

  Widget _buildActiveCard(Flag flag) {
    final key = "${flag.type}_${flag.size}";
    final controller = TextEditingController(
      text: (selectedActiveQty[key] ?? 0) == 0 ? '' : selectedActiveQty[key].toString()
    );

    return _cardContainer(
      borderColor: primaryOrange.withAlpha(26), // 0.1 * 255
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _flagHeader(flag, "Available: ${flag.quantity}"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MyTextField(
                  hintText: "Qty to Wash",
                  obscureText: false,
                  controller: controller,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.edit_note_rounded,
                  onChanged: (value) {
                    int qty = int.tryParse(value) ?? 0;
                    if (qty > flag.quantity) qty = flag.quantity;
                    selectedActiveQty[key] = qty;
                  },
                ),
              ),
              const SizedBox(width: 12),
              MyButton(
                text: "Send",
                onTap: isProcessing ? null : () => _moveToWashing(flag, key),
                horizontalPadding: 20,
                borderRadius: 14,
              ),
            ],
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
    final controller = TextEditingController(
      text: (selectedWashingQty[key] ?? 0) == 0 ? '' : selectedWashingQty[key].toString()
    );

    return _cardContainer(
      color: const Color(0xFFF1F4F8), // Soft washing blue-grey
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _flagHeader(flag, "In Washing: ${flag.quantity}", labelColor: Colors.blueGrey),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MyTextField(
                  hintText: "Qty to Return",
                  obscureText: false,
                  controller: controller,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.restore_rounded,
                  onChanged: (value) {
                    int qty = int.tryParse(value) ?? 0;
                    if (qty > flag.quantity) qty = flag.quantity;
                    selectedWashingQty[key] = qty;
                  },
                ),
              ),
              const SizedBox(width: 12),
              MyButton(
                text: "Return",
                backgroundColor: Colors.green.shade600,
                onTap: isProcessing ? null : () => _moveToActive(flag, key),
                horizontalPadding: 20,
                borderRadius: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flagHeader(Flag flag, String qtyLabel, {Color labelColor = primaryOrange}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(flag.type, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark)),
            Text("Size: ${flag.size}", style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(qtyLabel, style: TextStyle(color: labelColor, fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }

  Widget _cardContainer({required Widget child, Color? color, Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor ?? Colors.black.withAlpha(8)), // 0.03 * 255
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5), // 0.02 * 255
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ==========================================================
  // ACTIONS (Logics untouched as requested)
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
        flags: [Flag(type: flag.type, size: flag.size, quantity: qty)],
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
        flags: [Flag(type: flag.type, size: flag.size, quantity: qty)],
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
        backgroundColor: textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}