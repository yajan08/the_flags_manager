class Flag {
  String type;   // Tiranga or Bhagwa
  String size;   // e.g., "10x6"
  int quantity;
  String? reason; // ✅ Add this for disposed flags

  Flag({
    required this.type,
    required this.size,
    required this.quantity,
    this.reason,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'size': size,
        'quantity': quantity,
        if (reason != null) 'reason': reason,
      };

  factory Flag.fromMap(Map<String, dynamic> map) => Flag(
        type: map['type'],
        size: map['size'],
        quantity: map['quantity'],
        reason: map['reason'], // Will be null if not present
      );
}
