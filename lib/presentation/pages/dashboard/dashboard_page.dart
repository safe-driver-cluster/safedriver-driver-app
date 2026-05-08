import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_driver_driver_app/l10n/app_localizations.dart';

import '../../../providers/language_provider.dart';
import '../../../providers/theme_provider.dart';
import '../alerts/alerts_page.dart';
import '../attendance/attendance_page.dart';
import '../buses/buses_page.dart';
import '../complaint/complaint_page.dart';
import '../map/map_page.dart';
import '../profile/profile_page.dart';
import '../ratings/ratings_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  void _navigateToPage(BuildContext context, int index) {
    Widget? page;

    switch (index) {
      case 0: // My Attendance
        page = const AttendancePage();
        break;
      case 1: // My Buses
        page = const BusesPage();
        break;
      case 2: // My Alerts
        page = const AlertsPage();
        break;
      case 3: // Ratings
        page = const RatingsPage();
        break;
      case 4: // Complain
        page = const ComplaintPage();
        break;
      case 5: // My Profile
        page = const ProfilePage();
        break;
      case 6: // Map
        page = const MapPage();
        break;
      case 7: // Help & Support
        _showHelpDialog(context);
        return;
    }

    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SafeDriver Driver App',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('For assistance, please contact:'),
              SizedBox(height: 8),
              Text('📞 Support: +94 11 234 5678'),
              Text('📧 Email: support@safedriver.lk'),
              SizedBox(height: 16),
              Text('Emergency Hotline: 1919'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    final List<Map<String, dynamic>> menuItems = [
      {
        'title': l10n.myAttendance,
        'icon': Icons.calendar_today,
        'color': Colors.orange
      },
      {
        'title': l10n.myBuses,
        'icon': Icons.directions_bus,
        'color': Colors.blue
      },
      {
        'title': l10n.myAlerts,
        'icon': Icons.notifications_active,
        'color': Colors.red
      },
      {'title': l10n.ratings, 'icon': Icons.star, 'color': Colors.amber},
      {
        'title': l10n.complain,
        'icon': Icons.report_problem,
        'color': Colors.purple
      },
      {'title': l10n.myProfile, 'icon': Icons.person, 'color': Colors.teal},
      {'title': l10n.map, 'icon': Icons.map, 'color': Colors.green},
      {'title': l10n.helpSupport, 'icon': Icons.help, 'color': Colors.blueGrey},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language),
            onSelected: (language) {
              ref
                  .read(languageControllerProvider.notifier)
                  .changeLanguage(language);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: AppLanguage.english, child: Text('English')),
              const PopupMenuItem(
                  value: AppLanguage.sinhala, child: Text('සිංහල')),
              const PopupMenuItem(
                  value: AppLanguage.tamil, child: Text('தமிழ்')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _navigateToPage(context, index),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 40, color: item['color']),
                    const SizedBox(height: 12),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
