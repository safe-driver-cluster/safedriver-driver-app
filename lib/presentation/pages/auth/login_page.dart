import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../viewmodels/auth_view_model.dart';
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

  @override
  void dispose() {
    _phone.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    final result = await _viewModel.startOtpLogin(_fullPhoneNumber);
    if (!mounted) return;
    if (result == null) {
      _showSnack(
        _viewModel.errorCode == 'driver_not_found'
            ? l10n.t('driverNotFound')
            : l10n.t('otpFailed'),
      );
      return;
    }
    Navigator.pushNamed(context, AppRoutes.otp, arguments: result);
  }

  String get _fullPhoneNumber {
    var localNumber = _phone.text.trim();
    if (localNumber.startsWith('0')) localNumber = localNumber.substring(1);
    return '$_selectedCountryCode$localNumber';
  }

  void _showSnack(String message) {
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryDark,
                  Color(0xFF1E3A8A),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: AppDesign.shadowLG,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceXL),
                        Text(
                          l10n.t('loginTitle'),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceSM),
                        Text(
                          l10n.t('loginSubtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDesign.spaceXL),
                      decoration: BoxDecoration(
                        color: th.cardBackground,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PhoneNumberField(
                                controller: _phone,
                                selectedCountryCode: _selectedCountryCode,
                                onCountryCodeChanged: (code) =>
                                    setState(() => _selectedCountryCode = code),
                                labelText: l10n.t('phoneNumber'),
                                validator: (value) {
                                  if (value == null || value.trim().length < 9)
                                    return l10n.t('phoneRequired');
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDesign.space2XL),
                              GradientButton(
                                label: l10n.t('sendOtp'),
                                icon: Icons.sms_rounded,
                                isLoading: _viewModel.isLoading,
                                onPressed: _sendOtp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
