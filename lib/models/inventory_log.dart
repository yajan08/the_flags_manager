import 'package:cloud_firestore/cloud_firestore.dart';
import 'flag.dart';

class InventoryLog {
  final String? id;           // Unique ID for the log
  final String userEmail;     // Email of the person who made the change
  final DateTime timestamp;   // Exact time of change
  final String action;        // 'TRANSFER', 'WASH_START', 'WASH_RETURN', 'RECEIVE', 'ADD'
  final String fromSite;      // Source site name
  final String toSite;        // Destination site name
  final List<Flag> flags;     // List of flags moved
  final String autoDescription; // The auto-generated sentence (e.g., "Moved 10 Tiranga...")

  InventoryLog({
    this.id,
    required this.userEmail,
    required this.timestamp,
    required this.action,
    required this.fromSite,
    required this.toSite,
    required this.flags,
    required this.autoDescription,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() => {
        'userEmail': userEmail,
        'timestamp': Timestamp.fromDate(timestamp),
        'action': action,
        'fromSite': fromSite,
        'toSite': toSite,
        'flags': flags.map((f) => f.toMap()).toList(),
        'autoDescription': autoDescription,
      };

  // Create from Firestore Map
  factory InventoryLog.fromMap(String id, Map<String, dynamic> map) => InventoryLog(
        id: id,
        userEmail: map['userEmail'] ?? '',
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        action: map['action'] ?? '',
        fromSite: map['fromSite'] ?? '',
        toSite: map['toSite'] ?? '',
        flags: (map['flags'] as List?)
                ?.map((f) => Flag.fromMap(f as Map<String, dynamic>))
                .toList() ??
            [],
        autoDescription: map['autoDescription'] ?? '',
      );
}