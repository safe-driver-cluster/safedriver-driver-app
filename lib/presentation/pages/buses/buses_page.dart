import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class BusesPage extends StatelessWidget {
  const BusesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final vm = DriverDashboardViewModel();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('myBuses'))),
      body: StreamBuilder(
        stream: vm.buses(driver),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (data.isEmpty)
            return EmptyState(
              message: l10n.t('noAssignedBuses'),
              icon: Icons.directions_bus_filled_rounded,
            );
          return ListView.separated(
            padding: const EdgeInsets.all(AppDesign.spaceLG),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final bus = data[i];
              return SoftCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_bus_rounded),
                  title: Text(bus.busNumber),
                  subtitle: Text('${bus.routeNumber}  ${bus.registration}'),
                  trailing: Text(bus.status),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
