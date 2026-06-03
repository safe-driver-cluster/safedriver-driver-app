import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
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
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
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
                    Text(driver.fullName, style: AppTextStyles.title),
                    const SizedBox(height: 3),
                    Text(
                      driver.email.isEmpty ? driver.phoneNumber : driver.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
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
        Row(
          children: [
            Expanded(
              child: _ProfileStat(
                icon: Icons.shield_rounded,
                label: l10n.t('safetyScore'),
                value: driver.safetyScore.toStringAsFixed(0),
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStat(
                icon: Icons.star_rounded,
                label: l10n.t('passengerRating'),
                value: driver.rating.toStringAsFixed(1),
                color: AppColors.warningColor,
              ),
            ),
          ],
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
    return DriverPageShell(title: l10n.t('profile'), body: body);
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
                color: AppColors.cardTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            Flexible(
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
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
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.cardTint,
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
    final color = active ? AppColors.secondaryColor : AppColors.textSecondary;
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
