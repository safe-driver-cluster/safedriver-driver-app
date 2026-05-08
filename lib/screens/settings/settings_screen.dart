import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final isDarkMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale!.settings),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                locale.theme,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: SwitchListTile(
                title: Text(locale.dark),
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 24),
            // Language Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                locale.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildLanguageTile(
                      context,
                      'English',
                      'en',
                      language,
                      ref,
                    ),
                    const Divider(),
                    _buildLanguageTile(
                      context,
                      'සිංහල',
                      'si',
                      language,
                      ref,
                    ),
                    const Divider(),
                    _buildLanguageTile(
                      context,
                      'தமிழ்',
                      'ta',
                      language,
                      ref,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Notifications Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive push notifications'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Alerts'),
                    subtitle: const Text('Receive alerts'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String languageName,
    String languageCode,
    String currentLanguage,
    WidgetRef ref,
  ) {
    final isSelected = currentLanguage == languageCode;
    return ListTile(
      title: Text(languageName),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
          : null,
      onTap: isSelected
          ? null
          : () {
              ref.read(languageProvider.notifier).setLanguage(languageCode);
            },
    );
  }
}
