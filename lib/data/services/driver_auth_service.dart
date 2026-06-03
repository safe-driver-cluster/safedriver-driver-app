import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('[DriverAuthService.normalizePhone] input: $input');
    final cleaned = input.trim().replaceAll(RegExp(r'[\s()-]'), '');
    final normalized = cleaned.startsWith('+')
        ? cleaned
        : cleaned.startsWith('94')
        ? '+$cleaned'
        : cleaned.startsWith('0')
        ? '+94${cleaned.substring(1)}'
        : '+94$cleaned';
    debugPrint('[DriverAuthService.normalizePhone] normalized: $normalized');
    return normalized;
  }

  List<String> phoneVariants(String input) {
    final normalized = normalizePhone(input);
    final withoutPlus = normalized.replaceFirst('+', '');
    final local = withoutPlus.startsWith('94')
        ? '0${withoutPlus.substring(2)}'
        : withoutPlus;
    final variants = {
      input.trim(),
      normalized,
      withoutPlus,
      local,
    }.where((v) => v.isNotEmpty).toList();
    debugPrint('[DriverAuthService.phoneVariants] variants: $variants');
    return variants;
  }

  Future<DriverProfile?> findDriverByPhone(String input) async {
    debugPrint('[DriverAuthService.findDriverByPhone] input: $input');
    const fields = ['phoneNumber', 'phone', 'mobileNumber', 'contactNumber'];
    for (final field in fields) {
      for (final phone in phoneVariants(input)) {
        debugPrint(
          '[DriverAuthService.findDriverByPhone] querying drivers where $field == $phone',
        );
        final query = await _firestore
            .collection('drivers')
            .where(field, isEqualTo: phone)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final driver = DriverProfile.fromDoc(query.docs.first);
          debugPrint(
            '[DriverAuthService.findDriverByPhone] found driver id=${driver.id}, active=${driver.isActive}',
          );
          if (driver.isActive) return driver;
        }
      }
    }
    debugPrint('[DriverAuthService.findDriverByPhone] no active driver found');
    return null;
  }

  Future<DriverProfile?> findDriverById(String id) async {
    try {
      debugPrint('[DriverAuthService.findDriverById] id: $id');
      final doc = await _firestore.collection('drivers').doc(id).get();
      debugPrint('[DriverAuthService.findDriverById] exists: ${doc.exists}');
      if (!doc.exists) return null;
      final driver = DriverProfile.fromDoc(doc);
      debugPrint(
        '[DriverAuthService.findDriverById] active=${driver.isActive}, phone=${driver.phoneNumber}',
      );
      return driver.isActive ? driver : null;
    } on FirebaseException {
      debugPrint('[DriverAuthService.findDriverById] FirebaseException');
      return null;
    }
  }

  Future<OtpStartResult> startOtpLogin(String phoneInput) async {
    debugPrint('[DriverAuthService.startOtpLogin] raw phoneInput: $phoneInput');
    debugPrint(
      '[DriverAuthService.startOtpLogin] current Firebase user before send: ${_auth.currentUser?.uid}',
    );
    final phoneNumber = normalizePhone(phoneInput);

    try {
      final callable = _functions.httpsCallable('driverSendOTP');
      debugPrint(
        '[DriverAuthService.startOtpLogin] calling driverSendOTP phoneNumber=$phoneNumber',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
      });
      final data = Map<String, dynamic>.from(result.data);
      debugPrint('[DriverAuthService.startOtpLogin] response: $data');
      final driverId = data['driverId']?.toString();
      final driverData = Map<String, dynamic>.from(
        data['driver'] as Map? ?? {},
      );
      debugPrint(
        '[DriverAuthService.startOtpLogin] driverId=$driverId, driverDataEmpty=${driverData.isEmpty}',
      );
      if (driverId == null || driverId.isEmpty || driverData.isEmpty) {
        debugPrint(
          '[DriverAuthService.startOtpLogin] invalid response, throwing driver_not_found',
        );
        throw DriverAuthException('driver_not_found');
      }

      return OtpStartResult(
        verificationId: data['verificationId'] as String,
        phoneNumber: data['phoneNumber'] as String? ?? phoneNumber,
        driver: DriverProfile.fromMap(driverId, driverData),
        expiresAt: DateTime.tryParse(data['expiresAt']?.toString() ?? ''),
      );
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        '[DriverAuthService.startOtpLogin] FirebaseFunctionsException code=${error.code}, message=${error.message}, details=${error.details}',
      );
      throw DriverAuthException(
        error.code == 'not-found' ? 'driver_not_found' : 'otp_failed',
      );
    } catch (error, stackTrace) {
      debugPrint('[DriverAuthService.startOtpLogin] unexpected error: $error');
      debugPrint('[DriverAuthService.startOtpLogin] stackTrace: $stackTrace');
      rethrow;
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
      debugPrint(
        '[DriverAuthService.verifyOtp] verificationId: $verificationId',
      );
      debugPrint('[DriverAuthService.verifyOtp] phoneNumber: $phoneNumber');
      debugPrint(
        '[DriverAuthService.verifyOtp] smsCode length: ${smsCode.length}',
      );
      debugPrint(
        '[DriverAuthService.verifyOtp] current Firebase user before verify: ${_auth.currentUser?.uid}',
      );
      final callable = _functions.httpsCallable('driverVerifyOTP');
      final normalizedPhone = normalizePhone(phoneNumber);
      debugPrint(
        '[DriverAuthService.verifyOtp] calling driverVerifyOTP normalizedPhone=$normalizedPhone',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'verificationId': verificationId,
        'otp': smsCode,
        'phoneNumber': normalizedPhone,
      });
      final data = Map<String, dynamic>.from(result.data);
      debugPrint('[DriverAuthService.verifyOtp] response: $data');
      final token = data['customToken']?.toString();
      final driverId = data['driverId']?.toString();
      final driverData = Map<String, dynamic>.from(
        data['driver'] as Map? ?? {},
      );
      debugPrint(
        '[DriverAuthService.verifyOtp] tokenPresent=${token != null && token.isNotEmpty}, driverId=$driverId, driverDataEmpty=${driverData.isEmpty}',
      );
      if (token == null ||
          token.isEmpty ||
          driverId == null ||
          driverId.isEmpty) {
        debugPrint(
          '[DriverAuthService.verifyOtp] invalid response, throwing login_failed',
        );
        throw DriverAuthException('login_failed');
      }

      debugPrint('[DriverAuthService.verifyOtp] signing in with custom token');
      await _auth.signInWithCustomToken(token);
      debugPrint(
        '[DriverAuthService.verifyOtp] Firebase user after custom token: ${_auth.currentUser?.uid}',
      );
      final returnedDriver = driverData.isEmpty
          ? null
          : DriverProfile.fromMap(driverId, driverData);
      final driver = await findDriverById(driverId) ?? returnedDriver;
      if (driver == null) {
        debugPrint(
          '[DriverAuthService.verifyOtp] driver profile not found after token sign-in. Signing out.',
        );
        await _auth.signOut();
        throw DriverAuthException('driver_not_found');
      }
      debugPrint(
        '[DriverAuthService.verifyOtp] verified driver id=${driver.id}, name=${driver.fullName}',
      );
      return driver;
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        '[DriverAuthService.verifyOtp] FirebaseFunctionsException code=${error.code}, message=${error.message}, details=${error.details}',
      );
      throw DriverAuthException(
        error.code == 'not-found' ? 'driver_not_found' : 'login_failed',
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        '[DriverAuthService.verifyOtp] FirebaseAuthException code=${error.code}, message=${error.message}',
      );
      throw DriverAuthException('login_failed');
    } catch (error, stackTrace) {
      debugPrint('[DriverAuthService.verifyOtp] unexpected error: $error');
      debugPrint('[DriverAuthService.verifyOtp] stackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();
}

class DriverAuthException implements Exception {
  DriverAuthException(this.code);
  final String code;
}
