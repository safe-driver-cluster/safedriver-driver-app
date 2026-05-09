import 'package:flutter/foundation.dart';

import '../../data/models/driver_models.dart';
import '../../data/services/driver_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({DriverAuthService? authService})
    : _authService = authService ?? DriverAuthService();

  final DriverAuthService _authService;

  bool isLoading = false;
  String? errorCode;

  Future<OtpStartResult?> startOtpLogin(String phoneNumber) async {
    return _guard(() => _authService.startOtpLogin(phoneNumber), 'otp_failed');
  }

  Future<OtpStartResult?> resendOtp(String phoneNumber) async {
    return _guard(() => _authService.resendOtp(phoneNumber), 'otp_failed');
  }

  Future<DriverProfile?> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    return _guard(
      () => _authService.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      ),
      'login_failed',
    );
  }

  Future<T?> _guard<T>(Future<T> Function() action, String fallback) async {
    isLoading = true;
    errorCode = null;
    notifyListeners();
    try {
      return await action();
    } on DriverAuthException catch (error) {
      errorCode = error.code;
      return null;
    } catch (_) {
      errorCode = fallback;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
