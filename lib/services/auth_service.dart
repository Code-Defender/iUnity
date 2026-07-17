import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes (null means logged out, User means logged in)
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with Email and Password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      print("Sign Up Error: $e");
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      print("Sign In Error: $e");
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _handleAuthException(e);
      rethrow;
    } catch (e) {
      print("Password Reset Error: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Sign Out Error: $e");
      rethrow;
    }
  }

  // Exception handler helper
  void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        print('The password provided is too weak.');
        break;
      case 'email-already-in-use':
        print('The account already exists for that email.');
        break;
      case 'invalid-email':
        print('The email address is not valid.');
        break;
      case 'user-not-found':
        print('No user found for that email.');
        break;
      case 'wrong-password':
        print('Wrong password provided.');
        break;
      case 'user-disabled':
        print('This user has been disabled.');
        break;
      default:
        print('Auth Exception (${e.code}): ${e.message}');
    }
  }
}
