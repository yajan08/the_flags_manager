// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_order.dart';
import '../models/flag.dart';
import '../services/purchase_order_service.dart';
import '../services/site_service.dart';
import '../widgets/my_button.dart';      // ✅ Integrated
import '../widgets/my_text_field.dart'; // ✅ Integrated
import 'package:posthog_flutter/posthog_flutter.dart';

class AddPOScreen extends StatefulWidget {
  const AddPOScreen({super.key});

  @override
  State<AddPOScreen> createState() => _AddPOScreenState();
}

class _AddPOScreenState extends State<AddPOScreen> {
  final _formKey = GlobalKey<FormState>();
  final _poNumberController = TextEditingController();
  final PurchaseOrderService poService = PurchaseOrderService();
  final SiteService siteService = SiteService();

  List<FlagEntry> flagEntries = [];
  bool _isSaving = false;

  static const Color primaryOrange = Color(0xFFFF6F00);
  static const Color bgColor = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);

  // Pre-defined common sizes
  final List<String> commonSizes = ['10x15', '16x24', '20x30', '24x36'];

  @override
  void dispose() {
    _poNumberController.dispose();
    super.dispose();
  }

  int get _totalQuantity => flagEntries.fold(0, (sum, e) => sum + e.quantity);

  Future<void> _savePO() async {
    if (!_formKey.currentState!.validate()) return;

    if (flagEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one flag batch')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final poNumber = _poNumberController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? 'Unknown User';

    try {
      final existing = await poService.getPOById(poNumber);
      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO number already exists'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }

      final po = PurchaseOrder(
        id: poNumber,
        poNumber: poNumber,
        pendingFlags: flagEntries.map((e) => e.toFlag()).toList(),
        deliveredFlags: [],
        createdBy: userEmail,
        createdAt: DateTime.now(),
      );

      await poService.addPO(po);

      await siteService.addFlagsToSite(
        siteId: 'pending',
        siteName: 'Pending',
        flags: po.pendingFlags,
        userEmail: userEmail,
      );

      Posthog().capture(
        eventName: 'po_created',
        properties: {
          'po_number': poNumber,
          'total_items': _totalQuantity,
          'batch_count': flagEntries.length,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PO saved successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving PO: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddBatchModal() {
    Posthog().screen(screenName: 'AddBatchModal');
    
    final typeController = TextEditingController(text: 'Tiranga');
    final sizeController = TextEditingController();
    final quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder( // Added to handle chip selection state inside modal
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Flag Batch',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: typeController.text,
                          decoration: const InputDecoration(border: InputBorder.none, labelText: "Flag Type"),
                          items: ['Tiranga', 'Bhagwa']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold))))
                              .toList(),
                          onChanged: (val) { if (val != null) typeController.text = val; },
                        ),
                      ),
                    ),
                
                    const SizedBox(height: 16),
                    const Text(
                      "Common Sizes",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: commonSizes.map((size) {
                        final bool isSelected = sizeController.text == size;
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          selectedColor: primaryOrange.withAlpha(50),
                          labelStyle: TextStyle(
                            color: isSelected ? primaryOrange : textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              sizeController.text = selected ? size : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                
                    MyTextField(
                      controller: sizeController,
                      hintText: 'Size (e.g., 10x6)',
                      obscureText: false,
                      prefixIcon: Icons.straighten_rounded,
                      onChanged: (val) {
                        // Update modal state to refresh chips if user types manually
                        setModalState(() {});
                      },
                    ),
                
                    MyTextField(
                      controller: quantityController,
                      hintText: 'Quantity',
                      obscureText: false,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.numbers_rounded,
                    ),
                
                    const SizedBox(height: 24),
                    MyButton(
                      text: 'Add to Order',
                      verticalPadding: 16,
                      onTap: () {
                        final type = typeController.text.trim();
                        final size = sizeController.text.trim();
                        final qty = int.tryParse(quantityController.text.trim()) ?? 0;
                
                        if (type.isEmpty || size.isEmpty || qty <= 0) return;
                
                        setState(() {
                          final existingIndex = flagEntries.indexWhere((e) => e.type == type && e.size == size);
                          if (existingIndex >= 0) {
                            flagEntries[existingIndex].quantity += qty;
                          } else {
                            flagEntries.add(FlagEntry(type: type, size: size, quantity: qty));
                          }
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
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
        title: const Text(
          'New Purchase Order',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: primaryOrange, size: 28),
              onPressed: _savePO,
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: MyTextField(
                controller: _poNumberController,
                hintText: 'Enter PO Number',
                obscureText: false,
                prefixIcon: Icons.tag_rounded,
              ),
            ),
            Expanded(
              child: flagEntries.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: flagEntries.length,
                      itemBuilder: (context, index) {
                        final entry = flagEntries[index];
                        return _buildBatchCard(entry, index);
                      },
                    ),
            ),
            _buildBottomSummaryBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add_outlined, size: 64, color: textMuted.withAlpha(51)),
          const SizedBox(height: 16),
          Text("No items added yet", style: TextStyle(color: textMuted.withAlpha(128), fontWeight: FontWeight.w600)),
          TextButton(onPressed: _showAddBatchModal, child: const Text("Add first batch", style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBatchCard(FlagEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryOrange.withAlpha(26),
          child: const Icon(Icons.flag_rounded, color: primaryOrange, size: 20),
        ),
        title: Text(entry.type, style: const TextStyle(fontWeight: FontWeight.w800, color: textDark)),
        subtitle: Text("Size: ${entry.size}", style: const TextStyle(fontWeight: FontWeight.w500, color: textMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(entry.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => setState(() => flagEntries.removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORDER TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1)),
                  Text('$_totalQuantity Items', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            MyButton(
              text: 'Add Batch',
              verticalPadding: 14,
              horizontalPadding: 20,
              onTap: _showAddBatchModal,
              prefixIcon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class FlagEntry {
  final String uid = DateTime.now().microsecondsSinceEpoch.toString();
  String type;
  String size;
  int quantity;

  FlagEntry({this.type = 'Tiranga', this.size = '', this.quantity = 0});
  Flag toFlag() => Flag(type: type, size: size, quantity: quantity);
}