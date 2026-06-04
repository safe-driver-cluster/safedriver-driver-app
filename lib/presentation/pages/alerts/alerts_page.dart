import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../data/models/driver_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final vm = DriverDashboardViewModel();
    final body = StreamBuilder(
      stream: vm.alerts(driver),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        debugPrint(
          '[AlertsPage] driver=${driver.id} state=${snapshot.connectionState} hasError=${snapshot.hasError} count=${data.length}',
        );
        if (snapshot.hasError) {
          debugPrint('[AlertsPage.error] ${snapshot.error}');
          return EmptyState(
            message: 'Could not load alerts. Check debug logs.',
            icon: Icons.error_outline_rounded,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.isEmpty) {
          return EmptyState(
            message: l10n.t('noAlerts'),
            icon: Icons.notifications_off_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final alert = data[i];
            return _AlertCard(alert: alert);
          },
        );
      },
    );
    if (!showAppBar) return body;
    return DriverPageShell(
      title: l10n.t('myAlerts'),
      selectedNavIndex: 2,
      body: body,
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final DriverAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(alert.type);
    return SoftCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_iconFor(alert.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(alert.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(label: alert.priority, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (alert.type.isNotEmpty)
                _InfoChip(
                  icon: Icons.category_rounded,
                  label: _labelFor(alert.type),
                  color: color,
                ),
              if (alert.numberPlate.isNotEmpty)
                _InfoChip(
                  icon: Icons.confirmation_number_rounded,
                  label: alert.numberPlate,
                  color: AppColors.primaryColor,
                ),
              if (alert.tag.isNotEmpty)
                _InfoChip(
                  icon: Icons.sell_rounded,
                  label: alert.tag,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('smoking')) return AppColors.dangerColor;
    if (normalized.contains('phone')) return AppColors.warningColor;
    if (normalized.contains('sleep')) return AppColors.purpleColor;
    return AppColors.primaryColor;
  }

  IconData _iconFor(String type) {
    final normalized = type.toLowerCase();
    if (normalized.contains('smoking')) return Icons.smoke_free_rounded;
    if (normalized.contains('phone')) return Icons.phone_android_rounded;
    if (normalized.contains('sleep')) return Icons.bedtime_rounded;
    return Icons.warning_rounded;
  }

  String _labelFor(String type) {
    if (type.isEmpty) return 'Alert';
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Time unavailable';
    return DateFormat.yMMMd().add_jm().format(time);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: AppFontWeights.bold,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: AppFontWeights.bold,
            ),
          ),
        ],
      ),
    );
  }
}
