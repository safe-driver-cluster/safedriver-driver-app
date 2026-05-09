import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final dark = app.themeMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceLG),
        children: [
          SoftCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.t('darkMode')),
              value: dark,
              onChanged: (value) =>
                  app.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.t('language')),
              trailing: DropdownButton<Locale>(
                value: app.locale,
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('si'), child: Text('සිංහල')),
                  DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
                ],
                onChanged: (value) {
                  if (value != null) app.setLocale(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
