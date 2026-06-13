import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/design_constants.dart';
import '../../../data/models/driver_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _vm = DriverDashboardViewModel();
  Stream<List<AttendanceRecord>>? _attendanceStream;
  String? _streamDriverId;
  int _refreshKey = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = AppScope.of(context).driver;
    if (driver != null &&
        (_attendanceStream == null || _streamDriverId != driver.id)) {
      _setAttendanceStream(driver.id);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _setAttendanceStream(String driverId) {
    _streamDriverId = driverId;
    _attendanceStream = _vm.attendance(driverId);
  }

  Future<void> _refresh() async {
    final driver = AppScope.of(context).driver!;
    setState(() {
      _refreshKey++;
      _setAttendanceStream(driver.id);
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    return DriverPageShell(
      title: l10n.t('myAttendance'),
      body: StreamBuilder(
        key: ValueKey(_refreshKey),
        stream: _attendanceStream ?? _vm.attendance(driver.id),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const ScrollableEmptyState(
                message: 'Could not load attendance.',
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
                message: l10n.t('noAttendance'),
                icon: Icons.event_busy_rounded,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          );
        },
      ),
    );
  }
}
