import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';
import 'package:safe_driver_driver_app/screens/auth/login_screen.dart';
import 'package:safe_driver_driver_app/screens/settings/settings_screen.dart';

class DrawerWidget extends ConsumerWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final authService = ref.read(authServiceProvider);
    final user = authService.getCurrentUser();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.phoneNumber ?? 'Driver',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(locale!.myProfile),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: Text(locale.map),
            onTap: () {
              Navigator.pop(context);
              // Navigate to map
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning),
            title: Text(locale.complaints),
            onTap: () {
              Navigator.pop(context);
              // Navigate to complaints
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(locale.helpSupport),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help & support
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(locale.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(locale.about),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context, locale);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(locale.logout),
            onTap: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations locale) {
    showAboutDialog(
      context: context,
      applicationName: 'SafeDriver - Driver',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 SafeDriver. All rights reserved.',
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'SafeDriver is a comprehensive driver management application designed to enhance transportation safety and efficiency.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
