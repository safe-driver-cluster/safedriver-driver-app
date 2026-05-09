import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/driver_models.dart';

class OtpStartResult {
  OtpStartResult({
    required this.verificationId,
    required this.phoneNumber,
    required this.driver,
    this.expiresAt,
  });

  final String verificationId;
  final String phoneNumber;
  final DriverProfile driver;
  final DateTime? expiresAt;
}

class DriverAuthService {
  DriverAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String normalizePhone(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('94')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+94${cleaned.substring(1)}';
    return '+94$cleaned';
  }

  List<String> phoneVariants(String input) {
    final normalized = normalizePhone(input);
    final withoutPlus = normalized.replaceFirst('+', '');
    final local = withoutPlus.startsWith('94')
        ? '0${withoutPlus.substring(2)}'
        : withoutPlus;
    return {
      input.trim(),
      normalized,
      withoutPlus,
      local,
    }.where((v) => v.isNotEmpty).toList();
  }

  Future<DriverProfile?> findDriverByPhone(String input) async {
    const fields = ['phoneNumber', 'phone', 'mobileNumber', 'contactNumber'];
    for (final field in fields) {
      for (final phone in phoneVariants(input)) {
        final query = await _firestore
            .collection('drivers')
            .where(field, isEqualTo: phone)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final driver = DriverProfile.fromDoc(query.docs.first);
          if (driver.isActive) return driver;
        }
      }
    }
    return null;
  }

  Future<DriverProfile?> findDriverById(String id) async {
    final doc = await _firestore.collection('drivers').doc(id).get();
    if (!doc.exists) return null;
    final driver = DriverProfile.fromDoc(doc);
    return driver.isActive ? driver : null;
  }

  Future<OtpStartResult> startOtpLogin(String phoneInput) async {
    final phoneNumber = normalizePhone(phoneInput);
    final driver = await findDriverByPhone(phoneNumber);
    if (driver == null) throw DriverAuthException('driver_not_found');

    try {
      final callable = _functions.httpsCallable('driverSendOTP');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
      });
      final data = Map<String, dynamic>.from(result.data);
      return OtpStartResult(
        verificationId: data['verificationId'] as String,
        phoneNumber: data['phoneNumber'] as String? ?? phoneNumber,
        driver: driver,
        expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
      );
    } on FirebaseFunctionsException catch (error) {
      throw DriverAuthException(
        error.code == 'not-found' ? 'driver_not_found' : 'otp_failed',
      );
    }
  }

  Future<OtpStartResult> resendOtp(String phoneNumber) =>
      startOtpLogin(phoneNumber);

  Future<DriverProfile> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    try {
      final callable = _functions.httpsCallable('driverVerifyOTP');
      final result = await callable.call<Map<String, dynamic>>({
        'verificationId': verificationId,
        'otp': smsCode,
        'phoneNumber': normalizePhone(phoneNumber),
      });
      final data = Map<String, dynamic>.from(result.data);
      final token = data['customToken']?.toString();
      final driverId = data['driverId']?.toString();
      if (token == null ||
          token.isEmpty ||
          driverId == null ||
          driverId.isEmpty) {
        throw DriverAuthException('login_failed');
      }

      await _auth.signInWithCustomToken(token);
      final driver =
          await findDriverById(driverId) ??
          await findDriverByPhone(phoneNumber);
      if (driver == null) {
        await _auth.signOut();
        throw DriverAuthException('driver_not_found');
      }
      return driver;
    } on FirebaseFunctionsException catch (error) {
      throw DriverAuthException(
        error.code == 'not-found' ? 'driver_not_found' : 'login_failed',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();
}

class DriverAuthException implements Exception {
  DriverAuthException(this.code);
  final String code;
}
