import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/auth_view_model.dart';
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

  @override
  void initState() {
    super.initState();
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
    final l10n = AppLocalizations.of(context);
    if (_otp.text.trim().length < 6) {
      _show(l10n.t('otpRequired'));
      return;
    }
    final driver = await _viewModel.verifyOtp(
      verificationId: _result.verificationId,
      smsCode: _otp.text.trim(),
      phoneNumber: _result.phoneNumber,
    );
    if (!mounted) return;
    if (driver == null) {
      _show(l10n.t('loginFailed'));
      return;
    }
    AppScope.of(context).setDriver(driver);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (_) => false,
    );
  }

  Future<void> _resend() async {
    final l10n = AppLocalizations.of(context);
    final next = await _viewModel.resendOtp(_result.phoneNumber);
    if (!mounted) return;
    if (next == null) {
      _show(l10n.t('otpFailed'));
      return;
    }
    _otp.clear();
    setState(() => _result = next);
    _startTimer();
  }

  void _show(String message) {
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
        return Scaffold(
          appBar: AppBar(),
          body: Padding(
            padding: const EdgeInsets.all(AppDesign.spaceXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDesign.spaceXL),
                Icon(Icons.verified_user_rounded, size: 74, color: th.primary),
                const SizedBox(height: AppDesign.spaceXL),
                Text(
                  l10n.t('otpTitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headline3.copyWith(
                    color: th.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDesign.spaceMD),
                Text(
                  '${l10n.t('otpSubtitle')}\n${_result.phoneNumber}',
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
                ),
                const SizedBox(height: AppDesign.space2XL),
                GradientButton(
                  label: l10n.t('verifyLogin'),
                  icon: Icons.login_rounded,
                  isLoading: _viewModel.isLoading,
                  onPressed: _verify,
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
