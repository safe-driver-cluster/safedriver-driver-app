import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class RatingsPage extends StatelessWidget {
  const RatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final vm = DriverDashboardViewModel();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('ratings'))),
      body: StreamBuilder(
        stream: vm.feedback(driver.id),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (data.isEmpty)
            return EmptyState(
              message: l10n.t('noRatings'),
              icon: Icons.star_border_rounded,
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
                  title: Text(item.title),
                  subtitle: Text(item.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber),
                      Text('${item.rating}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
