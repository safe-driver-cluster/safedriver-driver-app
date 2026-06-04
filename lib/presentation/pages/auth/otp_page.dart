import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/common/auth_error_message.dart';
import '../../widgets/common/professional_widgets.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.result});

  final OtpStartResult result;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otp = TextEditingController();
  final _viewModel = AuthViewModel();
  late OtpStartResult _result = widget.result;
  Timer? _timer;
  int _seconds = 45;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[DriverOtpPage.initState] verificationId=${_result.verificationId}, phone=${_result.phoneNumber}, driverId=${_result.driver.id}',
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    if (_isVerifying) {
      debugPrint('[DriverOtpPage._verify] ignored duplicate verify');
      return;
    }

    final l10n = AppLocalizations.of(context);
    final code = _otp.text.trim();
    debugPrint('[DriverOtpPage._verify] pressed');
    debugPrint(
      '[DriverOtpPage._verify] verificationId=${_result.verificationId}',
    );
    debugPrint('[DriverOtpPage._verify] phone=${_result.phoneNumber}');
    debugPrint('[DriverOtpPage._verify] otp length=${code.length}');
    if (_otp.text.trim().length < 6) {
      debugPrint('[DriverOtpPage._verify] OTP validation failed');
      final message = l10n.t('otpRequired');
      setState(() => _errorMessage = message);
      _show(message);
      return;
    }
    setState(() {
      _errorMessage = null;
      _isVerifying = true;
    });
    try {
      final driver = await _viewModel.verifyOtp(
        verificationId: _result.verificationId,
        smsCode: code,
        phoneNumber: _result.phoneNumber,
      );
      if (!mounted) return;
      if (driver == null) {
        debugPrint(
          '[DriverOtpPage._verify] failed errorCode=${_viewModel.errorCode}',
        );
        final message = l10n.authErrorMessage(_viewModel.errorCode);
        setState(() => _errorMessage = message);
        _show(message);
        return;
      }
      debugPrint(
        '[DriverOtpPage._verify] success driverId=${driver.id}, name=${driver.fullName}',
      );
      AppScope.of(context).setDriver(driver);
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    debugPrint('[DriverOtpPage._resend] pressed phone=${_result.phoneNumber}');
    final next = await _viewModel.resendOtp(_result.phoneNumber);
    if (!mounted) return;
    if (next == null) {
      debugPrint(
        '[DriverOtpPage._resend] failed errorCode=${_viewModel.errorCode}',
      );
      final message = l10n.authErrorMessage(
        _viewModel.errorCode,
        fallbackKey: 'otpFailed',
      );
      setState(() => _errorMessage = message);
      _show(message);
      return;
    }
    debugPrint(
      '[DriverOtpPage._resend] success verificationId=${next.verificationId}, phone=${next.phoneNumber}',
    );
    _otp.clear();
    setState(() {
      _errorMessage = null;
      _result = next;
    });
    _startTimer();
  }

  void _show(String message) {
    debugPrint('[DriverOtpPage._show] $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final th = ThemeHelper.of(context);
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return DriverPageShell(
          title: l10n.t('otpTitle'),
          subtitle: _result.phoneNumber,
          body: Padding(
            padding: const EdgeInsets.all(AppDesign.spaceXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDesign.spaceXL),
                Icon(Icons.verified_user_rounded, size: 74, color: th.primary),
                const SizedBox(height: AppDesign.spaceXL),
                Text(
                  l10n.t('otpSubtitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: th.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDesign.space2XL),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline3.copyWith(
                    color: th.textPrimary,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.t('otpCode'),
                    counterText: '',
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppDesign.spaceLG),
                  AuthErrorMessage(message: _errorMessage!),
                ],
                const SizedBox(height: AppDesign.space2XL),
                GradientButton(
                  label: l10n.t('verifyLogin'),
                  icon: Icons.login_rounded,
                  isLoading: _viewModel.isLoading || _isVerifying,
                  onPressed: _isVerifying ? null : _verify,
                ),
                const SizedBox(height: AppDesign.spaceLG),
                TextButton(
                  onPressed: _seconds == 0 && !_viewModel.isLoading
                      ? _resend
                      : null,
                  child: Text(
                    _seconds == 0
                        ? l10n.t('resendOtp')
                        : '${l10n.t('resendIn')} $_seconds s',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
