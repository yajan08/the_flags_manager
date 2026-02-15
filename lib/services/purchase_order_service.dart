import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_order.dart';

class PurchaseOrderService {
  final CollectionReference _poCollection =
      FirebaseFirestore.instance.collection('purchaseOrders');

  // Add a new PO
  Future<void> addPO(PurchaseOrder po) async {
    await _poCollection.doc(po.id).set(po.toMap());
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
}
