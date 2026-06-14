import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/services/driver_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/logout_confirmation_dialog.dart';
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
    final refreshed = await DriverAuthService().findDriverById(
      driver.id,
      forceServer: true,
    );
    if (!mounted) return;
    setState(() => _refreshing = false);

    final messenger = ScaffoldMessenger.of(context);
    if (refreshed == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.t('profileRefreshFailed'))),
      );
      return;
    }

    app.setDriver(refreshed);
    messenger.showSnackBar(SnackBar(content: Text(l10n.t('profileRefreshed'))));
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final shouldLogout = await showLogoutConfirmationDialog(
      context: context,
      title: l10n.t('logoutConfirmTitle'),
      message: l10n.t('logoutConfirmMessage'),
      cancelLabel: l10n.t('cancel'),
      logoutLabel: l10n.t('logout'),
    );
    if (!shouldLogout) return;

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
    final useWebLayout = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    return DriverPageShell(
      title: l10n.t('settings'),
      body: useWebLayout
          ? _WebSettingsView(
              app: app,
              driverAvailable: driver != null,
              l10n: l10n,
              refreshing: _refreshing,
              loggingOut: _loggingOut,
              onRefreshProfile: _refreshProfile,
              onLogout: _confirmLogout,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              children: [
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
}

class _WebSettingsView extends StatelessWidget {
  const _WebSettingsView({
    required this.app,
    required this.driverAvailable,
    required this.l10n,
    required this.refreshing,
    required this.loggingOut,
    required this.onRefreshProfile,
    required this.onLogout,
  });

  final AppController app;
  final bool driverAvailable;
  final AppLocalizations l10n;
  final bool refreshing;
  final bool loggingOut;
  final VoidCallback onRefreshProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _WebSettingsPanel(
                title: l10n.t('appPreferences'),
                subtitle: 'Personalize the driver console experience.',
                children: [
                  _WebThemeSelector(
                    mode: app.themeMode,
                    onChanged: app.setThemeMode,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 12),
                  _WebLanguageSelector(
                    locale: app.locale,
                    onChanged: app.setLocale,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _WebSettingsPanel(
                title: l10n.t('settingsFunctions'),
                subtitle: 'Account actions and support tools.',
                children: [
                  _WebActionCard(
                    icon: Icons.sync_rounded,
                    title: l10n.t('refreshProfile'),
                    subtitle: l10n.t('refreshProfileHint'),
                    loading: refreshing,
                    onTap: driverAvailable ? onRefreshProfile : null,
                  ),
                  const SizedBox(height: 12),
                  _WebActionCard(
                    icon: Icons.support_agent_rounded,
                    title: l10n.t('support'),
                    subtitle: l10n.t('contactAdmin'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportPage()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WebActionCard(
                    icon: Icons.logout_rounded,
                    title: l10n.t('logout'),
                    subtitle: l10n.t('logoutSettingsHint'),
                    danger: true,
                    loading: loggingOut,
                    onTap: onLogout,
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

class _WebSettingsPanel extends StatelessWidget {
  const _WebSettingsPanel({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: th.borderColor),
        boxShadow: th.isDark ? null : AppDesign.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(
              color: th.textPrimary,
              fontWeight: AppFontWeights.extraBold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: th.textSecondary),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _WebThemeSelector extends StatelessWidget {
  const _WebThemeSelector({
    required this.mode,
    required this.onChanged,
    required this.l10n,
  });

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _WebChoiceGroup<ThemeMode>(
      icon: Icons.contrast_rounded,
      title: l10n.t('theme'),
      value: mode,
      options: [
        _WebChoiceOption(ThemeMode.system, l10n.t('systemDefault')),
        _WebChoiceOption(ThemeMode.light, l10n.t('lightMode')),
        _WebChoiceOption(ThemeMode.dark, l10n.t('darkMode')),
      ],
      onChanged: onChanged,
    );
  }
}

class _WebLanguageSelector extends StatelessWidget {
  const _WebLanguageSelector({
    required this.locale,
    required this.onChanged,
    required this.l10n,
  });

  final Locale locale;
  final ValueChanged<Locale> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _WebChoiceGroup<Locale>(
      icon: Icons.language_rounded,
      title: l10n.t('language'),
      value: locale,
      options: const [
        _WebChoiceOption(Locale('en'), 'English'),
        _WebChoiceOption(Locale('si'), '\u0dc3\u0dd2\u0d82\u0dc4\u0dbd'),
        _WebChoiceOption(Locale('ta'), '\u0ba4\u0bae\u0bbf\u0bb4\u0bcd'),
      ],
      onChanged: onChanged,
    );
  }
}

class _WebChoiceOption<T> {
  const _WebChoiceOption(this.value, this.label);

  final T value;
  final String label;
}

class _WebChoiceGroup<T> extends StatelessWidget {
  const _WebChoiceGroup({
    required this.icon,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<_WebChoiceOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: th.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: th.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: th.textPrimary,
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = option.value == value;
              return GestureDetector(
                onTap: () => onChanged(option.value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryColor
                        : th.cardBackground,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected ? AppColors.primaryColor : th.borderColor,
                    ),
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
                        option.label,
                        style: AppTextStyles.caption.copyWith(
                          color: selected ? Colors.white : th.textPrimary,
                          fontWeight: selected
                              ? AppFontWeights.extraBold
                              : AppFontWeights.medium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WebActionCard extends StatelessWidget {
  const _WebActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final color = danger ? AppColors.dangerColor : AppColors.primaryColor;
    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: th.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: th.borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: danger ? AppColors.dangerColor : th.textPrimary,
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: th.textSecondary,
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
              Icon(Icons.arrow_forward_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        color: th.textSecondary,
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
    final th = ThemeHelper.of(context);
    return _TileShell(
      icon: Icons.contrast_rounded,
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.t('theme'),
              style: AppTextStyles.bodyMedium.copyWith(color: th.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<ThemeMode>(
            value: mode,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text(l10n.t('systemDefault')),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text(l10n.t('lightMode')),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text(l10n.t('darkMode')),
              ),
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
    final th = ThemeHelper.of(context);
    return _TileShell(
      icon: Icons.language_rounded,
      showDivider: false,
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.t('language'),
              style: AppTextStyles.bodyMedium.copyWith(color: th.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<Locale>(
            value: locale,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(
                value: Locale('si'),
                child: Text('\u0dc3\u0dd2\u0d82\u0dc4\u0dbd'),
              ),
              DropdownMenuItem(
                value: Locale('ta'),
                child: Text('\u0ba4\u0bae\u0bbf\u0bb4\u0bcd'),
              ),
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
    final th = ThemeHelper.of(context);
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
                        color: danger ? AppColors.dangerColor : th.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: th.textSecondary,
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
        if (showDivider) const Divider(height: 1, indent: 62, endIndent: 14),
      ],
    );
  }
}
