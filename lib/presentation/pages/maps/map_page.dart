import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('map'))),
      body: Padding(
        padding: const EdgeInsets.all(AppDesign.spaceLG),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_rounded, size: 72),
              const SizedBox(height: 16),
              Text(l10n.t('routeGuidance'), style: AppTextStyles.headline3),
              const SizedBox(height: 8),
              Text(driver.currentRoute.isEmpty ? '-' : driver.currentRoute),
            ],
          ),
        ),
      ),
    );
  }
}
