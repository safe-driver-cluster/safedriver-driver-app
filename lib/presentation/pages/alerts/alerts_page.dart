import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final vm = DriverDashboardViewModel();
    final body = StreamBuilder(
      stream: vm.alerts(driver.id),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.isEmpty) {
          return EmptyState(
            message: l10n.t('noAlerts'),
            icon: Icons.notifications_off_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDesign.spaceLG),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final alert = data[i];
            return SoftCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning_rounded),
                title: Text(alert.title, style: AppTextStyles.title),
                subtitle: Text(alert.description),
                trailing: _PriorityPill(label: alert.priority),
              ),
            );
          },
        );
      },
    );
    if (!showAppBar) return body;
    return DriverPageShell(title: l10n.t('myAlerts'), body: body);
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}
