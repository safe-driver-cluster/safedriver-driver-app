import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/models/driver_models.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';

class SupportHistoryPage extends StatefulWidget {
  const SupportHistoryPage({super.key});

  @override
  State<SupportHistoryPage> createState() => _SupportHistoryPageState();
}

class _SupportHistoryPageState extends State<SupportHistoryPage> {
  final _vm = DriverDashboardViewModel();
  Stream<List<DriverSupportRequest>>? _stream;
  String? _streamDriverId;
  int _refreshKey = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = AppScope.of(context).driver;
    if (driver != null && (_stream == null || _streamDriverId != driver.id)) {
      _setStream(driver.id);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _setStream(String driverId) {
    _streamDriverId = driverId;
    _stream = _vm.supportRequests(driverId);
  }

  Future<void> _refresh() async {
    final driver = AppScope.of(context).driver!;
    setState(() {
      _refreshKey++;
      _setStream(driver.id);
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final driver = AppScope.of(context).driver!;
    final stream = _stream ?? _vm.supportRequests(driver.id);
    return DriverPageShell(
      title: 'Support history',
      selectedNavIndex: 0,
      body: StreamBuilder<List<DriverSupportRequest>>(
        key: ValueKey(_refreshKey),
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const _ScrollableEmptyState(
                message: 'Could not load support history. Pull to retry.',
                icon: Icons.error_outline_rounded,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = [...snapshot.data!]..sort(_newestFirst);
          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const _ScrollableEmptyState(
                message:
                    'No support requests submitted from this driver app yet.',
                icon: Icons.history_rounded,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _SupportHistoryCard(request: requests[index]),
            ),
          );
        },
      ),
    );
  }

  int _newestFirst(DriverSupportRequest a, DriverSupportRequest b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }
}

class _SupportHistoryCard extends StatelessWidget {
  const _SupportHistoryCard({required this.request});

  final DriverSupportRequest request;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    final priorityColor = request.priority.toLowerCase() == 'urgent'
        ? AppColors.dangerColor
        : AppColors.primaryColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSupportDetails(context, request),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: AppFontWeights.extraBold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(request.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  icon: Icons.circle_rounded,
                  label: _labelFor(request.status),
                  color: statusColor,
                ),
              ],
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                request.message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.35),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Pill(
                  icon: request.priority.toLowerCase() == 'urgent'
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_rounded,
                  label: _labelFor(request.priority),
                  color: priorityColor,
                ),
                if (request.updatedAt != null)
                  _Pill(
                    icon: Icons.update_rounded,
                    label:
                        'Updated ${DateFormat.MMMd().format(request.updatedAt!)}',
                    color: AppColors.textSecondary,
                  ),
                _Pill(
                  icon: Icons.open_in_new_rounded,
                  label: 'View details',
                  color: statusColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('closed') ||
        normalized.contains('resolved') ||
        normalized.contains('done')) {
      return AppColors.secondaryColor;
    }
    if (normalized.contains('progress') || normalized.contains('review')) {
      return AppColors.warningColor;
    }
    return AppColors.primaryColor;
  }
}

void _showSupportDetails(BuildContext context, DriverSupportRequest request) {
  showDialog<void>(
    context: context,
    builder: (context) => _SupportDetailsDialog(request: request),
  );
}

class _SupportDetailsDialog extends StatelessWidget {
  const _SupportDetailsDialog({required this.request});

  final DriverSupportRequest request;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    final priorityColor = request.priority.toLowerCase() == 'urgent'
        ? AppColors.dangerColor
        : AppColors.primaryColor;
    final th = ThemeHelper.of(context);
    final size = MediaQuery.sizeOf(context);
    final rows = _supportDetailRows(request);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: size.height * 0.86,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: th.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: th.isDark ? null : AppDesign.shadowLG,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.category,
                            style: AppTextStyles.title.copyWith(
                              color: th.textPrimary,
                              fontWeight: AppFontWeights.extraBold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDetailTime(request.createdAt),
                            style: AppTextStyles.caption.copyWith(
                              color: th.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  request.message.isEmpty
                      ? 'No support message was provided.'
                      : request.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: th.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.circle_rounded,
                      label: _labelFor(request.status),
                      color: statusColor,
                    ),
                    _Pill(
                      icon: request.priority.toLowerCase() == 'urgent'
                          ? Icons.priority_high_rounded
                          : Icons.check_circle_rounded,
                      label: _labelFor(request.priority),
                      color: priorityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Full details',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: th.textPrimary,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 10),
                ...rows.map(
                  (row) => _DetailRow(label: row.key, value: row.value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('closed') ||
        normalized.contains('resolved') ||
        normalized.contains('done')) {
      return AppColors.secondaryColor;
    }
    if (normalized.contains('progress') || normalized.contains('review')) {
      return AppColors.warningColor;
    }
    return AppColors.primaryColor;
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: th.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: th.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: th.textSecondary,
              fontWeight: AppFontWeights.bold,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            value,
            style: AppTextStyles.caption.copyWith(
              color: th.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

List<MapEntry<String, String>> _supportDetailRows(
  DriverSupportRequest request,
) {
  return [
    MapEntry('Category', request.category),
    MapEntry('Priority', _labelFor(request.priority)),
    MapEntry('Status', _labelFor(request.status)),
    MapEntry('Submitted', _formatDetailTime(request.createdAt)),
    MapEntry('Last updated', _formatDetailTime(request.updatedAt)),
    MapEntry('Request ID', request.id),
  ];
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

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
          Icon(icon, size: 13, color: color),
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

class _ScrollableEmptyState extends StatelessWidget {
  const _ScrollableEmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: EmptyState(message: message, icon: icon),
        ),
      ],
    );
  }
}

String _formatTime(DateTime? time) {
  if (time == null) return 'Date unavailable';
  return DateFormat.yMMMd().add_jm().format(time);
}

String _formatDetailTime(DateTime? time) {
  if (time == null) return 'Date unavailable';
  return DateFormat.yMMMMd().add_jm().format(time);
}

String _labelFor(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
