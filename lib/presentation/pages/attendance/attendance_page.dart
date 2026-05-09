import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final vm = DriverDashboardViewModel();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('myAttendance'))),
      body: StreamBuilder(
        stream: vm.attendance(driver.id),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (data.isEmpty)
            return EmptyState(
              message: l10n.t('noAttendance'),
              icon: Icons.event_busy_rounded,
            );
          return ListView.separated(
            padding: const EdgeInsets.all(AppDesign.spaceLG),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final item = data[i];
              return SoftCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_rounded),
                  title: Text(item.status),
                  subtitle: Text(
                    item.checkIn == null
                        ? l10n.t('today')
                        : DateFormat.yMMMd().add_jm().format(item.checkIn!),
                  ),
                  trailing: Text(item.busId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
