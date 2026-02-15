import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_order.dart';
import '../models/flag.dart';

class PurchaseOrderService {
  final CollectionReference _poCollection =
      FirebaseFirestore.instance.collection('purchaseOrders');

  // Add a new PO (all flags go to pending by default)
  Future<void> addPO(PurchaseOrder po) async {
    await _poCollection.doc(po.id).set({
      'poNumber': po.poNumber,
      'pendingFlags': po.pendingFlags.map((f) => f.toMap()).toList(),
      'deliveredFlags': po.deliveredFlags.map((f) => f.toMap()).toList(),
      'createdBy': po.createdBy,
      'createdAt': po.createdAt.toIso8601String(),
    });
  }

  // Get all POs
  Stream<List<PurchaseOrder>> getPOs() {
    return _poCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => PurchaseOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // Get PO by ID
  Future<PurchaseOrder?> getPOById(String id) async {
    final doc = await _poCollection.doc(id).get();
    if (doc.exists) {
      return PurchaseOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Update PO
  Future<void> updatePO(PurchaseOrder po) async {
    await _poCollection.doc(po.id).update(po.toMap());
  }

  // Delete PO
  Future<void> deletePO(String id) async {
    await _poCollection.doc(id).delete();
  }

  // ==========================================================
  // MARK FLAGS AS RECEIVED: Move from pending -> delivered
  // ==========================================================
  Future<void> receiveFlags(
      String poId, List<Flag> receivedFlags) async {
    final poRef = _poCollection.doc(poId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(poRef);
      if (!snapshot.exists) throw Exception("PO not found");

      final po = PurchaseOrder.fromMap(
          snapshot.id, snapshot.data() as Map<String, dynamic>);

      List<Flag> updatedPending = List.from(po.pendingFlags);
      List<Flag> updatedDelivered = List.from(po.deliveredFlags);

      for (var flag in receivedFlags) {
        // Find in pending
        int index = updatedPending.indexWhere(
            (f) => f.type == flag.type && f.size == flag.size);
        if (index == -1) {
          throw Exception('Flag ${flag.type} ${flag.size} not found in pending for this PO.');
        }

        int available = updatedPending[index].quantity;
        if (flag.quantity > available) {
          throw Exception(
              'Cannot receive more than pending quantity for ${flag.type} ${flag.size}');
        }

        // Subtract from pending
        updatedPending[index].quantity = available - flag.quantity;
        if (updatedPending[index].quantity <= 0) {
          updatedPending.removeAt(index);
        }

        // Add to delivered
        int deliveredIndex = updatedDelivered.indexWhere(
            (f) => f.type == flag.type && f.size == flag.size);
        if (deliveredIndex >= 0) {
          updatedDelivered[deliveredIndex].quantity += flag.quantity;
        } else {
          updatedDelivered.add(Flag(
              type: flag.type, size: flag.size, quantity: flag.quantity));
        }
      }

      transaction.update(poRef, {
        'pendingFlags': updatedPending.map((f) => f.toMap()).toList(),
        'deliveredFlags': updatedDelivered.map((f) => f.toMap()).toList(),
      });
    });
  }
}
