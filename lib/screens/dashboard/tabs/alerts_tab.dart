import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';

class AlertsTab extends ConsumerWidget {
  const AlertsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final alerts = userId != null
        ? ref.watch(alertsStreamProvider(userId))
        : const AsyncValue.loading();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale!.myAlerts,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          alerts.when(
            data: (alertsList) {
              if (alertsList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(locale.noAlerts),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: alertsList.length,
                itemBuilder: (context, index) {
                  final alert = alertsList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        _getAlertIcon(alert.type),
                        color: _getAlertColor(alert.type),
                      ),
                      title: Text(alert.title),
                      subtitle: Text(
                        alert.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatTime(alert.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getAlertColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
