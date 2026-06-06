import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
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
    return SoftCard(
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
            ],
          ),
        ],
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

String _labelFor(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
