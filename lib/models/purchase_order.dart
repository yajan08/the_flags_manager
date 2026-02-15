import 'flag.dart';

class PurchaseOrder {
  String id;           // Firestore doc ID
  String poNumber;
  List<Flag> pendingFlags;   // Flags yet to be received
  List<Flag> deliveredFlags; // Flags already received
  String createdBy;
  DateTime createdAt;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.pendingFlags,
    required this.deliveredFlags,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'poNumber': poNumber,
        'pendingFlags': pendingFlags.map((f) => f.toMap()).toList(),
        'deliveredFlags': deliveredFlags.map((f) => f.toMap()).toList(),
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PurchaseOrder.fromMap(String id, Map<String, dynamic> map) =>
      PurchaseOrder(
        id: id,
        poNumber: map['poNumber'],
        pendingFlags: List<Flag>.from(
            (map['pendingFlags'] as List? ?? []).map((f) => Flag.fromMap(f))),
        deliveredFlags: List<Flag>.from(
            (map['deliveredFlags'] as List? ?? []).map((f) => Flag.fromMap(f))),
        createdBy: map['createdBy'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}
