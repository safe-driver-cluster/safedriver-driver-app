import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/models/driver_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  final _vm = DriverDashboardViewModel();
  Stream<List<DriverBus>>? _busStream;
  String? _streamDriverId;
  int _refreshKey = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = AppScope.of(context).driver;
    if (driver != null && (_busStream == null || _streamDriverId != driver.id)) {
      _setBusStream(driver);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _setBusStream(DriverProfile driver) {
    _streamDriverId = driver.id;
    _busStream = _vm.buses(driver);
  }

  Future<void> _refresh() async {
    final driver = AppScope.of(context).driver!;
    setState(() {
      _refreshKey++;
      _setBusStream(driver);
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final body = StreamBuilder(
      key: ValueKey(_refreshKey),
      stream: _busStream ?? _vm.buses(driver),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: const ScrollableEmptyState(
              message: 'Could not load buses.',
              icon: Icons.error_outline_rounded,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ScrollableEmptyState(
              message: l10n.t('noAssignedBuses'),
              icon: Icons.directions_bus_filled_rounded,
            ),
          );
        }
        if (kIsWeb && MediaQuery.sizeOf(context).width >= 900) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _WebBusesView(
              buses: data,
              driver: driver,
              routeLabel: _routeLabel,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final bus = data[i];
              final th = ThemeHelper.of(context);
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
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.12,
                            ),
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
                                style: AppTextStyles.caption.copyWith(
                                  color: th.textSecondary,
                                ),
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
                        color: th.tintBackground,
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
          ),
        );
      },
    );
    if (!widget.showAppBar) return body;
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

class _WebBusesView extends StatelessWidget {
  const _WebBusesView({
    required this.buses,
    required this.driver,
    required this.routeLabel,
  });

  final List<DriverBus> buses;
  final DriverProfile driver;
  final String Function(DriverBus bus, String driverRoute) routeLabel;

  @override
  Widget build(BuildContext context) {
    final activeCount = buses
        .where(
          (bus) => bus.status.toLowerCase().replaceAll('_', ' ') == 'active',
        )
        .length;
    final trackedCount = buses
        .where((bus) => bus.latitude != null && bus.longitude != null)
        .length;
    final avgSafety = buses
        .where((bus) => bus.safetyScore > 0)
        .map((bus) => bus.safetyScore)
        .toList();
    final safetyText = avgSafety.isEmpty
        ? '-'
        : (avgSafety.reduce((a, b) => a + b) / avgSafety.length)
              .toStringAsFixed(0);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _WebBusMetric(
                        label: 'Assigned buses',
                        value: buses.length.toString(),
                        icon: Icons.directions_bus_rounded,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WebBusMetric(
                        label: 'Active',
                        value: activeCount.toString(),
                        icon: Icons.radio_button_checked_rounded,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WebBusMetric(
                        label: 'Tracked',
                        value: trackedCount.toString(),
                        icon: Icons.gps_fixed_rounded,
                        color: AppColors.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WebBusMetric(
                        label: 'Safety avg',
                        value: safetyText,
                        icon: Icons.shield_rounded,
                        color: AppColors.warningColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _WebSectionTitle(title: 'Assigned fleet', count: buses.length),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.crossAxisExtent >= 1280 ? 2 : 1;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: columns == 2 ? 2.65 : 4.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _WebBusCard(
                    bus: buses[index],
                    driver: driver,
                    routeText: routeLabel(buses[index], driver.currentRoute),
                  ),
                  childCount: buses.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WebBusMetric extends StatelessWidget {
  const _WebBusMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      height: 96,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.borderColor),
        boxShadow: th.isDark ? null : AppDesign.shadowSM,
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline3.copyWith(
                    color: th.textPrimary,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: th.textSecondary,
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

class _WebSectionTitle extends StatelessWidget {
  const _WebSectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            color: th.textPrimary,
            fontWeight: AppFontWeights.extraBold,
          ),
        ),
        const SizedBox(width: 10),
        _StatusPill(label: '$count total'),
      ],
    );
  }
}

class _WebBusCard extends StatelessWidget {
  const _WebBusCard({
    required this.bus,
    required this.driver,
    required this.routeText,
  });

  final DriverBus bus;
  final DriverProfile driver;
  final String routeText;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: th.borderColor),
        boxShadow: th.isDark ? null : AppDesign.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.11),
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
                    Text(
                      bus.busNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: th.textPrimary,
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      routeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: th.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(label: bus.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DetailChip(
                  icon: Icons.directions_bus_filled_rounded,
                  label: 'Model',
                  value: bus.model,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailChip(
                  icon: Icons.alt_route_rounded,
                  label: 'Route ID',
                  value: bus.routeId,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DetailChip(
                  icon: Icons.business_rounded,
                  label: 'Depot',
                  value: bus.locationDepot,
                ),
              ),
            ],
          ),
          const Spacer(),
          _DetailRow(
            icon: Icons.person_rounded,
            label: 'Assigned driver',
            value: bus.driverName.isEmpty ? driver.fullName : bus.driverName,
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
    final th = ThemeHelper.of(context);
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: 154,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: th.subtleBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: th.borderColor),
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
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: th.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: th.textPrimary,
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
    final th = ThemeHelper.of(context);
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: th.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label  ',
                style: AppTextStyles.caption.copyWith(color: th.textSecondary),
                children: [
                  TextSpan(
                    text: value,
                    style: AppTextStyles.caption.copyWith(
                      color: th.textPrimary,
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
