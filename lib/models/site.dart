import 'flag.dart';

class Site {
  String id;               // Firestore document ID
  String name;             // Office, Godown, Customer Name
  List<Flag> activeFlags;  // flags not in washing
  List<Flag> washingFlags; // flags in washing

  Site({
    required this.id,
    required this.name,
    this.activeFlags = const [],
    this.washingFlags = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'activeFlags': activeFlags.map((f) => f.toMap()).toList(),
        'washingFlags': washingFlags.map((f) => f.toMap()).toList(),
      };

  factory Site.fromMap(String id, Map<String, dynamic> map) => Site(
        id: id,
        name: map['name'],
        activeFlags: (map['activeFlags'] as List?)
                ?.map((f) => Flag.fromMap(f))
                .toList() ??
            [],
        washingFlags: (map['washingFlags'] as List?)
                ?.map((f) => Flag.fromMap(f))
                .toList() ??
            [],
      );
}
