import 'flag.dart';

class Site {
  String id;
  String name;
  List<Flag> activeFlags;
  List<Flag> washingFlags;
  List<Flag> stitchingFlags;
  List<Flag> disposedFlags; 

  Site({
    required this.id,
    required this.name,
    this.activeFlags = const [],
    this.washingFlags = const [],
    this.stitchingFlags = const [],
    this.disposedFlags = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'activeFlags': activeFlags.map((f) => f.toMap()).toList(),
        'washingFlags': washingFlags.map((f) => f.toMap()).toList(),
        'stitchingFlags': stitchingFlags.map((f) => f.toMap()).toList(),
        'disposedFlags': disposedFlags.map((f) => f.toMap()).toList(),
      };

  factory Site.fromMap(String id, Map<String, dynamic> map) => Site(
        id: id,
        name: map['name'] ?? '',
        activeFlags: _parseFlags(map['activeFlags']),
        washingFlags: _parseFlags(map['washingFlags']),
        stitchingFlags: _parseFlags(map['stitchingFlags']),
        disposedFlags: _parseFlags(map['disposedFlags']),
      );

  // Helper to keep the factory clean and handle nulls/empty lists
  static List<Flag> _parseFlags(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((f) => Flag.fromMap(f as Map<String, dynamic>)).toList();
  }
}
