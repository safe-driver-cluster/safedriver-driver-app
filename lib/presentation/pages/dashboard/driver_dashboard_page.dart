import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/dashboard/dashboard_action_tile.dart';
import '../alerts/alerts_page.dart';
import '../attendance/attendance_page.dart';
import '../buses/buses_page.dart';
import '../complaints/complaint_page.dart';
import '../complaints/complaint_history_page.dart';
import '../maps/map_page.dart';
import '../profile/profile_page.dart';
import '../ratings/ratings_page.dart';
import '../settings/settings_page.dart';
import '../support/support_page.dart';
import '../support/support_history_page.dart';
import '../../widgets/common/logout_confirmation_dialog.dart';
import '../../widgets/common/professional_widgets.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  late int _index = widget.initialIndex.clamp(0, 3).toInt();
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
    final shouldLogout = await showLogoutConfirmationDialog(
      context: context,
      title: l10n.t('logoutConfirmTitle'),
      message: l10n.t('logoutConfirmMessage'),
      cancelLabel: l10n.t('cancel'),
      logoutLabel: l10n.t('logout'),
    );
    if (!shouldLogout) return;
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
      showBack: true,
      selectedNavIndex: _index,
      onNavSelected: (value) => setState(() => _index = value),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        final padding = wide
            ? const EdgeInsets.fromLTRB(32, 26, 28, 32)
            : const EdgeInsets.fromLTRB(14, 14, 14, 20);
        return ListView(
          padding: padding,
          children: [
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 420,
                      child: _DriverOverviewCard(driver: driver, l10n: l10n),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _DashboardCommandCard(driver: driver, l10n: l10n),
                    ),
                  ],
                ),
              )
            else
              _DriverOverviewCard(driver: driver, l10n: l10n),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick actions',
                    style: AppTextStyles.title.copyWith(
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                ),
                if (wide)
                  Text(
                    'Choose a workspace to continue',
                    style: AppTextStyles.caption.copyWith(
                      color: ThemeHelper.of(context).textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _ActionGrid(driver: driver, l10n: l10n, onOpen: onOpen),
          ],
        );
      },
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.driver,
    required this.l10n,
    required this.onOpen,
  });

  final dynamic driver;
  final AppLocalizations l10n;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1300
            ? 5
            : width >= 980
            ? 4
            : width >= 680
            ? 3
            : 2;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: width >= 1300
              ? 2.1
              : width >= 980
              ? 1.95
              : width >= 680
              ? 1.7
              : 1.58,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
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
              title: 'Complaint history',
              subtitle: 'Your submitted complaints',
              icon: Icons.assignment_rounded,
              color: AppColors.dangerColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintHistoryPage()),
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
              title: 'Support history',
              subtitle: 'Your support requests',
              icon: Icons.forum_rounded,
              color: AppColors.primaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportHistoryPage()),
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
        );
      },
    );
  }
}

class _DashboardCommandCard extends StatelessWidget {
  const _DashboardCommandCard({required this.driver, required this.l10n});

  final dynamic driver;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppDesign.shadowLG,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome back, ${driver.fullName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headline2.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  driver.currentRoute.isEmpty
                      ? l10n.t('routeGuidance')
                      : driver.currentRoute,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CommandPill(
                      icon: Icons.directions_bus_rounded,
                      label: driver.currentBusId.isEmpty
                          ? l10n.t('noAssignedBuses')
                          : driver.currentBusId,
                    ),
                    _CommandPill(
                      icon: Icons.star_rounded,
                      label: '${driver.rating.toStringAsFixed(1)} rating',
                    ),
                    _CommandPill(
                      icon: Icons.radio_button_checked_rounded,
                      label: driver.isOnDuty
                          ? l10n.t('active')
                          : l10n.t('inactive'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Icon(
            Icons.route_rounded,
            color: Colors.white.withValues(alpha: 0.22),
            size: 130,
          ),
        ],
      ),
    );
  }
}

class _CommandPill extends StatelessWidget {
  const _CommandPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: AppFontWeights.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverOverviewCard extends StatelessWidget {
  const _DriverOverviewCard({required this.driver, required this.l10n});

  final dynamic driver;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final statusColor = driver.isOnDuty
        ? AppColors.secondaryColor
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: th.borderColor),
        boxShadow: th.isDark ? null : AppDesign.shadowSM,
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
                        color: th.textPrimary,
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
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: th.subtleBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: th.borderColor),
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
                          color: th.textPrimary,
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
                          color: th.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: th.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
