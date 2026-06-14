import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../widgets/common/auth_error_message.dart';
import '../../widgets/common/country_code_picker.dart';
import '../../widgets/common/professional_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _viewModel = AuthViewModel();
  String _selectedCountryCode = '+94';
  String? _errorMessage;

  @override
  void dispose() {
    _phone.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context);
    debugPrint('[DriverLoginPage._sendOtp] pressed');
    debugPrint('[DriverLoginPage._sendOtp] raw local phone: ${_phone.text}');
    debugPrint(
      '[DriverLoginPage._sendOtp] country code: $_selectedCountryCode',
    );
    debugPrint('[DriverLoginPage._sendOtp] full phone: $_fullPhoneNumber');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[DriverLoginPage._sendOtp] form validation failed');
      return;
    }
    setState(() => _errorMessage = null);
    HapticFeedback.lightImpact();
    final result = await _viewModel.startOtpLogin(_fullPhoneNumber);
    if (!mounted) return;
    if (result == null) {
      debugPrint(
        '[DriverLoginPage._sendOtp] failed errorCode=${_viewModel.errorCode}',
      );
      final message = l10n.authErrorMessage(
        _viewModel.errorCode,
        fallbackKey: 'otpFailed',
      );
      setState(() => _errorMessage = message);
      _showSnack(message);
      return;
    }
    debugPrint(
      '[DriverLoginPage._sendOtp] success verificationId=${result.verificationId}, phone=${result.phoneNumber}, driverId=${result.driver.id}',
    );
    Navigator.pushNamed(context, AppRoutes.otp, arguments: result);
  }

  String get _fullPhoneNumber {
    var localNumber = _phone.text.trim();
    if (localNumber.startsWith('0')) localNumber = localNumber.substring(1);
    return '$_selectedCountryCode$localNumber';
  }

  void _showSnack(String message) {
    debugPrint('[DriverLoginPage._showSnack] $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryDark,
                  Color(0xFF1E3A8A),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 860;
                  if (wide) {
                    return Padding(
                      padding: const EdgeInsets.all(38),
                      child: Row(
                        children: [
                          Expanded(child: _LoginBrandPanel(l10n: l10n)),
                          const SizedBox(width: 36),
                          SizedBox(
                            width: 500,
                            child: _LoginFormPanel(
                              th: th,
                              l10n: l10n,
                              formKey: _formKey,
                              phone: _phone,
                              selectedCountryCode: _selectedCountryCode,
                              errorMessage: _errorMessage,
                              isLoading: _viewModel.isLoading,
                              onCountryCodeChanged: (code) => setState(() {
                                _selectedCountryCode = code;
                                _errorMessage = null;
                              }),
                              onPhoneChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                              onSubmit: _sendOtp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.40,
                        child: _LoginBrandPanel(l10n: l10n, compact: true),
                      ),
                      Expanded(
                        child: _LoginFormPanel(
                          th: th,
                          l10n: l10n,
                          formKey: _formKey,
                          phone: _phone,
                          selectedCountryCode: _selectedCountryCode,
                          errorMessage: _errorMessage,
                          isLoading: _viewModel.isLoading,
                          onCountryCodeChanged: (code) => setState(() {
                            _selectedCountryCode = code;
                            _errorMessage = null;
                          }),
                          onPhoneChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                          onSubmit: _sendOtp,
                          mobile: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 112.0 : 96.0;
    return Container(
      padding: EdgeInsets.all(compact ? 0 : 42),
      decoration: compact
          ? null
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.20),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: compact
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 30 : 28),
              boxShadow: AppDesign.shadowLG,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 24 : 22),
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
          const SizedBox(height: AppDesign.spaceXL),
          Text(
            l10n.t('loginTitle'),
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              fontSize: compact ? 34 : 48,
              height: 1.05,
              fontWeight: AppFontWeights.extraBold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDesign.spaceSM),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              l10n.t('loginSubtitle'),
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 34),
            const _LoginTrustStrip(),
          ],
        ],
      ),
    );
  }
}

class _LoginTrustStrip extends StatelessWidget {
  const _LoginTrustStrip();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _LoginTrustPill(
          icon: Icons.verified_user_rounded,
          label: 'Admin verified',
        ),
        _LoginTrustPill(icon: Icons.lock_rounded, label: 'Secure OTP login'),
        _LoginTrustPill(icon: Icons.dashboard_rounded, label: 'Driver console'),
      ],
    );
  }
}

class _LoginTrustPill extends StatelessWidget {
  const _LoginTrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: AppFontWeights.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.th,
    required this.l10n,
    required this.formKey,
    required this.phone,
    required this.selectedCountryCode,
    required this.errorMessage,
    required this.isLoading,
    required this.onCountryCodeChanged,
    required this.onPhoneChanged,
    required this.onSubmit,
    this.mobile = false,
  });

  final ThemeHelper th;
  final AppLocalizations l10n;
  final GlobalKey<FormState> formKey;
  final TextEditingController phone;
  final String selectedCountryCode;
  final String? errorMessage;
  final bool isLoading;
  final ValueChanged<String> onCountryCodeChanged;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSubmit;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final titleRow = mobile
        ? null
        : Row(
            children: [
              Container(
                height: 52,
                width: 52,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in to dashboard',
                      style: AppTextStyles.headline3.copyWith(
                        color: th.textPrimary,
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SafeDriver Driver App',
                      style: AppTextStyles.caption.copyWith(
                        color: th.textSecondary,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? AppDesign.spaceXL : 28),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(mobile ? 32 : 28),
        boxShadow: mobile ? null : AppDesign.shadowLG,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (titleRow != null)
                titleRow
              else
                Text(
                  'Sign in to dashboard',
                  style: AppTextStyles.headline3.copyWith(
                    color: th.textPrimary,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered driver phone number to continue.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: th.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDesign.space2XL),
              PhoneNumberField(
                controller: phone,
                selectedCountryCode: selectedCountryCode,
                onCountryCodeChanged: onCountryCodeChanged,
                labelText: l10n.t('phoneNumber'),
                validator: (value) {
                  if (value == null || value.trim().length < 9) {
                    return l10n.t('phoneRequired');
                  }
                  return null;
                },
                onChanged: onPhoneChanged,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppDesign.spaceLG),
                AuthErrorMessage(message: errorMessage!),
              ],
              const SizedBox(height: AppDesign.space2XL),
              GradientButton(
                label: l10n.t('sendOtp'),
                icon: Icons.sms_rounded,
                isLoading: isLoading,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
