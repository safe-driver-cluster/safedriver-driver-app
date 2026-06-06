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
    final body = ListView(
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
                      driver.email.isEmpty ? driver.phoneNumber : driver.email,
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
