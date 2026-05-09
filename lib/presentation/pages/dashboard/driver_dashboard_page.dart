import 'package:flutter/material.dart';

import '../../../app/routes.dart';
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

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  int _index = 0;

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

    final pages = [
      _DashboardHome(onOpen: (page) => setState(() => _index = page)),
      const BusesPage(),
      const AlertsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.t(
            _index == 0
                ? 'dashboard'
                : _index == 1
                ? 'myBuses'
                : _index == 2
                ? 'myAlerts'
                : 'profile',
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.t('settings'),
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
          IconButton(
            tooltip: l10n.t('logout'),
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await DriverAuthService().signOut();
              app.clearDriver();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_rounded),
            label: l10n.t('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bus_rounded),
            label: l10n.t('myBuses'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.notifications_rounded),
            label: l10n.t('myAlerts'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: l10n.t('profile'),
          ),
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
      padding: const EdgeInsets.all(AppDesign.spaceLG),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryColor, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: driver.profileImageUrl == null
                    ? null
                    : NetworkImage(driver.profileImageUrl!),
                child: driver.profileImageUrl == null
                    ? const Icon(Icons.person_rounded)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      driver.isOnDuty ? l10n.t('active') : l10n.t('inactive'),
                      style: TextStyle(color: Colors.white.withOpacity(0.82)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            DashboardActionTile(
              title: l10n.t('myAttendance'),
              icon: Icons.event_available_rounded,
              color: AppColors.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendancePage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('myBuses'),
              icon: Icons.directions_bus_rounded,
              color: AppColors.primaryColor,
              onTap: () => onOpen(1),
            ),
            DashboardActionTile(
              title: l10n.t('myAlerts'),
              icon: Icons.notifications_rounded,
              color: AppColors.dangerColor,
              onTap: () => onOpen(2),
            ),
            DashboardActionTile(
              title: l10n.t('ratings'),
              icon: Icons.star_rate_rounded,
              color: AppColors.warningColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RatingsPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('complaints'),
              icon: Icons.report_rounded,
              color: AppColors.secondaryColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('map'),
              icon: Icons.map_rounded,
              color: AppColors.primaryDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('support'),
              icon: Icons.support_agent_rounded,
              color: AppColors.infoColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('settings'),
              icon: Icons.tune_rounded,
              color: Colors.grey,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            DashboardActionTile(
              title: l10n.t('profile'),
              icon: Icons.person_rounded,
              color: AppColors.primaryColor,
              onTap: () => onOpen(3),
            ),
          ],
        ),
      ],
    );
  }
}
