class Flag {
  String type;   // Tiranga or Bhagwa
  String size;   // e.g., "10x6"
  int quantity;

  Flag({
    required this.type,
    required this.size,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'size': size,
        'quantity': quantity,
      };

  factory Flag.fromMap(Map<String, dynamic> map) => Flag(
        type: map['type'],
        size: map['size'],
        quantity: map['quantity'],
      );
}
