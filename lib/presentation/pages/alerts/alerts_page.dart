import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/alert_model.dart';
import '../../../data/services/alert_service.dart';
import '../../../providers/auth_provider.dart';

final alertServiceProvider = Provider((ref) => AlertService());

final alertsProvider = StreamProvider.autoDispose<List<AlertModel>>((ref) {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return Stream.value([]);

  final service = ref.watch(alertServiceProvider);
  return service.streamAlerts(driverId: driverId);
});

final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return Stream.value(0);

  final service = ref.watch(alertServiceProvider);
  return service.streamUnreadCount(driverId);
});

class AlertsPage extends ConsumerWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final alertsAsync = ref.watch(alertsProvider);
    final unreadCountAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myAlerts),
        actions: [
          unreadCountAsync.when(
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton.icon(
                      onPressed: () async {
                        final driverId = ref.read(currentDriverIdProvider);
                        if (driverId != null) {
                          await ref
                              .read(alertServiceProvider)
                              .markAllAsRead(driverId);
                        }
                      },
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: Text(
                        l10n.markAllRead,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAlerts,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return _buildAlertCard(context, l10n, alert, ref);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, AppLocalizations l10n,
      AlertModel alert, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isRead ? 1 : 3,
      color: alert.isRead ? null : Colors.blue.shade50,
      child: InkWell(
        onTap: () async {
          if (!alert.isRead) {
            await ref.read(alertServiceProvider).markAsRead(alert.id);
          }
          _showAlertDetails(context, l10n, alert);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAlertIcon(alert.type),
                    color: _getAlertColor(alert.priority),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: alert.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                    ),
                  ),
                  if (!alert.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alert.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(alert.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Chip(
                    label: Text(
                      alert.priority.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor:
                        _getAlertColor(alert.priority).withOpacity(0.2),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlertDetails(
      BuildContext context, AppLocalizations l10n, AlertModel alert) {
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getAlertIcon(alert.type),
                color: _getAlertColor(alert.priority)),
            const SizedBox(width: 12),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.message),
              const SizedBox(height: 16),
              Text(
                dateFormat.format(alert.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
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

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.emergency:
        return Icons.emergency;
      case AlertType.maintenance:
        return Icons.build;
      case AlertType.schedule:
        return Icons.schedule;
      case AlertType.safety:
        return Icons.security;
      case AlertType.announcement:
        return Icons.campaign;
      case AlertType.general:
      default:
        return Icons.info;
    }
  }

  Color _getAlertColor(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return Colors.red;
      case AlertPriority.high:
        return Colors.orange;
      case AlertPriority.medium:
        return Colors.blue;
      case AlertPriority.low:
        return Colors.grey;
    }
  }
}
