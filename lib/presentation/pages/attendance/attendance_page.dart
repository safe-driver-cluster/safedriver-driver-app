import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/attendance_model.dart';
import '../../../data/services/attendance_service.dart';
import '../../../providers/auth_provider.dart';

final attendanceServiceProvider = Provider((ref) => AttendanceService());

final attendanceHistoryProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return [];

  final service = ref.watch(attendanceServiceProvider);
  return service.getAttendanceHistory(driverId: driverId, limit: 30);
});

final todayAttendanceProvider =
    FutureProvider.autoDispose<AttendanceModel?>((ref) async {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return null;

  final service = ref.watch(attendanceServiceProvider);
  return service.getTodayAttendance(driverId);
});

class AttendancePage extends ConsumerWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAttendance),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(attendanceHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's Attendance Card
              _buildTodaySection(context, l10n, todayAttendanceAsync),
              const SizedBox(height: 24),

              // Attendance History
              Text(
                'Attendance History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildHistorySection(context, l10n, historyAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection(BuildContext context, AppLocalizations l10n,
      AsyncValue<AttendanceModel?> attendanceAsync) {
    return attendanceAsync.when(
      data: (attendance) {
        final now = DateTime.now();
        final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
        final timeFormat = DateFormat('hh:mm a');

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  dateFormat.format(now),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (attendance != null) ...[
                  Icon(
                    attendance.isClockedIn
                        ? Icons.check_circle
                        : Icons.access_time,
                    size: 48,
                    color: attendance.isClockedIn ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    attendance.isClockedIn
                        ? l10n.currentlyOnDuty
                        : l10n.shiftCompleted,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: attendance.isClockedIn
                              ? Colors.green
                              : Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            l10n.clockIn,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeFormat.format(attendance.clockInTime),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (attendance.clockOutTime != null)
                        Column(
                          children: [
                            Text(
                              l10n.clockOut,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeFormat.format(attendance.clockOutTime!),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (attendance.totalHours != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${l10n.totalHours}: ${attendance.totalHours!.toStringAsFixed(2)} hrs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ] else ...[
                  const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance record for today',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, AppLocalizations l10n,
      AsyncValue<List<AttendanceModel>> historyAsync) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No attendance history'),
              ),
            ),
          );
        }

        return Column(
          children: history
              .map((attendance) =>
                  _buildAttendanceCard(context, l10n, attendance))
              .toList(),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
      BuildContext context, AppLocalizations l10n, AttendanceModel attendance) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          attendance.status == AttendanceStatus.completed
              ? Icons.check_circle
              : Icons.access_time,
          color: attendance.status == AttendanceStatus.completed
              ? Colors.green
              : Colors.orange,
        ),
        title: Text(dateFormat.format(attendance.clockInTime)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${l10n.clockIn}: ${timeFormat.format(attendance.clockInTime)}'),
            if (attendance.clockOutTime != null)
              Text(
                  '${l10n.clockOut}: ${timeFormat.format(attendance.clockOutTime!)}'),
            if (attendance.totalHours != null)
              Text(
                  '${l10n.totalHours}: ${attendance.totalHours!.toStringAsFixed(2)} hrs'),
          ],
        ),
        trailing: Chip(
          label: Text(
            attendance.status.toString().split('.').last.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getStatusColor(attendance.status),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.completed:
        return Colors.green.shade100;
      case AttendanceStatus.active:
        return Colors.blue.shade100;
      case AttendanceStatus.late:
        return Colors.orange.shade100;
      case AttendanceStatus.absent:
        return Colors.red.shade100;
    }
  }
}
