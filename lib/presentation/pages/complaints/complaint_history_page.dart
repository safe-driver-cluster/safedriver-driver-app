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

class ComplaintHistoryPage extends StatefulWidget {
  const ComplaintHistoryPage({super.key});

  @override
  State<ComplaintHistoryPage> createState() => _ComplaintHistoryPageState();
}

class _ComplaintHistoryPageState extends State<ComplaintHistoryPage> {
  final _vm = DriverDashboardViewModel();
  Stream<List<DriverComplaintRecord>>? _stream;
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
    _stream = _vm.complaints(driverId);
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
    final stream = _stream ?? _vm.complaints(driver.id);
    return DriverPageShell(
      title: 'Complaint history',
      selectedNavIndex: 0,
      body: StreamBuilder<List<DriverComplaintRecord>>(
        key: ValueKey(_refreshKey),
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const _ScrollableEmptyState(
                message: 'Could not load complaint history. Pull to retry.',
                icon: Icons.error_outline_rounded,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = [...snapshot.data!]..sort(_newestFirst);
          if (complaints.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const _ScrollableEmptyState(
                message: 'No complaints submitted from this driver app yet.',
                icon: Icons.history_rounded,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: complaints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _ComplaintHistoryCard(record: complaints[index]),
            ),
          );
        },
      ),
    );
  }

  int _newestFirst(DriverComplaintRecord a, DriverComplaintRecord b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }
}

class _ComplaintHistoryCard extends StatelessWidget {
  const _ComplaintHistoryCard({required this.record});

  final DriverComplaintRecord record;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showComplaintDetails(context, record),
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
                    color: AppColors.dangerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.report_problem_rounded,
                    color: AppColors.dangerColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: AppFontWeights.extraBold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(record.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  icon: Icons.circle_rounded,
                  label: _labelFor(record.status),
                  color: statusColor,
                ),
              ],
            ),
            if (record.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                record.message,
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
                if (record.category.isNotEmpty)
                  _Pill(
                    icon: Icons.category_rounded,
                    label: record.category,
                    color: AppColors.primaryColor,
                  ),
                if (record.mediaUrl.isNotEmpty)
                  const _Pill(
                    icon: Icons.attach_file_rounded,
                    label: 'Media attached',
                    color: AppColors.infoColor,
                  ),
                if (record.updatedAt != null)
                  _Pill(
                    icon: Icons.update_rounded,
                    label:
                        'Updated ${DateFormat.MMMd().format(record.updatedAt!)}',
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
    return AppColors.dangerColor;
  }
}

void _showComplaintDetails(BuildContext context, DriverComplaintRecord record) {
  showDialog<void>(
    context: context,
    builder: (context) => _ComplaintDetailsDialog(record: record),
  );
}

class _ComplaintDetailsDialog extends StatelessWidget {
  const _ComplaintDetailsDialog({required this.record});

  final DriverComplaintRecord record;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(record.status);
    final th = ThemeHelper.of(context);
    final size = MediaQuery.sizeOf(context);
    final rows = _complaintDetailRows(record);
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
                        color: AppColors.dangerColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.report_problem_rounded,
                        color: AppColors.dangerColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: AppTextStyles.title.copyWith(
                              color: th.textPrimary,
                              fontWeight: AppFontWeights.extraBold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDetailTime(record.createdAt),
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
                  record.message.isEmpty
                      ? 'No complaint message was provided.'
                      : record.message,
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
                      label: _labelFor(record.status),
                      color: statusColor,
                    ),
                    if (record.category.isNotEmpty)
                      _Pill(
                        icon: Icons.category_rounded,
                        label: record.category,
                        color: AppColors.primaryColor,
                      ),
                    if (record.mediaUrl.isNotEmpty)
                      const _Pill(
                        icon: Icons.attach_file_rounded,
                        label: 'Media attached',
                        color: AppColors.infoColor,
                      ),
                  ],
                ),
                if (record.mediaUrl.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Attached media',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: th.textPrimary,
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ComplaintMediaPreview(url: record.mediaUrl),
                ],
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
    return AppColors.dangerColor;
  }
}

class _ComplaintMediaPreview extends StatelessWidget {
  const _ComplaintMediaPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        color: th.inputFill,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Attached media could not be loaded.',
                style: AppTextStyles.caption.copyWith(
                  color: th.textSecondary,
                  height: 1.3,
                ),
              ),
            );
          },
        ),
      ),
    );
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

List<MapEntry<String, String>> _complaintDetailRows(
  DriverComplaintRecord record,
) {
  return [
    MapEntry('Status', _labelFor(record.status)),
    MapEntry(
      'Category',
      record.category.isEmpty ? 'Not specified' : record.category,
    ),
    MapEntry('Submitted', _formatDetailTime(record.createdAt)),
    MapEntry('Last updated', _formatDetailTime(record.updatedAt)),
    MapEntry('Complaint ID', record.id),
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
