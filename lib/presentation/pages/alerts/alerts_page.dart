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
  final _search = TextEditingController();
  final _vm = DriverDashboardViewModel();
  Stream<List<DriverAlert>>? _alertStream;
  String? _streamDriverId;
  int _refreshKey = 0;
  String _selectedType = 'all';

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
    _search.dispose();
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
          '[AlertsPage.filtered] query=${_search.text.trim()} type=$_selectedType count=${filtered.length}',
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _AlertControlsHeader(
                  controller: _search,
                  types: types,
                  selectedType: _selectedType,
                  onSearchChanged: (_) {
                    debugPrint(
                      '[AlertsPage.search] query=${_search.text.trim()} local filter only',
                    );
                    setState(() {});
                  },
                  onClearSearch: () {
                    _search.clear();
                    debugPrint('[AlertsPage.search] cleared local filter only');
                    setState(() {});
                  },
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
    final query = _search.text.trim().toLowerCase();
    return alerts.where((alert) {
      final typeMatches =
          _selectedType == 'all' || alert.type.toLowerCase() == _selectedType;
      final searchable = [
        alert.title,
        alert.description,
        alert.type,
        alert.tag,
        alert.numberPlate,
        alert.priority,
      ].join(' ').toLowerCase();
      final searchMatches = query.isEmpty || searchable.contains(query);
      return typeMatches && searchMatches;
    }).toList();
  }
}

class _AlertControlsHeader extends SliverPersistentHeaderDelegate {
  _AlertControlsHeader({
    required this.controller,
    required this.types,
    required this.selectedType,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onTypeSelected,
  });

  final TextEditingController controller;
  final List<String> types;
  final String selectedType;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
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
            _AlertSearchField(
              controller: controller,
              onChanged: onSearchChanged,
              onClear: onClearSearch,
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
    return oldDelegate.controller != controller ||
        oldDelegate.types != types ||
        oldDelegate.selectedType != selectedType;
  }
}

class _AlertSearchField extends StatelessWidget {
  const _AlertSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search alerts, plate, type...',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.primaryColor,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cardTint),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.cardTint),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 1.4,
          ),
        ),
      ),
    );
  }
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
