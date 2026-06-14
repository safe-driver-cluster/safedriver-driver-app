import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
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
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
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
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
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
    final code = _otpCode;
    debugPrint('[DriverOtpPage._verify] pressed');
    debugPrint(
      '[DriverOtpPage._verify] verificationId=${_result.verificationId}',
    );
    debugPrint('[DriverOtpPage._verify] phone=${_result.phoneNumber}');
    debugPrint('[DriverOtpPage._verify] otp length=${code.length}');
    if (code.length < 6) {
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
    _clearOtp();
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

  String get _otpCode => _otpControllers.map((item) => item.text).join();

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes.first.requestFocus();
  }

  void _handleOtpChanged(String value, int index) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    if (value.length > 1) {
      _pasteOtp(value);
      return;
    }
    if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (_otpCode.length == 6) {
      _otpFocusNodes[index].unfocus();
    }
  }

  void _pasteOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].text = i < digits.length ? digits[i] : '';
    }
    final nextIndex = digits.length >= 6 ? 5 : digits.length;
    _otpFocusNodes[nextIndex.clamp(0, 5)].requestFocus();
    if (digits.length >= 6) _otpFocusNodes.last.unfocus();
  }

  KeyEventResult _handleOtpKey(FocusNode node, KeyEvent event, int index) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace ||
        _otpControllers[index].text.isNotEmpty ||
        index == 0) {
      return KeyEventResult.ignored;
    }
    _otpFocusNodes[index - 1].requestFocus();
    _otpControllers[index - 1].clear();
    return KeyEventResult.handled;
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
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: th.subtleBackground,
              gradient: th.isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryColor.withValues(alpha: 0.06),
                        th.subtleBackground,
                        th.subtleBackground,
                      ],
                    ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide
                            ? AppDesign.space2XL
                            : AppDesign.spaceLG,
                        vertical: isWide ? 46 : AppDesign.spaceXL,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: _OtpVerificationCard(
                            th: th,
                            l10n: l10n,
                            phoneNumber: _result.phoneNumber,
                            errorMessage: _errorMessage,
                            seconds: _seconds,
                            isLoading: _viewModel.isLoading,
                            isVerifying: _isVerifying,
                            controllers: _otpControllers,
                            focusNodes: _otpFocusNodes,
                            onChanged: _handleOtpChanged,
                            onKeyEvent: _handleOtpKey,
                            onVerify: _verify,
                            onResend: _resend,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OtpVerificationCard extends StatelessWidget {
  const _OtpVerificationCard({
    required this.th,
    required this.l10n,
    required this.phoneNumber,
    required this.errorMessage,
    required this.seconds,
    required this.isLoading,
    required this.isVerifying,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
    required this.onVerify,
    required this.onResend,
  });

  final ThemeHelper th;
  final AppLocalizations l10n;
  final String phoneNumber;
  final String? errorMessage;
  final int seconds;
  final bool isLoading;
  final bool isVerifying;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onChanged;
  final KeyEventResult Function(FocusNode node, KeyEvent event, int index)
  onKeyEvent;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 760;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? AppDesign.space2XL : AppDesign.spaceXL),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(isWide ? 30 : 24),
        border: Border.all(color: th.borderColor),
        boxShadow: th.isDark ? null : AppDesign.shadowLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _OtpHero(th: th),
          const SizedBox(height: AppDesign.spaceXL),
          Text(
            l10n.t('otpSubtitle'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: th.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDesign.spaceSM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spaceLG,
              vertical: AppDesign.spaceMD,
            ),
            decoration: BoxDecoration(
              color: th.tintBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              phoneNumber,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: th.textPrimary,
                fontWeight: AppFontWeights.extraBold,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.space2XL),
          _OtpBoxes(
            controllers: controllers,
            focusNodes: focusNodes,
            onChanged: onChanged,
            onKeyEvent: onKeyEvent,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppDesign.spaceLG),
            AuthErrorMessage(message: errorMessage!),
          ],
          const SizedBox(height: AppDesign.space2XL),
          GradientButton(
            label: l10n.t('verifyLogin'),
            icon: Icons.login_rounded,
            isLoading: isLoading || isVerifying,
            onPressed: isVerifying ? null : onVerify,
          ),
          const SizedBox(height: AppDesign.spaceLG),
          Center(
            child: TextButton.icon(
              onPressed: seconds == 0 && !isLoading ? onResend : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                seconds == 0
                    ? l10n.t('resendOtp')
                    : '${l10n.t('resendIn')} $seconds s',
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spaceSM),
          _OtpSecurityNote(th: th),
        ],
      ),
    );
  }
}

class _OtpHero extends StatelessWidget {
  const _OtpHero({required this.th});

  final ThemeHelper th;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        height: 92,
        width: 92,
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 66,
              width: 66,
              decoration: BoxDecoration(
                color: th.cardBackground,
                shape: BoxShape.circle,
                boxShadow: th.isDark ? null : AppDesign.shadowSM,
              ),
            ),
            Icon(Icons.verified_user_rounded, size: 42, color: th.primary),
          ],
        ),
      ),
    );
  }
}

class _OtpSecurityNote extends StatelessWidget {
  const _OtpSecurityNote({required this.th});

  final ThemeHelper th;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, size: 16, color: th.textSecondary),
        const SizedBox(width: AppDesign.spaceSM),
        Flexible(
          child: Text(
            'This code keeps your driver account secure.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: th.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String value, int index) onChanged;
  final KeyEventResult Function(FocusNode node, KeyEvent event, int index)
  onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 520.0;
        final boxSize = ((available - 50) / controllers.length)
            .clamp(46.0, 64.0)
            .toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(controllers.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == controllers.length - 1 ? 0 : 10,
              ),
              child: SizedBox(
                width: boxSize,
                child: Focus(
                  onKeyEvent: (node, event) => onKeyEvent(node, event, index),
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textInputAction: index == controllers.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.headline3.copyWith(
                      fontSize: 24,
                      color: th.textPrimary,
                      fontWeight: AppFontWeights.extraBold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: th.inputFill,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radiusLG),
                        borderSide: BorderSide(color: th.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radiusLG),
                        borderSide: BorderSide(color: th.primary, width: 1.6),
                      ),
                    ),
                    onChanged: (value) => onChanged(value, index),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
