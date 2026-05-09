import 'package:flutter/material.dart';

import '../data/services/driver_auth_service.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/otp_page.dart';
import '../presentation/pages/auth/splash_page.dart';
import '../presentation/pages/dashboard/driver_dashboard_page.dart';
import '../presentation/pages/language/language_selection_page.dart';
import '../presentation/pages/onboarding/onboarding_page.dart';

class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const dashboard = '/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _route(const SplashPage());
      case language:
        return _route(const LanguageSelectionPage());
      case onboarding:
        return _route(const OnboardingPage());
      case login:
        return _route(const LoginPage());
      case otp:
        return _route(OtpPage(result: settings.arguments as OtpStartResult));
      case dashboard:
        return _route(const DriverDashboardPage());
      default:
        return _route(const SplashPage());
    }
  }

  static MaterialPageRoute<dynamic> _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
