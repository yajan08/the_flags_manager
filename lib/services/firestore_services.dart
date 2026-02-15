// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/flag.dart';
// import '../models/site.dart';
// import '../models/purchase_order.dart';
// import '../models/user.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   /// USERS
//   Future<void> addUser(AppUser user) async {
//     await _db.collection('users').doc(user.id).set(user.toMap());
//   }

//   Future<AppUser?> getUser(String id) async {
//     final doc = await _db.collection('users').doc(id).get();
//     if (doc.exists) return AppUser.fromMap(doc.id, doc.data()!);
//     return null;
//   }

//   /// SITES
//   Future<void> addSite(Site site) async {
//     await _db.collection('sites').doc(site.id).set(site.toMap());
//   }

//   Future<List<Site>> getSites() async {
//     final snapshot = await _db.collection('sites').get();
//     return snapshot.docs.map((doc) => Site.fromMap(doc.id, doc.data())).toList();
//   }

//   Future<void> updateSiteFlags(
//       String siteId, List<Flag> activeFlags, List<Flag> washingFlags) async {
//     await _db.collection('sites').doc(siteId).update({
//       'activeFlags': activeFlags.map((f) => f.toMap()).toList(),
//       'washingFlags': washingFlags.map((f) => f.toMap()).toList(),
//     });
//   }

//   /// PURCHASE ORDERS
//   Future<void> addPO(PurchaseOrder po) async {
//     await _db.collection('purchaseOrders').doc(po.id).set(po.toMap());
//   }

//   Future<List<PurchaseOrder>> getPOs() async {
//     final snapshot = await _db.collection('purchaseOrders').get();
//     return snapshot.docs
//         .map((doc) => PurchaseOrder.fromMap(doc.id, doc.data()))
//         .toList();
//   }

//   /// TRANSFER FLAGS
//   /// fromSiteId → toSiteId, move quantity of a specific flag type+size
//   Future<void> transferFlags({
//     required String fromSiteId,
//     required String toSiteId,
//     required Flag flag,
//     bool toWashing = false,
//   }) async {
//     final fromDoc = await _db.collection('sites').doc(fromSiteId).get();
//     final toDoc = await _db.collection('sites').doc(toSiteId).get();

//     Site fromSite = Site.fromMap(fromDoc.id, fromDoc.data()!);
//     Site toSite = Site.fromMap(toDoc.id, toDoc.data()!);

//     // Remove from source site
//     List<Flag> sourceList = fromSite.activeFlags;
//     for (var f in sourceList) {
//       if (f.type == flag.type && f.size == flag.size) {
//         if (f.quantity >= flag.quantity) {
//           f.quantity -= flag.quantity;
//         } else {
//           throw Exception("Not enough flags in source site");
//         }
//         break;
//       }
//     }
//     sourceList.removeWhere((f) => f.quantity == 0);

//     // Add to destination
//     List<Flag> targetList = toWashing ? toSite.washingFlags : toSite.activeFlags;
//     bool found = false;
//     for (var f in targetList) {
//       if (f.type == flag.type && f.size == flag.size) {
//         f.quantity += flag.quantity;
//         found = true;
//         break;
//       }
//     }
//     if (!found) {
//       targetList.add(Flag(type: flag.type, size: flag.size, quantity: flag.quantity));
//     }

//     // Update both sites
//     await updateSiteFlags(fromSiteId, fromSite.activeFlags, fromSite.washingFlags);
//     await updateSiteFlags(toSiteId, toSite.activeFlags, toSite.washingFlags);
//   }
// }
