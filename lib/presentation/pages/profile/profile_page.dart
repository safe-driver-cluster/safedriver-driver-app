import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final driver = AppScope.of(context).driver!;
    final l10n = AppLocalizations.of(context);
    final th = ThemeHelper.of(context);
    final useWebLayout = kIsWeb && MediaQuery.sizeOf(context).width >= 900;
    final body = useWebLayout
        ? _WebProfileView(driver: driver, l10n: l10n)
        : ListView(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
            children: [
              SoftCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _Avatar(url: driver.profileImageUrl, size: 62),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.fullName,
                            style: AppTextStyles.title.copyWith(
                              color: th.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            driver.email.isEmpty
                                ? driver.phoneNumber
                                : driver.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: th.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InlineStatus(
                            active: driver.isOnDuty,
                            label: driver.isOnDuty
                                ? l10n.t('active')
                                : l10n.t('inactive'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.badge_rounded,
                label: l10n.t('employeeId'),
                value: driver.employeeId,
              ),
              _InfoRow(
                icon: Icons.phone_rounded,
                label: l10n.t('phoneNumber'),
                value: driver.phoneNumber,
              ),
              _InfoRow(
                icon: Icons.credit_card_rounded,
                label: l10n.t('license'),
                value: '${driver.licenseType} ${driver.licenseNumber}'.trim(),
              ),
              _InfoRow(
                icon: Icons.directions_bus_rounded,
                label: l10n.t('currentBus'),
                value: driver.currentBusId,
              ),
              _InfoRow(
                icon: Icons.alt_route_rounded,
                label: l10n.t('routeGuidance'),
                value: driver.currentRoute,
              ),
              _InfoRow(
                icon: Icons.home_rounded,
                label: 'Address',
                value: driver.raw['address']?.toString() ?? '',
              ),
              _InfoRow(
                icon: Icons.work_history_rounded,
                label: 'Experience',
                value: driver.raw['experience']?.toString() ?? '',
              ),
            ],
          );
    if (!showAppBar) return body;
    return DriverPageShell(
      title: l10n.t('profile'),
      selectedNavIndex: 3,
      body: body,
    );
  }
}

class _WebProfileView extends StatelessWidget {
  const _WebProfileView({required this.driver, required this.l10n});

  final dynamic driver;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final address = driver.raw['address']?.toString() ?? '';
    final experience = driver.raw['experience']?.toString() ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                height: 196,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: th.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: th.borderColor),
                  boxShadow: th.isDark ? null : AppDesign.shadowSM,
                ),
                child: Row(
                  children: [
                    _Avatar(url: driver.profileImageUrl, size: 86),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headline3.copyWith(
                              color: th.textPrimary,
                              fontWeight: AppFontWeights.extraBold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            driver.email.isEmpty
                                ? driver.phoneNumber
                                : driver.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: th.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _InlineStatus(
                            active: driver.isOnDuty,
                            label: driver.isOnDuty
                                ? l10n.t('active')
                                : l10n.t('inactive'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 196,
                child: Row(
                  children: [
                    Expanded(
                      child: _WebProfileMetric(
                        label: 'Rating',
                        value: driver.rating.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        color: AppColors.warningColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WebProfileMetric(
                        label: 'Safety score',
                        value: driver.safetyScore <= 0
                            ? '-'
                            : driver.safetyScore.toStringAsFixed(0),
                        icon: Icons.shield_rounded,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WebProfileMetric(
                        label: 'Experience',
                        value: experience.isEmpty ? '-' : experience,
                        icon: Icons.work_history_rounded,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _WebProfileSection(
                title: 'Driver identity',
                children: [
                  _WebInfoTile(
                    icon: Icons.badge_rounded,
                    label: l10n.t('employeeId'),
                    value: driver.employeeId,
                  ),
                  _WebInfoTile(
                    icon: Icons.phone_rounded,
                    label: l10n.t('phoneNumber'),
                    value: driver.phoneNumber,
                  ),
                  _WebInfoTile(
                    icon: Icons.home_rounded,
                    label: 'Address',
                    value: address,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _WebProfileSection(
                title: 'Assignment',
                children: [
                  _WebInfoTile(
                    icon: Icons.directions_bus_rounded,
                    label: l10n.t('currentBus'),
                    value: driver.currentBusId,
                  ),
                  _WebInfoTile(
                    icon: Icons.alt_route_rounded,
                    label: l10n.t('routeGuidance'),
                    value: driver.currentRoute,
                  ),
                  _WebInfoTile(
                    icon: Icons.credit_card_rounded,
                    label: l10n.t('license'),
                    value: '${driver.licenseType} ${driver.licenseNumber}'
                        .trim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WebProfileMetric extends StatelessWidget {
  const _WebProfileMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: th.borderColor),
        boxShadow: th.isDark ? null : AppDesign.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headline3.copyWith(
              color: th.textPrimary,
              fontWeight: AppFontWeights.extraBold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: th.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WebProfileSection extends StatelessWidget {
  const _WebProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: th.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: th.textPrimary,
              fontWeight: AppFontWeights.extraBold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _WebInfoTile extends StatelessWidget {
  const _WebInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: th.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: th.borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: th.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                color: th.textPrimary,
                fontWeight: AppFontWeights.extraBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: th.tintBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: th.textSecondary,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: th.textPrimary,
                  fontWeight: AppFontWeights.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: th.tintBackground,
      backgroundImage: url == null ? null : NetworkImage(url!),
      child: url == null
          ? const Icon(Icons.person_rounded, color: AppColors.primaryDark)
          : null,
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final color = active ? AppColors.secondaryColor : th.textSecondary;
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
