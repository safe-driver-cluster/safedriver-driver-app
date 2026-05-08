import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone: $e');
      return false;
    }
  }

  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(PhoneAuthCredential) onCodeSent,
    required Function(FirebaseAuthException) onError,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-retrieval
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          // This is called when code is sent
          // We'll handle this in the screen
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      print('Error verifying phone: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithPhoneNumber(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDriverData(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error fetching driver data: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error logging out: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}
