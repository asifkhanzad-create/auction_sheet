import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  static const String allowedAdminEmail = 'asifkhanzad@gmail.com';

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool isAllowed(User? user) {
    if (user == null || user.email == null) return false;
    return user.email!.toLowerCase() == allowedAdminEmail.toLowerCase();
  }

  /// Signs in with Google using Firebase's own web popup flow.
  /// Throws [NotAllowedException] if the signed-in account isn't the admin email.
  static Future<User?> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final userCredential = await _auth.signInWithPopup(provider);
    final user = userCredential.user;

    if (!isAllowed(user)) {
      await signOut();
      throw NotAllowedException();
    }

    return user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}

class NotAllowedException implements Exception {
  @override
  String toString() => 'This Google account is not authorized for admin access.';
}