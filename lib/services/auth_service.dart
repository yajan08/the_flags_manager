import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Get current user
  User? get currentUser => _auth.currentUser;

  // 🔹 Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 🔹 Login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed";
    } catch (_) {
      throw "Something went wrong";
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Create user (for admin use later)
  Future<UserCredential> createUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "User creation failed";
    } catch (_) {
      throw "Something went wrong";
    }
  }
}
