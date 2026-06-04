import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../data/models/driver_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class BusesPage extends StatelessWidget {
  const BusesPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final vm = DriverDashboardViewModel();
    final body = StreamBuilder(
      stream: vm.buses(driver),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (snapshot.hasError) {
          return const EmptyState(
            message: 'Could not load buses.',
            icon: Icons.error_outline_rounded,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.isEmpty) {
          return EmptyState(
            message: l10n.t('noAssignedBuses'),
            icon: Icons.directions_bus_filled_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final bus = data[i];
            return SoftCard(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bus.busNumber, style: AppTextStyles.title),
                            const SizedBox(height: 2),
                            Text(
                              _routeLabel(bus, driver.currentRoute),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(label: bus.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_rounded,
                          size: 16,
                          color: AppColors.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bus.registration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: AppFontWeights.bold,
                            ),
                          ),
                        ),
                        if (bus.safetyScore > 0) ...[
                          const Icon(
                            Icons.shield_rounded,
                            size: 16,
                            color: AppColors.secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bus.safetyScore.toStringAsFixed(0),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.secondaryColor,
                              fontWeight: AppFontWeights.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _DetailChip(
                        icon: Icons.directions_bus_filled_rounded,
                        label: 'Model',
                        value: bus.model,
                      ),
                      _DetailChip(
                        icon: Icons.alt_route_rounded,
                        label: 'Route ID',
                        value: bus.routeId,
                      ),
                      _DetailChip(
                        icon: Icons.business_rounded,
                        label: 'Depot',
                        value: bus.locationDepot,
                      ),
                      _DetailChip(
                        icon: Icons.calendar_month_rounded,
                        label: 'Year',
                        value: bus.year == 0 ? '' : bus.year.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Assigned driver',
                    value: bus.driverName.isEmpty
                        ? driver.fullName
                        : bus.driverName,
                  ),
                  _DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Current location',
                    value: bus.locationAddress.isEmpty
                        ? bus.locationDepot
                        : bus.locationAddress,
                  ),
                  _DetailRow(
                    icon: Icons.sensors_rounded,
                    label: 'Device ID',
                    value: bus.deviceId,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!showAppBar) return body;
    return DriverPageShell(
      title: l10n.t('myBuses'),
      selectedNavIndex: 1,
      body: body,
    );
  }

  String _routeLabel(DriverBus bus, String driverRoute) {
    if (bus.routeNumber.isNotEmpty && bus.routeId.isNotEmpty) {
      return '${bus.routeNumber} - ${bus.routeId}';
    }
    if (bus.routeNumber.isNotEmpty) return bus.routeNumber;
    if (driverRoute.isNotEmpty) return driverRoute;
    if (bus.routeId.isNotEmpty) return bus.routeId;
    return 'Assigned vehicle';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase().replaceAll('_', ' ');
    final active = normalized == 'active' || normalized == 'on duty';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (active ? AppColors.secondaryColor : AppColors.textSecondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'unknown' : normalized,
        style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.secondaryColor : AppColors.textSecondary,
          fontWeight: AppFontWeights.bold,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: 154,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardTint),
      ),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppFontWeights.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label  ',
                style: AppTextStyles.caption,
                children: [
                  TextSpan(
                    text: value,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
