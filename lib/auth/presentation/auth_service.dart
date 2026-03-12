import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> signUp({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'mobile': mobile.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userCredential.user!.updateDisplayName(fullName.trim());

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return e.message ?? 'Something went wrong.';
      }
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  static User? get currentUser => _auth.currentUser;
}