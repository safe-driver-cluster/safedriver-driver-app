import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';

class DriverBackButton extends StatelessWidget {
  const DriverBackButton({super.key, this.onPressed, this.foreground});

  final VoidCallback? onPressed;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? Colors.white;
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const Icon(Icons.arrow_back_rounded),
      color: color,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.16),
        fixedSize: const Size.square(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
        fixedSize: const Size.square(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
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
  Size get preferredSize => Size.fromHeight(subtitle == null ? 100 : 116);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      ),
      titleSpacing: 0,
      title: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
          child: Row(
            children: [
              if (showBack) ...[
                const DriverBackButton(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
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
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DriverGradientAppBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showBack: showBack,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
