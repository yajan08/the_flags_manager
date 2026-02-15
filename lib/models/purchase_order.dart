import 'flag.dart';

class PurchaseOrder {
  String id;           // Firestore doc ID
  String poNumber;
  List<Flag> flags;
  String createdBy;
  DateTime createdAt;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.flags,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'poNumber': poNumber,
        'flags': flags.map((f) => f.toMap()).toList(),
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PurchaseOrder.fromMap(String id, Map<String, dynamic> map) =>
      PurchaseOrder(
        id: id,
        poNumber: map['poNumber'],
        flags: List<Flag>.from(
            (map['flags'] as List).map((f) => Flag.fromMap(f))),
        createdBy: map['createdBy'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}
