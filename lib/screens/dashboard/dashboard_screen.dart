import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/home_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/attendance_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/buses_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/alerts_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/ratings_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/complaints_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/profile_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/map_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/tabs/help_support_tab.dart';
import 'package:safe_driver_driver_app/screens/dashboard/drawer_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = [
    HomeTab(),
    AttendanceTab(),
    BusesTab(),
    AlertsTab(),
    RatingsTab(),
    ComplaintsTab(),
    ProfileTab(),
    MapTab(),
    HelpSupportTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(locale!.dashboard),
          elevation: 0,
        ),
        drawer: const DrawerWidget(),
        body: _tabs[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: locale.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.check_circle),
              label: locale.myAttendance,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.directions_bus),
              label: locale.myBuses,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications),
              label: locale.myAlerts,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star),
              label: locale.ratings,
            ),
          ],
        ),
      ),
    );
  }
}
