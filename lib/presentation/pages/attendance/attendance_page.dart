import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/design_constants.dart';
import '../../../data/models/driver_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../../core/utils/theme_helper.dart';
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                return _AttendanceRow(record: data[i]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final signIn = record.checkIn;
    final signOff = record.checkOut;

    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceMD,
        vertical: AppDesign.spaceMD,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          final dateBlock = _DateBlock(record: record);
          final timeBlock = _TimeBlock(
            label: 'Sign in',
            date: signIn == null ? '--' : DateFormat('dd MMM').format(signIn),
            time: _formatTime(signIn),
          );
          final outBlock = _TimeBlock(
            label: 'Sign off',
            date: signOff == null ? '--' : DateFormat('dd MMM').format(signOff),
            time: _formatTime(signOff),
          );
          final totalBlock = _MetricBlock(
            label: 'Total',
            value: _formatDuration(record.workedDuration),
            valueColor: record.hasTimes ? th.textPrimary : th.textDisabled,
          );

          if (isWide) {
            return Row(
              children: [
                SizedBox(width: 190, child: dateBlock),
                Expanded(child: timeBlock),
                Expanded(child: outBlock),
                SizedBox(width: 76, child: totalBlock),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              dateBlock,
              const SizedBox(height: AppDesign.spaceMD),
              Row(
                children: [
                  Expanded(child: timeBlock),
                  Expanded(child: outBlock),
                  SizedBox(width: 70, child: totalBlock),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '00:00';
    return DateFormat('HH:mm').format(value);
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            DateFormat.E().format(record.date),
            style: AppTextStyles.caption.copyWith(color: th.textDisabled),
          ),
        ),
        Expanded(
          child: Text(
            '${DateFormat('yyyy-MM-dd').format(record.date)} (${record.status})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(color: th.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({
    required this.label,
    required this.date,
    required this.time,
  });

  final String label;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: th.textSecondary),
        ),
        const SizedBox(height: AppDesign.spaceXS),
        Text(
          '$date  $time',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(color: th.textPrimary),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: th.textSecondary),
        ),
        const SizedBox(height: AppDesign.spaceXS),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
