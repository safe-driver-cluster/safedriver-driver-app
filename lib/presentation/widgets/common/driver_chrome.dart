import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';

class DriverBackButton extends StatelessWidget {
  const DriverBackButton({super.key, this.onPressed, this.foreground});

  final VoidCallback? onPressed;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? Colors.white;
    return _HeaderActionSurface(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      child: Icon(Icons.arrow_back_rounded, color: color, size: 22),
    );
  }
}

class _HeaderActionSurface extends StatelessWidget {
  const _HeaderActionSurface({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class DriverIconButton extends StatelessWidget {
  const DriverIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _HeaderActionSurface(
      tooltip: tooltip,
      onPressed: onPressed,
      child: Icon(icon, color: Colors.white, size: 23),
    );
  }
}

class DriverGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const DriverGradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 96 : 108);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final canNavigateBack = showBack && Navigator.canPop(context);
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            ),
            Positioned(
              right: -46,
              top: -62,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: -42,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.infoColor.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: topPadding,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    if (canNavigateBack) ...[
                      const DriverBackButton(),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headline3.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: AppFontWeights.extraBold,
                              letterSpacing: 0,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontWeight: AppFontWeights.medium,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      ...actions.map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverBottomNavBar extends StatelessWidget {
  const DriverBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<DriverNavItem> items;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      decoration: BoxDecoration(
        color: th.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: th.isDark ? null : AppDesign.shadowLG,
      ),
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(index),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 58,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: selected
                          ? AppColors.primaryColor
                          : th.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? AppColors.primaryColor
                              : th.textSecondary,
                          fontWeight: selected
                              ? AppFontWeights.bold
                              : AppFontWeights.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class DriverNavItem {
  const DriverNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class DriverPageShell extends StatelessWidget {
  const DriverPageShell({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
    this.bottomNavigationBar,
    this.selectedNavIndex = 0,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottomNavigationBar;
  final int selectedNavIndex;

  @override
  Widget build(BuildContext context) {
    final driver = AppScope.of(context).driver;
    final useNavigationRail =
        MediaQuery.sizeOf(context).width >= 900 && driver != null;
    final navBar =
        bottomNavigationBar ??
        (driver == null
            ? null
            : DriverBottomNavBar(
                selectedIndex: selectedNavIndex.clamp(0, 3).toInt(),
                onSelected: (value) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (_) => false,
                    arguments: value,
                  );
                },
                items: _driverNavItems(context),
              ));
    final shellBody = useNavigationRail
        ? Row(
            children: [
              _DriverNavigationRail(
                selectedIndex: selectedNavIndex.clamp(0, 3).toInt(),
                items: _driverNavItems(context),
                onSelected: (value) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (_) => false,
                    arguments: value,
                  );
                },
              ),
              Expanded(child: DriverResponsiveBody(child: body)),
            ],
          )
        : DriverResponsiveBody(child: body);
    return Scaffold(
      appBar: DriverGradientAppBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showBack: showBack,
      ),
      body: shellBody,
      bottomNavigationBar: useNavigationRail ? null : navBar,
    );
  }

  List<DriverNavItem> _driverNavItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      DriverNavItem(icon: Icons.dashboard_rounded, label: l10n.t('dashboard')),
      DriverNavItem(
        icon: Icons.directions_bus_rounded,
        label: l10n.t('myBuses'),
      ),
      DriverNavItem(
        icon: Icons.notifications_rounded,
        label: l10n.t('myAlerts'),
      ),
      DriverNavItem(icon: Icons.person_rounded, label: l10n.t('profile')),
    ];
  }
}

class _DriverNavigationRail extends StatelessWidget {
  const _DriverNavigationRail({
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<DriverNavItem> items;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: th.isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF4F8FF)],
              ),
        color: th.isDark ? th.cardBackground : null,
        border: Border(right: BorderSide(color: th.borderColor)),
        boxShadow: th.isDark ? null : AppDesign.shadowSM,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              _RailBrand(th: th),
              const SizedBox(height: 22),
              Expanded(
                child: NavigationRail(
                  extended: true,
                  minExtendedWidth: 228,
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  labelType: NavigationRailLabelType.none,
                  indicatorColor: AppColors.primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  selectedIconTheme: const IconThemeData(
                    color: AppColors.primaryColor,
                  ),
                  unselectedIconTheme: IconThemeData(color: th.textSecondary),
                  selectedLabelTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                  unselectedLabelTextStyle: AppTextStyles.bodyMedium.copyWith(
                    color: th.textSecondary,
                    fontWeight: AppFontWeights.medium,
                  ),
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.icon),
                        label: Text(item.label),
                      ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'Driver operations console',
                  style: AppTextStyles.caption.copyWith(
                    color: th.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({required this.th});

  final ThemeHelper th;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: th.isDark ? null : AppDesign.shadowSM,
          ),
          child: const Icon(Icons.drive_eta_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SafeDriver',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: th.textPrimary,
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
              Text(
                'Driver web',
                style: AppTextStyles.caption.copyWith(color: th.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DriverResponsiveBody extends StatelessWidget {
  const DriverResponsiveBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: child);
  }
}
