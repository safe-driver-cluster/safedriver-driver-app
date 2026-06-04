import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../data/models/driver_models.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';
import '../support/support_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _refreshing = false;
  bool _loggingOut = false;

  Future<void> _refreshProfile() async {
    final app = AppScope.of(context);
    final driver = app.driver;
    final l10n = AppLocalizations.of(context);
    if (driver == null || _refreshing) return;

    setState(() => _refreshing = true);
    final refreshed = await DriverAuthService().findDriverById(driver.id);
    if (!mounted) return;
    setState(() => _refreshing = false);

    final messenger = ScaffoldMessenger.of(context);
    if (refreshed == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.t('profileRefreshFailed'))));
      return;
    }

    app.setDriver(refreshed);
    messenger.showSnackBar(SnackBar(content: Text(l10n.t('profileRefreshed'))));
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('logoutConfirmTitle')),
        content: Text(l10n.t('logoutConfirmMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('logout')),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;

    setState(() => _loggingOut = true);
    await DriverAuthService().signOut();
    app.clearDriver();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final driver = app.driver;
    final l10n = AppLocalizations.of(context);

    return DriverPageShell(
      title: l10n.t('settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
        children: [
          if (driver != null) ...[
            _DriverHeader(driver: driver, l10n: l10n),
            const SizedBox(height: 12),
            _SectionTitle(title: l10n.t('accountDetails')),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _DataTile(
                  icon: Icons.badge_rounded,
                  label: l10n.t('employeeId'),
                  value: driver.employeeId,
                ),
                _DataTile(
                  icon: Icons.phone_rounded,
                  label: l10n.t('phoneNumber'),
                  value: driver.phoneNumber,
                ),
                _DataTile(
                  icon: Icons.mail_rounded,
                  label: l10n.t('email'),
                  value: driver.email,
                ),
                _DataTile(
                  icon: Icons.credit_card_rounded,
                  label: l10n.t('license'),
                  value: _licenseText(driver),
                ),
                _DataTile(
                  icon: Icons.event_rounded,
                  label: l10n.t('licenseExpiry'),
                  value: _dateText(driver.licenseExpiry),
                ),
                _DataTile(
                  icon: Icons.directions_bus_rounded,
                  label: l10n.t('currentBus'),
                  value: driver.currentBusId,
                ),
                _DataTile(
                  icon: Icons.alt_route_rounded,
                  label: l10n.t('routeGuidance'),
                  value: driver.currentRoute,
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          _SectionTitle(title: l10n.t('appPreferences')),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _ThemeModeTile(
                mode: app.themeMode,
                onChanged: app.setThemeMode,
                l10n: l10n,
              ),
              _LanguageTile(
                locale: app.locale,
                onChanged: app.setLocale,
                l10n: l10n,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: l10n.t('settingsFunctions')),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _ActionTile(
                icon: Icons.sync_rounded,
                label: l10n.t('refreshProfile'),
                value: l10n.t('refreshProfileHint'),
                loading: _refreshing,
                onTap: driver == null ? null : _refreshProfile,
              ),
              _ActionTile(
                icon: Icons.support_agent_rounded,
                label: l10n.t('support'),
                value: l10n.t('contactAdmin'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportPage()),
                ),
              ),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: l10n.t('logout'),
                value: l10n.t('logoutSettingsHint'),
                loading: _loggingOut,
                danger: true,
                showDivider: false,
                onTap: _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _licenseText(DriverProfile driver) {
    return [driver.licenseType, driver.licenseNumber]
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
  }

  String _dateText(DateTime? value) {
    if (value == null) return '';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({required this.driver, required this.l10n});

  final DriverProfile driver;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final statusColor = driver.isOnDuty
        ? AppColors.secondaryColor
        : AppColors.textSecondary;
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.cardTint,
            backgroundImage: driver.profileImageUrl == null
                ? null
                : NetworkImage(driver.profileImageUrl!),
            child: driver.profileImageUrl == null
                ? const Icon(Icons.person_rounded, color: AppColors.primaryDark)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  driver.employeeId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      driver.isOnDuty ? l10n.t('active') : l10n.t('inactive'),
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warningColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${driver.rating.toStringAsFixed(1)} (${driver.totalRatings})',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: AppFontWeights.extraBold,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _DataTile extends StatelessWidget {
  const _DataTile({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: icon,
      showDivider: showDivider,
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value.trim().isEmpty ? '-' : value,
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
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.mode,
    required this.onChanged,
    required this.l10n,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: Icons.contrast_rounded,
      child: Row(
        children: [
          Expanded(child: Text(l10n.t('theme'), style: AppTextStyles.bodyMedium)),
          const SizedBox(width: 12),
          DropdownButton<ThemeMode>(
            value: mode,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.t('systemDefault'))),
              DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.t('lightMode'))),
              DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.t('darkMode'))),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.locale,
    required this.onChanged,
    required this.l10n,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: Icons.language_rounded,
      showDivider: false,
      child: Row(
        children: [
          Expanded(child: Text(l10n.t('language'), style: AppTextStyles.bodyMedium)),
          const SizedBox(width: 12),
          DropdownButton<Locale>(
            value: locale,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('si'), child: Text('\u0dc3\u0dd2\u0d82\u0dc4\u0dbd')),
              DropdownMenuItem(value: Locale('ta'), child: Text('\u0ba4\u0bae\u0bbf\u0bb4\u0bcd')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.loading = false,
    this.danger = false,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.dangerColor : AppColors.primaryColor;
    return _TileShell(
      icon: icon,
      iconColor: color,
      showDivider: showDivider,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusSM),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: danger ? AppColors.dangerColor : null,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (loading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.icon,
    required this.child,
    this.iconColor = AppColors.primaryColor,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 62, endIndent: 14),
      ],
    );
  }
}
