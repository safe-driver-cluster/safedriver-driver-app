import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/models/driver_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../viewmodels/driver_dashboard_view_model.dart';
import '../../widgets/common/professional_widgets.dart';
import '../complaints/complaint_page.dart';

const _defaultAlertTypes = ['safety', 'smoking', 'phone', 'sleep'];

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final _vm = DriverDashboardViewModel();
  Stream<List<DriverAlert>>? _alertStream;
  String? _streamDriverId;
  int _refreshKey = 0;
  String _selectedType = 'all';
  String _dateFilter = 'all';
  DateTimeRange? _customDateRange;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = AppScope.of(context).driver;
    if (driver != null &&
        (_alertStream == null || _streamDriverId != driver.id)) {
      _setAlertStream(driver);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _setAlertStream(DriverProfile driver) {
    debugPrint(
      '[AlertsPage.stream] create stream driver=${driver.id} bus=${driver.currentBusId}',
    );
    _streamDriverId = driver.id;
    _alertStream = _vm.alerts(driver);
  }

  Future<void> _refresh() async {
    debugPrint('[AlertsPage.refresh] restarting alert stream');
    final driver = AppScope.of(context).driver!;
    setState(() {
      _refreshKey++;
      _setAlertStream(driver);
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final stream = _alertStream ?? _vm.alerts(driver);
    final body = StreamBuilder(
      key: ValueKey(_refreshKey),
      stream: stream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        debugPrint(
          '[AlertsPage] driver=${driver.id} refreshKey=$_refreshKey state=${snapshot.connectionState} hasError=${snapshot.hasError} count=${data.length}',
        );
        if (snapshot.hasError) {
          debugPrint('[AlertsPage.error] ${snapshot.error}');
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _ScrollableEmptyState(
              message: 'Could not load alerts. Check debug logs.',
              icon: Icons.error_outline_rounded,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final types = _typesFor(data);
        final filtered = _filteredAlerts(data);
        debugPrint(
          '[AlertsPage.filtered] type=$_selectedType dateFilter=$_dateFilter range=$_customDateRange count=${filtered.length}',
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _AlertControlsHeader(
                  types: types,
                  selectedType: _selectedType,
                  dateFilter: _dateFilter,
                  dateRange: _customDateRange,
                  onDateFilterSelected: _selectDateFilter,
                  onCustomDateRange: _pickCustomDateRange,
                  onTypeSelected: (value) {
                    debugPrint(
                      '[AlertsPage.filter] type=$value local filter only',
                    );
                    setState(() => _selectedType = value);
                  },
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: EmptyState(
                      message: data.isEmpty
                          ? l10n.t('noAlerts')
                          : 'No matching alerts',
                      icon: Icons.notifications_off_rounded,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _AlertCard(alert: filtered[index]),
                  ),
                ),
            ],
          ),
        );
      },
    );
    if (!widget.showAppBar) return body;
    return DriverPageShell(
      title: l10n.t('myAlerts'),
      selectedNavIndex: 2,
      body: body,
    );
  }

  List<String> _typesFor(List<DriverAlert> alerts) {
    final liveTypes = alerts
        .map((alert) => alert.type.trim().toLowerCase())
        .where((type) => type.isNotEmpty)
        .toSet();
    final extraTypes = liveTypes.difference(_defaultAlertTypes.toSet()).toList()
      ..sort();
    final types = [..._defaultAlertTypes, ...extraTypes];
    return ['all', ...types];
  }

  List<DriverAlert> _filteredAlerts(List<DriverAlert> alerts) {
    return alerts.where((alert) {
      final typeMatches =
          _selectedType == 'all' || alert.type.toLowerCase() == _selectedType;
      final dateMatches = _isWithinRange(alert.createdAt);
      return typeMatches && dateMatches;
    }).toList();
  }

  bool _isWithinRange(DateTime? value) {
    final range = _activeDateRange();
    if (range == null) return true;
    if (value == null) return false;
    final date = DateUtils.dateOnly(value);
    final from = DateUtils.dateOnly(range.start);
    final to = DateUtils.dateOnly(range.end);
    if (date.isBefore(from)) return false;
    if (date.isAfter(to)) return false;
    return true;
  }

  DateTimeRange? _activeDateRange() {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    switch (_dateFilter) {
      case 'today':
        return DateTimeRange(start: today, end: today);
      case '7d':
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case '30d':
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case 'custom':
        return _customDateRange;
      default:
        return null;
    }
  }

  void _selectDateFilter(String value) {
    debugPrint('[AlertsPage.dateFilter] selected=$value local filter only');
    setState(() {
      _dateFilter = value;
      if (value != 'custom') _customDateRange = null;
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateUtils.dateOnly(now.subtract(const Duration(days: 6))),
            end: DateUtils.dateOnly(now),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    debugPrint('[AlertsPage.dateFilter] custom=$picked local filter only');
    setState(() {
      _dateFilter = 'custom';
      _customDateRange = picked;
    });
  }
}

class _AlertControlsHeader extends SliverPersistentHeaderDelegate {
  _AlertControlsHeader({
    required this.types,
    required this.selectedType,
    required this.dateFilter,
    required this.dateRange,
    required this.onDateFilterSelected,
    required this.onCustomDateRange,
    required this.onTypeSelected,
  });

  final List<String> types;
  final String selectedType;
  final String dateFilter;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onDateFilterSelected;
  final VoidCallback onCustomDateRange;
  final ValueChanged<String> onTypeSelected;

  @override
  double get minExtent => 126;

  @override
  double get maxExtent => 126;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final th = ThemeHelper.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: th.pageBackground,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            _AlertDateFilterChips(
              selectedFilter: dateFilter,
              dateRange: dateRange,
              onSelected: onDateFilterSelected,
              onCustomDateRange: onCustomDateRange,
            ),
            const SizedBox(height: 10),
            _AlertFilterChips(
              types: types,
              selectedType: selectedType,
              onSelected: onTypeSelected,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _AlertControlsHeader oldDelegate) {
    return oldDelegate.types != types ||
        oldDelegate.selectedType != selectedType ||
        oldDelegate.dateFilter != dateFilter ||
        oldDelegate.dateRange != dateRange;
  }
}

class _AlertDateFilterChips extends StatelessWidget {
  const _AlertDateFilterChips({
    required this.selectedFilter,
    required this.dateRange,
    required this.onSelected,
    required this.onCustomDateRange,
  });

  final String selectedFilter;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onSelected;
  final VoidCallback onCustomDateRange;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final items = [
      const _DateFilterItem(value: 'all', label: 'All dates'),
      const _DateFilterItem(value: 'today', label: 'Today'),
      const _DateFilterItem(value: '7d', label: '7 days'),
      const _DateFilterItem(value: '30d', label: '30 days'),
      _DateFilterItem(value: 'custom', label: _customLabel()),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final selected = selectedFilter == item.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: item.value == 'custom'
                  ? onCustomDateRange
                  : () => onSelected(item.value),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : th.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primaryColor : th.borderColor,
                  ),
                  boxShadow: selected || th.isDark ? null : AppDesign.shadowSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.value == 'custom'
                          ? Icons.date_range_rounded
                          : selected
                          ? Icons.check_rounded
                          : Icons.calendar_today_rounded,
                      size: 15,
                      color: selected ? Colors.white : AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white : th.textPrimary,
                        fontWeight: selected
                            ? AppFontWeights.bold
                            : AppFontWeights.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _customLabel() {
    if (selectedFilter != 'custom' || dateRange == null) return 'Date range';
    final format = DateFormat.MMMd();
    return '${format.format(dateRange!.start)} - ${format.format(dateRange!.end)}';
  }
}

class _DateFilterItem {
  const _DateFilterItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _AlertFilterChips extends StatelessWidget {
  const _AlertFilterChips({
    required this.types,
    required this.selectedType,
    required this.onSelected,
  });

  final List<String> types;
  final String selectedType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final selected = selectedType == type;
          final label = type == 'all' ? 'All alerts' : _labelFor(type);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelected(type),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : th.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primaryColor : th.borderColor,
                  ),
                  boxShadow: selected || th.isDark ? null : AppDesign.shadowSM,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white : th.textPrimary,
                        fontWeight: selected
                            ? AppFontWeights.bold
                            : AppFontWeights.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final DriverAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(alert.type);
    final th = ThemeHelper.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAlertDetails(context, alert),
      child: SoftCard(
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
                          color: th.textSecondary,
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
              style: AppTextStyles.bodyMedium.copyWith(color: th.textPrimary),
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
              ],
            ),
          ],
        ),
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

void _showAlertDetails(BuildContext context, DriverAlert alert) {
  final parentContext = context;
  showDialog<void>(
    context: context,
    builder: (context) => _AlertDetailsDialog(
      alert: alert,
      onReport: () {
        Navigator.of(context).pop();
        Navigator.of(parentContext).push(
          MaterialPageRoute(
            builder: (_) => ComplaintPage(
              prefill: ComplaintPrefill(
                type: 'Wrong alerts',
                title: 'Wrong alert report: ${alert.title}',
                message: _complaintMessageFor(alert),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _AlertDetailsDialog extends StatelessWidget {
  const _AlertDetailsDialog({required this.alert, required this.onReport});

  final DriverAlert alert;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final color = _detailColorFor(alert.type);
    final th = ThemeHelper.of(context);
    final rows = _detailRows(alert);
    final size = MediaQuery.sizeOf(context);
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
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_detailIconFor(alert.type), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: AppTextStyles.title.copyWith(
                              fontWeight: AppFontWeights.extraBold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDetailDate(alert.createdAt),
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
                  alert.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: th.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.priority_high_rounded,
                      label: alert.priority,
                      color: color,
                    ),
                    if (alert.status.isNotEmpty)
                      _InfoChip(
                        icon: Icons.radio_button_checked_rounded,
                        label: alert.status,
                        color: AppColors.primaryColor,
                      ),
                    if (alert.numberPlate.isNotEmpty)
                      _InfoChip(
                        icon: Icons.confirmation_number_rounded,
                        label: alert.numberPlate,
                        color: AppColors.primaryColor,
                      ),
                  ],
                ),
                if (alert.evidenceUrl.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Evidence',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 180),
                      color: AppColors.cardTint.withValues(alpha: 0.28),
                      child: Image.network(
                        alert.evidenceUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 220,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            height: 180,
                            child: Center(
                              child: Text(
                                'Evidence image could not be loaded',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  'Full details',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 10),
                ...rows.map(
                  (row) => _DetailRow(label: row.key, value: row.value),
                ),
                const SizedBox(height: 10),
                GradientButton(
                  label: 'Report this alert',
                  icon: Icons.report_problem_rounded,
                  onPressed: onReport,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _complaintMessageFor(DriverAlert alert) {
  final lines = [
    'I want to report this alert as wrong or needing review.',
    '',
    'Alert details:',
    'Title: ${alert.title}',
    'Message: ${alert.description}',
    if (alert.type.isNotEmpty) 'Type: ${_humanize(alert.type)}',
    if (alert.driverRef.isNotEmpty) 'Driver: ${alert.driverRef}',
    if (alert.numberPlate.isNotEmpty) 'Number plate: ${alert.numberPlate}',
    if (alert.tag.isNotEmpty) 'Tag: ${alert.tag}',
    if (alert.status.isNotEmpty) 'Status: ${alert.status}',
    if (alert.priority.isNotEmpty) 'Priority: ${alert.priority}',
    'Time: ${_formatDetailDate(alert.createdAt)}',
    if (alert.evidenceUrl.isNotEmpty) 'Evidence: ${alert.evidenceUrl}',
  ];
  return lines.join('\n');
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

List<MapEntry<String, String>> _detailRows(DriverAlert alert) {
  final rows = <MapEntry<String, String>>[
    if (alert.driverRef.isNotEmpty) MapEntry('Driver', alert.driverRef),
    if (alert.type.isNotEmpty) MapEntry('Type', _humanize(alert.type)),
    if (alert.tag.isNotEmpty) MapEntry('Tag', alert.tag),
    if (alert.numberPlate.isNotEmpty)
      MapEntry('Number plate', alert.numberPlate),
    MapEntry('Status', alert.status),
    MapEntry('Priority', alert.priority),
    MapEntry('Time', _formatDetailDate(alert.createdAt)),
  ];

  final hiddenEvidenceKeys = {
    'evidence',
    'evidenceUrl',
    'imageUrl',
    'photoUrl',
    'mediaUrl',
    'attachmentUrl',
  };
  final existingLabels = rows.map((row) => row.key.toLowerCase()).toSet();
  final rawEntries = alert.raw.entries.toList()
    ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
  for (final entry in rawEntries) {
    if (hiddenEvidenceKeys.contains(entry.key)) continue;
    final label = _humanize(entry.key);
    if (existingLabels.contains(label.toLowerCase())) continue;
    final value = _formatDetailValue(entry.value);
    if (value.isEmpty) continue;
    rows.add(MapEntry(label, value));
    existingLabels.add(label.toLowerCase());
  }
  return rows;
}

String _formatDetailValue(dynamic value) {
  if (value == null) return '';
  if (value is Timestamp) return _formatDetailDate(value.toDate());
  if (value is DateTime) return _formatDetailDate(value);
  if (value is GeoPoint) {
    return '${value.latitude.toStringAsFixed(6)}, ${value.longitude.toStringAsFixed(6)}';
  }
  if (value is Iterable) {
    return value
        .map(_formatDetailValue)
        .where((item) => item.isNotEmpty)
        .join(', ');
  }
  if (value is Map) {
    return value.entries
        .map(
          (entry) =>
              '${_humanize(entry.key.toString())}: ${_formatDetailValue(entry.value)}',
        )
        .join('\n');
  }
  return value.toString();
}

String _formatDetailDate(DateTime? time) {
  if (time == null) return 'Time unavailable';
  return DateFormat.yMMMd().add_jms().format(time);
}

String _humanize(String value) {
  if (value.trim().isEmpty) return 'Alert';
  return value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

Color _detailColorFor(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('smoking')) return AppColors.dangerColor;
  if (normalized.contains('phone')) return AppColors.warningColor;
  if (normalized.contains('sleep')) return AppColors.purpleColor;
  return AppColors.primaryColor;
}

IconData _detailIconFor(String type) {
  final normalized = type.toLowerCase();
  if (normalized.contains('smoking')) return Icons.smoke_free_rounded;
  if (normalized.contains('phone')) return Icons.phone_android_rounded;
  if (normalized.contains('sleep')) return Icons.bedtime_rounded;
  return Icons.warning_rounded;
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
