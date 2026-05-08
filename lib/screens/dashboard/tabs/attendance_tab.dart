import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';

class AttendanceTab extends ConsumerWidget {
  const AttendanceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final attendance = userId != null ? ref.watch(attendanceStreamProvider(userId)) : const AsyncValue.loading();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale!.myAttendance,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          attendance.when(
            data: (attendanceList) {
              if (attendanceList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(locale.noData),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: attendanceList.length,
                itemBuilder: (context, index) {
                  final att = attendanceList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        att.status == 'present' ? Icons.check_circle : Icons.cancel_outlined,
                        color: att.status == 'present' ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        att.date.toString().split(' ')[0],
                      ),
                      subtitle: Text(
                        '${locale.status}: ${att.status}',
                      ),
                      trailing: Text(
                        att.checkInTime != null
                            ? att.checkInTime.toString().split(' ')[1].substring(0, 5)
                            : '-',
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Center(
              child: Text('Error: $err'),
            ),
          ),
        ],
      ),
    );
  }
}
