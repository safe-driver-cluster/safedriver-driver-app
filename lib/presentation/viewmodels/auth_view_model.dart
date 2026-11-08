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
    debugPrint('[AuthViewModel.startOtpLogin] phoneNumber: $phoneNumber');
    return _guard(() => _authService.startOtpLogin(phoneNumber), 'otp_failed');
  }

  Future<OtpStartResult?> resendOtp(String phoneNumber) async {
    debugPrint('[AuthViewModel.resendOtp] phoneNumber: $phoneNumber');
    return _guard(() => _authService.resendOtp(phoneNumber), 'otp_failed');
  }

  Future<DriverProfile?> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    debugPrint('[AuthViewModel.verifyOtp] verificationId: $verificationId');
    debugPrint('[AuthViewModel.verifyOtp] phoneNumber: $phoneNumber');
    debugPrint('[AuthViewModel.verifyOtp] smsCode length: ${smsCode.length}');
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
    debugPrint('[AuthViewModel._guard] start fallback=$fallback');
    isLoading = true;
    errorCode = null;
    notifyListeners();
    try {
      final result = await action();
      debugPrint(
        '[AuthViewModel._guard] success resultType=${result.runtimeType}',
      );
      return result;
    } on DriverAuthException catch (error) {
      debugPrint(
        '[AuthViewModel._guard] DriverAuthException code=${error.code}',
      );
      errorCode = error.code;
      return null;
    } catch (error, stackTrace) {
      debugPrint('[AuthViewModel._guard] unexpected error: $error');
      debugPrint('[AuthViewModel._guard] stackTrace: $stackTrace');
      errorCode = fallback;
      return null;
    } finally {
      isLoading = false;
      debugPrint('[AuthViewModel._guard] finish errorCode=$errorCode');
      notifyListeners();
    }
  }
}
