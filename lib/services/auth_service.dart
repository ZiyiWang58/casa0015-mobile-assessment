import 'package:firebase_auth/firebase_auth.dart';

/// Handles Firebase Authentication tasks for the app.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of authentication state changes used by the app gate.
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Register a new user with email and password.
  static Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign in an existing user with email and password.
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Return the currently signed-in Firebase user, if any.
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}