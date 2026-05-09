import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/driver_models.dart';

class AppController extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;
  DriverProfile? _driver;
  bool _onboardingComplete = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  DriverProfile? get driver => _driver;
  bool get onboardingComplete => _onboardingComplete;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = Locale(prefs.getString('locale') ?? 'en');
    _themeMode = prefs.getBool('darkMode') == true
        ? ThemeMode.dark
        : ThemeMode.light;
    _onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', mode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);
    notifyListeners();
  }

  void setDriver(DriverProfile driver) {
    _driver = driver;
    notifyListeners();
  }

  void clearDriver() {
    _driver = null;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
