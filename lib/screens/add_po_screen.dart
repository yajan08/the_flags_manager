import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/purchase_order.dart';
import '../models/flag.dart';
import '../services/purchase_order_service.dart';
import '../services/site_service.dart';

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

  @override
  void dispose() {
    _poNumberController.dispose();
    super.dispose();
  }

  int get _totalQuantity =>
      flagEntries.fold(0, (sum, e) => sum + e.quantity);

  Future<void> _savePO() async {
  if (!_formKey.currentState!.validate()) return;

  if (flagEntries.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please add at least one flag batch')),
    );
    return;
  }

  final poNumber = _poNumberController.text.trim();
  final user = FirebaseAuth.instance.currentUser;

  try {
    // Prevent overwrite
    final existing = await poService.getPOById(poNumber);
    if (existing != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PO number already exists'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🔹 Create PO with pendingFlags = all flags, deliveredFlags = empty
    final po = PurchaseOrder(
      id: poNumber,
      poNumber: poNumber,
      pendingFlags: flagEntries.map((e) => e.toFlag()).toList(),
      deliveredFlags: [],
      createdBy: user?.email ?? 'Unknown',
      createdAt: DateTime.now(),
    );

    await poService.addPO(po);

    // 🔹 Add all flags to Pending site
    await siteService.addFlagsToSite(
      siteId: 'pending',
      siteName: 'Pending',
      flags: po.pendingFlags,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PO saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving PO: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  void _showAddBatchModal() {
    final typeController = TextEditingController(text: 'Tiranga');
    final sizeController = TextEditingController();
    final quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Flag Batch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: typeController.text,
                decoration: const InputDecoration(
                  labelText: 'Flag Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Tiranga', 'Bhagwa']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    typeController.text = val;
                  }
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size (e.g., 10x6)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final type = typeController.text.trim();
                    final size = sizeController.text.trim();
                    final qty =
                        int.tryParse(quantityController.text.trim()) ?? 0;

                    if (type.isEmpty || size.isEmpty || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields correctly'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      // Merge duplicate batches
                      final existingIndex =
                          flagEntries.indexWhere((e) => e.type == type && e.size == size);

                      if (existingIndex >= 0) {
                        flagEntries[existingIndex].quantity += qty;
                      } else {
                        flagEntries.add(
                          FlagEntry(type: type, size: size, quantity: qty),
                        );
                      }
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Add Batch'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Order'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _savePO,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _poNumberController,
                decoration: const InputDecoration(
                  labelText: 'PO Number',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
            ),

            Expanded(
              child: flagEntries.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _showAddBatchModal,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Flag Batch'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: flagEntries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = flagEntries[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text('${entry.type} - ${entry.size}'),
                            subtitle: Text('Qty: ${entry.quantity}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => setState(() => flagEntries.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Quantity',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '$_totalQuantity Items',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddBatchModal,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Batch'),
                    ),
                  ],
                ),
              ),
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

  FlagEntry({
    this.type = 'Tiranga',
    this.size = '',
    this.quantity = 0,
  });

  Flag toFlag() => Flag(type: type, size: size, quantity: quantity);
}
