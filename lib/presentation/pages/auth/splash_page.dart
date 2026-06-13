import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _goNext);
  }

  Future<void> _goNext() async {
    final driver = await DriverAuthService().findDriverForCurrentUser();
    if (!mounted) return;

    final app = AppScope.of(context);
    if (driver != null) {
      app.setDriver(driver);
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      return;
    }

    final route = app.onboardingComplete ? AppRoutes.login : AppRoutes.language;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appTitle = l10n.t('appName');
    final splashTitle = appTitle == 'SafeDriver - Driver App'
        ? 'SafeDriver -\nDriver App'
        : appTitle;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          color: const Color(0xFFF5F6FA),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              child: Column(
                children: [
                  const Spacer(flex: 4),
                  Container(
                    width: 172,
                    height: 172,
                    padding: const EdgeInsets.all(34),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 58),
                  Text(
                    splashTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 44,
                      height: 1.35,
                      fontWeight: AppFontWeights.extraBold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.t('tagline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 20,
                      fontWeight: AppFontWeights.semiBold,
                    ),
                  ),
                  const Spacer(flex: 3),
                  const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Text(
                    '${l10n.t('version')} 1.0.0',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.58),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Powered by SafeDriver Technologies',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.32),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
