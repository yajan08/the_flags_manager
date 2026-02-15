import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  // 🔹 Get user by ID
  Future<AppUser?> getUserById(String id) async {
    final doc = await _userCollection.doc(id).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // 🔹 Alias method for clarity
  Future<AppUser?> getUserByUid(String uid) async {
    return getUserById(uid);
  }

  // 🔹 Get all users (admin panel use)
  Stream<List<AppUser>> getAllUsers() {
    return _userCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // 🔹 Create user in Firestore
  Future<void> createUserInFirestore({
    required String uid,
    required String name,
    required String role,
  }) async {
    await _userCollection.doc(uid).set({
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 Get current user data
  Future<AppUser?> getCurrentUserData(String uid) async {
    return getUserById(uid);
  }

  // 🔹 Update user role (only person1@gmail.com will call this)
  Future<void> updateUserRole({
  required String uid,
  required String newRole,
  required String currentUserEmail,
}) async {
  // Only allow person1@gmail.com to change roles
  if (currentUserEmail != "person1@gmail.com") {
    throw "You are not authorized to change roles.";
  }

  await _userCollection.doc(uid).update({
    'role': newRole,
  });
}

}
