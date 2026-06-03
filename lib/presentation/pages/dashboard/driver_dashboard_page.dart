import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/dashboard/dashboard_action_tile.dart';
import '../../widgets/dashboard/dashboard_metric.dart';
import '../alerts/alerts_page.dart';
import '../attendance/attendance_page.dart';
import '../buses/buses_page.dart';
import '../complaints/complaint_page.dart';
import '../maps/map_page.dart';
import '../profile/profile_page.dart';
import '../ratings/ratings_page.dart';
import '../settings/settings_page.dart';
import '../support/support_page.dart';
import '../../widgets/common/professional_widgets.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  int _index = 0;
  bool _refreshingDriver = false;

  Future<void> _refreshDriverProfile(String driverId) async {
    if (_refreshingDriver) return;
    _refreshingDriver = true;
    final driver = await DriverAuthService().findDriverById(driverId);
    if (!mounted || driver == null) {
      _refreshingDriver = false;
      return;
    }
    AppScope.of(context).setDriver(driver);
    _refreshingDriver = false;
  }

  Future<void> _confirmLogout() async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('logoutConfirmTitle')),
        content: Text(l10n.t('logoutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('logout')),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    await DriverAuthService().signOut();
    app.clearDriver();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final driver = app.driver;
    final l10n = AppLocalizations.of(context);
    if (driver == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (_) => false,
            ),
            child: Text(l10n.t('loginTitle')),
          ),
        ),
      );
    }

    if (driver.currentBusId.isEmpty) {
      _refreshDriverProfile(driver.id);
    }

    final pages = [
      _DashboardHome(onOpen: (page) => setState(() => _index = page)),
      const BusesPage(showAppBar: false),
      const AlertsPage(showAppBar: false),
      const ProfilePage(showAppBar: false),
    ];

    final titleKey = _index == 0
        ? 'dashboard'
        : _index == 1
        ? 'myBuses'
        : _index == 2
        ? 'myAlerts'
        : 'profile';

    return DriverPageShell(
      title: l10n.t(titleKey),
      subtitle: _index == 0 ? l10n.t('tagline') : null,
      showBack: false,
      actions: [
        DriverIconButton(
          tooltip: l10n.t('settings'),
          icon: Icons.settings_rounded,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        DriverIconButton(
          tooltip: l10n.t('logout'),
          icon: Icons.logout_rounded,
          onPressed: _confirmLogout,
        ),
      ],
      body: pages[_index],
      bottomNavigationBar: DriverBottomNavBar(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
        items: [
          DriverNavItem(
            icon: Icons.dashboard_rounded,
            label: l10n.t('dashboard'),
          ),
          DriverNavItem(
            icon: Icons.directions_bus_rounded,
            label: l10n.t('myBuses'),
          ),
          DriverNavItem(
            icon: Icons.notifications_rounded,
            label: l10n.t('myAlerts'),
          ),
          DriverNavItem(icon: Icons.person_rounded, label: l10n.t('profile')),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({required this.onOpen});

  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final driver = AppScope.of(context).driver!;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 104),
      children: [
        _DriverOverviewCard(driver: driver, l10n: l10n),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardMetric(
                label: l10n.t('safetyScore'),
                value: driver.safetyScore.toStringAsFixed(0),
                icon: Icons.shield_rounded,
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardMetric(
                label: l10n.t('passengerRating'),
                value: driver.rating.toStringAsFixed(1),
                icon: Icons.star_rounded,
                color: AppColors.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Quick actions',
          style: AppTextStyles.title.copyWith(
            fontWeight: AppFontWeights.extraBold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.58,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            DashboardActionTile(
              title: l10n.t('myAttendance'),
              subtitle: l10n.t('today'),
              icon: Icons.event_available_rounded,
              color: AppColors.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendancePage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('myBuses'),
              subtitle: driver.currentBusId.isEmpty
                  ? l10n.t('noAssignedBuses')
                  : driver.currentBusId,
              icon: Icons.directions_bus_rounded,
              color: AppColors.primaryColor,
              onTap: () => onOpen(1),
            ),
            DashboardActionTile(
              title: l10n.t('myAlerts'),
              subtitle: 'Safety updates',
              icon: Icons.notifications_rounded,
              color: AppColors.dangerColor,
              onTap: () => onOpen(2),
            ),
            DashboardActionTile(
              title: l10n.t('ratings'),
              subtitle: '${driver.rating.toStringAsFixed(1)} average',
              icon: Icons.star_rate_rounded,
              color: AppColors.warningColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RatingsPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('complaints'),
              subtitle: l10n.t('submitComplaint'),
              icon: Icons.report_rounded,
              color: AppColors.secondaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('map'),
              subtitle: driver.currentRoute.isEmpty
                  ? l10n.t('routeGuidance')
                  : driver.currentRoute,
              icon: Icons.map_rounded,
              color: AppColors.primaryDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('support'),
              subtitle: l10n.t('contactAdmin'),
              icon: Icons.support_agent_rounded,
              color: AppColors.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('settings'),
              subtitle: l10n.t('language'),
              icon: Icons.tune_rounded,
              color: Colors.grey,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DriverOverviewCard extends StatelessWidget {
  const _DriverOverviewCard({required this.driver, required this.l10n});

  final dynamic driver;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final statusColor = driver.isOnDuty
        ? AppColors.secondaryColor
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppDesign.shadowSM,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.cardTint,
                  backgroundImage: driver.profileImageUrl == null
                      ? null
                      : NetworkImage(driver.profileImageUrl!),
                  child: driver.profileImageUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryDark,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          driver.isOnDuty
                              ? l10n.t('active')
                              : l10n.t('inactive'),
                          style: AppTextStyles.caption.copyWith(
                            color: statusColor,
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ScoreBadge(
                label: l10n.t('safetyScore'),
                value: driver.safetyScore.toStringAsFixed(0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.currentBusId.isEmpty
                            ? l10n.t('noAssignedBuses')
                            : driver.currentBusId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: AppFontWeights.extraBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driver.currentRoute.isEmpty
                            ? l10n.t('routeGuidance')
                            : driver.currentRoute,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              color: AppColors.secondaryColor,
              fontWeight: AppFontWeights.extraBold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
