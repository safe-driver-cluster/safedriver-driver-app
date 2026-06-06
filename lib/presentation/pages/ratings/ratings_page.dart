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

class RatingsPage extends StatefulWidget {
  const RatingsPage({super.key});

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final _vm = DriverDashboardViewModel();
  Stream<List<DriverFeedback>>? _feedbackStream;
  String? _streamDriverId;
  int _refreshKey = 0;
  String _selectedRating = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driver = AppScope.of(context).driver;
    if (driver != null &&
        (_feedbackStream == null || _streamDriverId != driver.id)) {
      _setFeedbackStream(driver.id);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _setFeedbackStream(String driverId) {
    _streamDriverId = driverId;
    _feedbackStream = _vm.feedback(driverId);
  }

  Future<void> _refresh() async {
    final driver = AppScope.of(context).driver!;
    setState(() {
      _refreshKey++;
      _setFeedbackStream(driver.id);
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final stream = _feedbackStream ?? _vm.feedback(driver.id);

    return DriverPageShell(
      title: l10n.t('ratings'),
      selectedNavIndex: 4,
      body: StreamBuilder<List<DriverFeedback>>(
        key: ValueKey(_refreshKey),
        stream: stream,
        builder: (context, snapshot) {
          final data = [...?snapshot.data]
            ..sort((a, b) {
              final aTime =
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bTime.compareTo(aTime);
            });

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: const _ScrollableEmptyState(
                message: 'Could not load ratings. Pull to retry.',
                icon: Icons.error_outline_rounded,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filteredFeedback(data);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _RatingsSummary(
                      driver: driver,
                      feedback: data,
                      selectedRating: _selectedRating,
                      onRatingSelected: (value) {
                        setState(() => _selectedRating = value);
                      },
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: EmptyState(
                        message: data.isEmpty
                            ? l10n.t('noRatings')
                            : 'No ratings match this filter',
                        icon: Icons.star_border_rounded,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _FeedbackCard(feedback: filtered[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<DriverFeedback> _filteredFeedback(List<DriverFeedback> feedback) {
    if (_selectedRating == 'all') return feedback;
    final selected = int.tryParse(_selectedRating);
    if (selected == null) return feedback;
    return feedback.where((item) => item.rating == selected).toList();
  }
}

class _RatingsSummary extends StatelessWidget {
  const _RatingsSummary({
    required this.driver,
    required this.feedback,
    required this.selectedRating,
    required this.onRatingSelected,
  });

  final DriverProfile driver;
  final List<DriverFeedback> feedback;
  final String selectedRating;
  final ValueChanged<String> onRatingSelected;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final liveAverage = feedback.isEmpty
        ? driver.rating
        : feedback.map((item) => item.rating).reduce((a, b) => a + b) /
              feedback.length;
    final total = driver.totalRatings > feedback.length
        ? driver.totalRatings
        : feedback.length;
    final latest = feedback.isEmpty ? null : feedback.first.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.warningColor,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveAverage.toStringAsFixed(1),
                          style: AppTextStyles.headline2.copyWith(
                            color: th.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        _StarRow(rating: liveAverage.round(), size: 18),
                      ],
                    ),
                  ),
                  _SummaryStat(
                    label: 'Total',
                    value: '$total',
                    icon: Icons.forum_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: 'Reviewed',
                      value: '${feedback.length}',
                      icon: Icons.rate_review_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryStat(
                      label: 'Latest',
                      value: _formatLatest(latest),
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _RatingFilterChips(
          selectedRating: selectedRating,
          counts: _ratingCounts(feedback),
          onSelected: onRatingSelected,
        ),
      ],
    );
  }

  Map<int, int> _ratingCounts(List<DriverFeedback> feedback) {
    final counts = {for (var rating = 1; rating <= 5; rating++) rating: 0};
    for (final item in feedback) {
      final rating = item.rating.clamp(1, 5);
      counts[rating] = (counts[rating] ?? 0) + 1;
    }
    return counts;
  }

  String _formatLatest(DateTime? value) {
    if (value == null) return 'None';
    return DateFormat.MMMd().format(value);
  }
}

class _RatingFilterChips extends StatelessWidget {
  const _RatingFilterChips({
    required this.selectedRating,
    required this.counts,
    required this.onSelected,
  });

  final String selectedRating;
  final Map<int, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final items = ['all', '5', '4', '3', '2', '1'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final selected = selectedRating == item;
          final count = item == 'all'
              ? counts.values.fold<int>(0, (sum, value) => sum + value)
              : counts[int.parse(item)] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelected(item),
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
                      item == 'all' ? Icons.tune_rounded : Icons.star_rounded,
                      size: 15,
                      color: selected ? Colors.white : AppColors.warningColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item == 'all' ? 'All ratings' : '$item star',
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white : th.textPrimary,
                        fontWeight: selected
                            ? AppFontWeights.bold
                            : AppFontWeights.medium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: AppTextStyles.caption.copyWith(
                        color: selected ? Colors.white70 : th.textSecondary,
                        fontWeight: AppFontWeights.bold,
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
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});

  final DriverFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final rating = feedback.rating.clamp(0, 5);
    final color = _colorFor(rating);
    final th = ThemeHelper.of(context);
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$rating',
                  style: AppTextStyles.title.copyWith(
                    color: color,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTime(feedback.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: th.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StarRow(rating: rating, size: 17),
            ],
          ),
          if (feedback.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              feedback.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: th.textPrimary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.person_rounded,
                label: feedback.passengerName,
                color: AppColors.primaryColor,
              ),
              if (feedback.category.isNotEmpty)
                _InfoChip(
                  icon: Icons.category_rounded,
                  label: _labelFor(feedback.category),
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFor(int rating) {
    if (rating >= 4) return AppColors.secondaryColor;
    if (rating == 3) return AppColors.warningColor;
    return AppColors.dangerColor;
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
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: th.tintBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 7),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: th.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: th.textPrimary,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating, required this.size});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < normalized ? Icons.star_rounded : Icons.star_border_rounded,
          color: AppColors.warningColor,
          size: size,
        );
      }),
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
