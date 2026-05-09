import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_driver_driver_app/l10n/app_localizations.dart';

void main() {
  test('localization returns restored app name', () {
    final l10n = AppLocalizations(const Locale('en'));
    expect(l10n.t('appName'), 'SafeDriver Driver');
  });
}
