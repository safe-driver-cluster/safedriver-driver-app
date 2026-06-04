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
  DateTimeRange? _dateRange;
  String _dateFilter = 'all';

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final types = _typesFor(data);
        final filtered = _filteredAlerts(data);
        debugPrint(
          '[AlertsPage.filtered] type=$_selectedType date=$_dateFilter range=${_dateRange?.start}..${_dateRange?.end} count=${filtered.length}',
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
                  dateRange: _dateRange,
                  onDateFilterSelected: _selectDateFilter,
                  onCustomDateRange: _pickDateRange,
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
                    padding: const EdgeInsets.only(bottom: 96),
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
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
    final types =
        alerts
            .map((alert) => alert.type.trim().toLowerCase())
            .where((type) => type.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['all', ...types];
  }

  List<DriverAlert> _filteredAlerts(List<DriverAlert> alerts) {
    return alerts.where((alert) {
      final typeMatches =
          _selectedType == 'all' || alert.type.toLowerCase() == _selectedType;
      final dateMatches = _dateRange == null || _isWithinRange(alert.createdAt);
      return typeMatches && dateMatches;
    }).toList();
  }

  bool _isWithinRange(DateTime? value) {
    if (value == null || _dateRange == null) return false;
    final date = DateUtils.dateOnly(value);
    final start = DateUtils.dateOnly(_dateRange!.start);
    final end = DateUtils.dateOnly(_dateRange!.end);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  void _selectDateFilter(String value) {
    final now = DateTime.now();
    DateTimeRange? range;
    if (value == 'today') {
      range = DateTimeRange(start: now, end: now);
    } else if (value == '7d') {
      range = DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      );
    } else if (value == '30d') {
      range = DateTimeRange(
        start: now.subtract(const Duration(days: 29)),
        end: now,
      );
    }
    debugPrint('[AlertsPage.dateFilter] value=$value local filter only');
    setState(() {
      _dateFilter = value;
      _dateRange = range;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange:
          _dateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryColor,
            ),
          );
          child: child!,
        );
      },
    );
    if (picked == null) return;
    debugPrint(
      '[AlertsPage.dateFilter] custom ${picked.start}..${picked.end} local filter only',
    );
    setState(() {
      _dateFilter = 'custom';
      _dateRange = picked;
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
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
                  color: selected ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.cardTint,
                  ),
                  boxShadow: selected ? AppDesign.shadowSM : null,
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
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: selected
                            ? AppFontWeights.bold
                            : AppFontWeights.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                  color: selected ? AppColors.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryColor
                        : AppColors.cardTint,
                  ),
                  boxShadow: selected ? AppDesign.shadowSM : null,
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
                        color: selected ? Colors.white : AppColors.textPrimary,
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
