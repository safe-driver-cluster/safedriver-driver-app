import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/professional_widgets.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('support'))),
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceLG),
        children: [
          _SupportTile(
            icon: Icons.admin_panel_settings_rounded,
            title: l10n.t('contactAdmin'),
          ),
          _SupportTile(icon: Icons.help_outline_rounded, title: l10n.t('faqs')),
          _SupportTile(
            icon: Icons.emergency_rounded,
            title: l10n.t('emergencyHelp'),
          ),
          _SupportTile(
            icon: Icons.alt_route_rounded,
            title: l10n.t('routeGuidance'),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}
