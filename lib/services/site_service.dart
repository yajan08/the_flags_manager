import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flag.dart';
import '../models/site.dart';

class SiteService {

  static const List<String> systemSiteIds = [
    'office',
    'pending',
    'godown',
  ];

  final CollectionReference _siteCollection =
      FirebaseFirestore.instance.collection('sites');

  Future<void> ensureDefaultSitesExist() async {
    for (var id in systemSiteIds) {
      final doc = await _siteCollection.doc(id).get();

      if (!doc.exists) {
        await _siteCollection.doc(id).set({
          'name': id[0].toUpperCase() + id.substring(1),
          'activeFlags': [],
          'washingFlags': [],
        });
      }
    }
  }


  /// Add a new site
  Future<void> addSite(Site site) async {
    await _siteCollection.doc(site.id).set(site.toMap());
  }

  /// Get all sites as stream
  Stream<List<Site>> getSites() {
    return _siteCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Site.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get a site by ID
  Future<Site?> getSiteById(String id) async {
    final doc = await _siteCollection.doc(id).get();
    if (doc.exists) {
      return Site.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Update a site
  Future<void> updateSite(Site site) async {
    if (systemSiteIds.contains(site.id)) {
      throw Exception("System sites cannot be renamed.");
    }

    await _siteCollection.doc(site.id).update(site.toMap());
  }


  /// Delete a site
  Future<void> deleteSite(String id) async {
    if (systemSiteIds.contains(id)) {
      throw Exception("System sites cannot be deleted.");
    }

    await _siteCollection.doc(id).delete();
  }


  /// Transfer flags between sites
  /// `toWashing` determines if flags go to washingFlags or activeFlags
  Future<void> transferFlags({
    required Site from,
    required Site to,
    required List<Flag> flagsToTransfer,
    bool toWashing = false,
  }) async {
    // Update source site (subtract quantities)
    for (var flag in flagsToTransfer) {
      List<Flag> sourceList = from.activeFlags;
      var existing = sourceList.firstWhere(
          (f) => f.type == flag.type && f.size == flag.size,
          orElse: () => Flag(type: flag.type, size: flag.size, quantity: 0));
      if (existing.quantity >= flag.quantity) {
        existing.quantity -= flag.quantity;
      } else {
        existing.quantity = 0;
      }
      // Remove any zero-quantity flags
      sourceList.removeWhere((f) => f.quantity <= 0);
    }

    await updateSite(from);

    // Update destination site (add quantities)
    List<Flag> targetList = toWashing ? to.washingFlags : to.activeFlags;

    for (var flag in flagsToTransfer) {
      var existing = targetList.firstWhere(
          (f) => f.type == flag.type && f.size == flag.size,
          orElse: () => Flag(type: flag.type, size: flag.size, quantity: 0));

      if (targetList.contains(existing)) {
        existing.quantity += flag.quantity;
      } else {
        targetList.add(flag);
      }
    }

    await updateSite(to);
  }

  /// Add flags directly to the Office site (used when adding new PO)
  /// Add flags to a specific site (auto-creates site if missing)
Future<void> addFlagsToSite({
  required String siteId,
  required String siteName,
  required List<Flag> flags,
}) async {
  final siteDoc = _siteCollection.doc(siteId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(siteDoc);

    if (!snapshot.exists) {
      // Create site if it doesn't exist
      transaction.set(siteDoc, {
        'name': siteName,
        'activeFlags': flags.map((f) => f.toMap()).toList(),
        'washingFlags': [],
      });
      return;
    }

    // Get current active flags
    final currentFlags =
        List<Map<String, dynamic>>.from(snapshot.get('activeFlags') ?? []);

    for (var flag in flags) {
      var index = currentFlags.indexWhere(
        (f) => f['type'] == flag.type && f['size'] == flag.size,
      );

      if (index >= 0) {
        currentFlags[index]['quantity'] += flag.quantity;
      } else {
        currentFlags.add(flag.toMap());
      }
    }

    transaction.update(siteDoc, {'activeFlags': currentFlags});
  });
}
/// Receive flags from Pending and move them to Office
Future<void> receiveFlagsFromPendingToOffice(
  List<Flag> receivedFlags,
) async {
  final pendingRef = _siteCollection.doc('pending');
  final officeRef = _siteCollection.doc('office');

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final pendingSnap = await transaction.get(pendingRef);
    final officeSnap = await transaction.get(officeRef);

    if (!pendingSnap.exists) {
      throw Exception('Pending site does not exist.');
    }

    // Get current lists
    List<Map<String, dynamic>> pendingFlags =
        List<Map<String, dynamic>>.from(
            pendingSnap.get('activeFlags') ?? []);

    List<Map<String, dynamic>> officeFlags = officeSnap.exists
        ? List<Map<String, dynamic>>.from(
            officeSnap.get('activeFlags') ?? [])
        : [];

    for (var flag in receivedFlags) {
      // ----- VALIDATE & SUBTRACT FROM PENDING -----
      int pendingIndex = pendingFlags.indexWhere(
        (f) => f['type'] == flag.type && f['size'] == flag.size,
      );

      if (pendingIndex == -1) {
        throw Exception(
            'Flag ${flag.type} ${flag.size} not found in Pending.');
      }

      int availableQty = pendingFlags[pendingIndex]['quantity'];

      if (flag.quantity > availableQty) {
        throw Exception(
            'Trying to receive more than available for ${flag.type} ${flag.size}.');
      }

      pendingFlags[pendingIndex]['quantity'] =
          availableQty - flag.quantity;

      // Remove if zero
      if (pendingFlags[pendingIndex]['quantity'] <= 0) {
        pendingFlags.removeAt(pendingIndex);
      }

      // ----- ADD TO OFFICE -----
      int officeIndex = officeFlags.indexWhere(
        (f) => f['type'] == flag.type && f['size'] == flag.size,
      );

      if (officeIndex >= 0) {
        officeFlags[officeIndex]['quantity'] += flag.quantity;
      } else {
        officeFlags.add(flag.toMap());
      }
    }

    // Update pending
    transaction.update(pendingRef, {
      'activeFlags': pendingFlags,
    });

    // Create or update office
    if (!officeSnap.exists) {
      transaction.set(officeRef, {
        'name': 'Office',
        'activeFlags': officeFlags,
        'washingFlags': [],
      });
    } else {
      transaction.update(officeRef, {
        'activeFlags': officeFlags,
      });
    }
  });
}

}
