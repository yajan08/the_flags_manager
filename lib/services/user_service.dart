import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  // Get user by ID (used for login)
  Future<AppUser?> getUserById(String id) async {
    final doc = await _userCollection.doc(id).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Get all users (optional for admin selection)
  Stream<List<AppUser>> getAllUsers() {
    return _userCollection.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }
}
