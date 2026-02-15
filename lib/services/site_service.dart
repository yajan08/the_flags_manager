import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flag.dart';
import '../models/site.dart';

class SiteService {
  static const List<String> systemSiteIds = [
    'office',
    'pending',
    'godown',
    'disposed',
  ];

  final CollectionReference _siteCollection =
      FirebaseFirestore.instance.collection('sites');

  /// Ensure default system sites exist
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

  /// Add new site
  Future<void> addSite(Site site) async {
    await _siteCollection.doc(site.id).set(site.toMap());
  }

  /// Stream all sites
  Stream<List<Site>> getSites() {
    return _siteCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            Site.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  /// Get site by ID
  Future<Site?> getSiteById(String id) async {
    final doc = await _siteCollection.doc(id).get();
    if (doc.exists) {
      return Site.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Update site (non-system only)
  Future<void> updateSite(Site site) async {
    if (systemSiteIds.contains(site.id)) {
      throw Exception("System sites cannot be renamed.");
    }

    await _siteCollection.doc(site.id).update(site.toMap());
  }

  /// Delete site (non-system only)
  Future<void> deleteSite(String id) async {
    if (systemSiteIds.contains(id)) {
      throw Exception("System sites cannot be deleted.");
    }

    await _siteCollection.doc(id).delete();
  }

  // ==========================================================
  // SAFE TRANSFER BETWEEN TWO SITES (NOW TRANSACTIONAL)
  // ==========================================================
  Future<void> transferFlags({
    required String fromSiteId,
    required String toSiteId,
    required List<Flag> flagsToTransfer,
    bool toWashing = false,
  }) async {
    final fromRef = _siteCollection.doc(fromSiteId);
    final toRef = _siteCollection.doc(toSiteId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final fromSnap = await transaction.get(fromRef);
      final toSnap = await transaction.get(toRef);

      if (!fromSnap.exists || !toSnap.exists) {
        throw Exception("One of the sites does not exist.");
      }

      List<Map<String, dynamic>> fromActive =
          List<Map<String, dynamic>>.from(
              fromSnap.get('activeFlags') ?? []);

      List<Map<String, dynamic>> toActive =
          List<Map<String, dynamic>>.from(
              toSnap.get('activeFlags') ?? []);

      List<Map<String, dynamic>> toWashingList =
          List<Map<String, dynamic>>.from(
              toSnap.get('washingFlags') ?? []);

      for (var flag in flagsToTransfer) {
        // ----- SUBTRACT FROM SOURCE -----
        int index = fromActive.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (index == -1) {
          throw Exception(
              'Flag ${flag.type} ${flag.size} not found in source.');
        }

        int available = fromActive[index]['quantity'];

        if (flag.quantity > available) {
          throw Exception(
              'Trying to transfer more than available.');
        }

        fromActive[index]['quantity'] = available - flag.quantity;

        if (fromActive[index]['quantity'] <= 0) {
          fromActive.removeAt(index);
        }

        // ----- ADD TO DESTINATION -----
        List<Map<String, dynamic>> targetList =
            toWashing ? toWashingList : toActive;

        int targetIndex = targetList.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (targetIndex >= 0) {
          targetList[targetIndex]['quantity'] += flag.quantity;
        } else {
          targetList.add(flag.toMap());
        }
      }

      transaction.update(fromRef, {
        'activeFlags': fromActive,
      });

      transaction.update(toRef, {
        'activeFlags': toActive,
        'washingFlags': toWashingList,
      });
    });
  }

  // ==========================================================
  // MOVE FLAGS WITHIN SAME SITE (ACTIVE -> WASHING)
  // ==========================================================
  Future<void> moveActiveToWashing({
    required String siteId,
    required List<Flag> flags,
  }) async {
    final siteRef = _siteCollection.doc(siteId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(siteRef);

      if (!snap.exists) {
        throw Exception("Site does not exist.");
      }

      List<Map<String, dynamic>> active =
          List<Map<String, dynamic>>.from(
              snap.get('activeFlags') ?? []);

      List<Map<String, dynamic>> washing =
          List<Map<String, dynamic>>.from(
              snap.get('washingFlags') ?? []);

      for (var flag in flags) {
        int activeIndex = active.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (activeIndex == -1) {
          throw Exception(
              'Flag ${flag.type} ${flag.size} not found in active.');
        }

        int available = active[activeIndex]['quantity'];

        if (flag.quantity > available) {
          throw Exception("Moving more than available.");
        }

        // subtract from active
        active[activeIndex]['quantity'] =
            available - flag.quantity;

        if (active[activeIndex]['quantity'] <= 0) {
          active.removeAt(activeIndex);
        }

        // add to washing
        int washIndex = washing.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (washIndex >= 0) {
          washing[washIndex]['quantity'] += flag.quantity;
        } else {
          washing.add(flag.toMap());
        }
      }

      transaction.update(siteRef, {
        'activeFlags': active,
        'washingFlags': washing,
      });
    });
  }

  // ==========================================================
  // ADD FLAGS TO SITE (SAFE)
  // ==========================================================
  Future<void> addFlagsToSite({
    required String siteId,
    required String siteName,
    required List<Flag> flags,
  }) async {
    final siteDoc = _siteCollection.doc(siteId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(siteDoc);

      if (!snapshot.exists) {
        transaction.set(siteDoc, {
          'name': siteName,
          'activeFlags': flags.map((f) => f.toMap()).toList(),
          'washingFlags': [],
        });
        return;
      }

      final currentFlags =
          List<Map<String, dynamic>>.from(
              snapshot.get('activeFlags') ?? []);

      for (var flag in flags) {
        int index = currentFlags.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (index >= 0) {
          currentFlags[index]['quantity'] += flag.quantity;
        } else {
          currentFlags.add(flag.toMap());
        }
      }

      transaction.update(siteDoc, {
        'activeFlags': currentFlags,
      });
    });
  }

  // ==========================================================
  // RECEIVE FROM PENDING → OFFICE
  // ==========================================================
  Future<void> receiveFlagsFromPendingToOffice(
      List<Flag> receivedFlags) async {
    final pendingRef = _siteCollection.doc('pending');
    final officeRef = _siteCollection.doc('office');

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final pendingSnap = await transaction.get(pendingRef);
      final officeSnap = await transaction.get(officeRef);

      if (!pendingSnap.exists) {
        throw Exception('Pending site does not exist.');
      }

      List<Map<String, dynamic>> pendingFlags =
          List<Map<String, dynamic>>.from(
              pendingSnap.get('activeFlags') ?? []);

      List<Map<String, dynamic>> officeFlags =
          officeSnap.exists
              ? List<Map<String, dynamic>>.from(
                  officeSnap.get('activeFlags') ?? [])
              : [];

      for (var flag in receivedFlags) {
        int pendingIndex = pendingFlags.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (pendingIndex == -1) {
          throw Exception(
              'Flag not found in Pending.');
        }

        int availableQty =
            pendingFlags[pendingIndex]['quantity'];

        if (flag.quantity > availableQty) {
          throw Exception(
              'Receiving more than available.');
        }

        pendingFlags[pendingIndex]['quantity'] =
            availableQty - flag.quantity;

        if (pendingFlags[pendingIndex]['quantity'] <= 0) {
          pendingFlags.removeAt(pendingIndex);
        }

        int officeIndex = officeFlags.indexWhere(
          (f) => f['type'] == flag.type && f['size'] == flag.size,
        );

        if (officeIndex >= 0) {
          officeFlags[officeIndex]['quantity'] += flag.quantity;
        } else {
          officeFlags.add(flag.toMap());
        }
      }

      transaction.update(pendingRef, {
        'activeFlags': pendingFlags,
      });

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
  // ==========================================================
// MOVE FLAGS WITHIN SAME SITE (WASHING -> ACTIVE)
// ==========================================================
Future<void> moveWashingToActive({
  required String siteId,
  required List<Flag> flags,
}) async {
  final siteRef = _siteCollection.doc(siteId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final snap = await transaction.get(siteRef);

    if (!snap.exists) {
      throw Exception("Site does not exist.");
    }

    List<Map<String, dynamic>> active =
        List<Map<String, dynamic>>.from(
            snap.get('activeFlags') ?? []);

    List<Map<String, dynamic>> washing =
        List<Map<String, dynamic>>.from(
            snap.get('washingFlags') ?? []);

    for (var flag in flags) {
      int washIndex = washing.indexWhere(
        (f) => f['type'] == flag.type && f['size'] == flag.size,
      );

      if (washIndex == -1) {
        throw Exception(
            'Flag ${flag.type} ${flag.size} not found in washing.');
      }

      int available = washing[washIndex]['quantity'];

      if (flag.quantity > available) {
        throw Exception("Returning more than available.");
      }

      // subtract from washing
      washing[washIndex]['quantity'] =
          available - flag.quantity;

      if (washing[washIndex]['quantity'] <= 0) {
        washing.removeAt(washIndex);
      }

      // add to active
      int activeIndex = active.indexWhere(
        (f) => f['type'] == flag.type && f['size'] == flag.size,
      );

      if (activeIndex >= 0) {
        active[activeIndex]['quantity'] += flag.quantity;
      } else {
        active.add(flag.toMap());
      }
    }

    transaction.update(siteRef, {
      'activeFlags': active,
      'washingFlags': washing,
    });
  });
}

}