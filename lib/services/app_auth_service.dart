import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Holds the current session's identity for use across the app
/// (passed into requests, chat messages, Discord alerts, etc).
class AppUser {
  static String? uid;
  static String? name;
  static bool isGuest = false;

  static bool get isSignedIn => uid != null;

  static void clear() {
    uid = null;
    name = null;
    isGuest = false;
  }

  /// Populates AppUser from a Firebase user (used on fresh sign-in AND
  /// on app restart when an existing session is found).
  static void loadFrom(User user) {
    uid = user.uid;
    name = user.displayName ?? user.email?.split('@').first ?? 'Guest';
    isGuest = user.isAnonymous;
  }
}

/// Thrown when the user deliberately dismisses the Google sign-in sheet.
/// Callers should treat this as a silent no-op, not an error to display.
class SignInCancelledException implements Exception {
  const SignInCancelledException();
}

class AppAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Call once at app startup. If a session already exists (Firebase
  /// persists sign-in across restarts on Android by default), this
  /// restores AppUser from it so the login screen can be skipped.
  static bool restoreSession() {
    final user = _auth.currentUser;
    if (user == null) return false;
    AppUser.loadFrom(user);
    return true;
  }

  /// Google Sign-In — uses the v7 Credential Manager API.
  ///
  /// `authenticate()` alone always shows the legacy dialog-style picker
  /// on Android (it's hardcoded to the "button flow" / GetSignInWithGoogleOption).
  /// The modern bottom-sheet only comes from `attemptLightweightAuthentication()`
  /// (GetGoogleIdOption), which tries previously-signed-in accounts first —
  /// so we try that first and only fall back to the dialog picker if there's
  /// genuinely no eligible account. `reportAllExceptions: true` makes a
  /// dismissed sheet throw a distinguishable `canceled` exception instead of
  /// silently returning null, so we can tell "nothing to try" apart from
  /// "user closed it" and only fall through to the dialog in the first case.
  static bool _googleInitialized = false;

  static Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await googleSignIn.initialize(
        serverClientId: '122741019764-pqvtnhcrficnia4nrom1c66vmn1n7807.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    }

    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.attemptLightweightAuthentication(
        reportAllExceptions: true,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User explicitly dismissed the bottom sheet — stop here rather
        // than falling through to the dialog picker.
        throw const SignInCancelledException();
      }
      // Any other exception here means nothing was eligible to try —
      // fall through to the full picker below.
    }

    googleUser ??= await googleSignIn.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) throw Exception('Sign-in failed');

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('Sign-in failed');

    AppUser.loadFrom(user);
  }

  /// Email/password sign up — creates a new Firebase account and sets the
  /// display name so it shows up consistently everywhere else in the app.
  static Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = userCredential.user;
    if (user == null) throw Exception('Sign-up failed');

    await user.updateDisplayName(name.trim());
    await user.reload();

    AppUser.loadFrom(_auth.currentUser!);
  }

  /// Email/password sign in — for existing accounts.
  static Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = userCredential.user;
    if (user == null) throw Exception('Sign-in failed');

    AppUser.loadFrom(user);
  }

  /// Sends a password reset email via Firebase's built-in flow.
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Guest sign-in — anonymous Firebase auth, with a mandatory display name
  /// supplied by the user. The name is saved onto the Firebase user profile
  /// itself so it survives app restarts (Firebase keeps the same anonymous
  /// account on the same device unless explicitly signed out).
  static Future<void> signInAsGuest(String name) async {
    final userCredential = await _auth.signInAnonymously();
    final user = userCredential.user;
    if (user == null) throw Exception('Sign-in failed');

    await user.updateDisplayName(name.trim());
    await user.reload();

    AppUser.loadFrom(_auth.currentUser!);
  }

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
    AppUser.clear();
  }

  /// Maps common FirebaseAuthException codes to friendly messages.
  static String friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}