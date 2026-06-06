import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../data/services/driver_data_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';
import '../../widgets/common/submission_success_dialog.dart';
import 'support_history_page.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _message = TextEditingController();
  final _service = DriverDataService();
  String _category = 'App issue';
  String _priority = 'normal';
  bool _submitting = false;

  static const _hotline = '119';
  static const _adminPhone = '+94761165638';
  static const _categories = [
    'App issue',
    'Bus assignment',
    'Route problem',
    'Account help',
    'Safety concern',
  ];
  static const _priorities = ['normal', 'urgent'];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _copyContact(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $value'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    final message = _message.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('fieldRequired')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.submitSupportRequest(
        driverId: driver.id,
        driverName: driver.fullName,
        category: _category,
        message: message,
        priority: _priority,
      );
      _message.clear();
      if (!mounted) return;
      await showSubmissionSuccessDialog(
        context: context,
        title: 'Support Request Sent',
        message: 'Your support request was sent to admin successfully.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = AppScope.of(context).driver!;
    return DriverPageShell(
      title: l10n.t('support'),
      selectedNavIndex: 0,
      actions: [
        DriverIconButton(
          tooltip: 'Support history',
          icon: Icons.history_rounded,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupportHistoryPage()),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
        children: [
          _HeroCard(driverName: driver.fullName),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: l10n.t('contactAdmin'),
                  subtitle: _adminPhone,
                  color: AppColors.primaryColor,
                  onTap: () => _copyContact(_adminPhone, 'Admin phone'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.local_police_rounded,
                  title: l10n.t('emergencyHelp'),
                  subtitle: _hotline,
                  color: AppColors.dangerColor,
                  onTap: () => _copyContact(_hotline, 'Emergency hotline'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SupportRequestCard(
            category: _category,
            priority: _priority,
            categories: _categories,
            priorities: _priorities,
            controller: _message,
            submitting: _submitting,
            onCategoryChanged: (value) => setState(() => _category = value),
            onPriorityChanged: (value) => setState(() => _priority = value),
            onSubmit: _submit,
          ),
          const SizedBox(height: 12),
          _FaqSection(
            items: [
              _FaqItem(
                icon: Icons.directions_bus_rounded,
                title: 'Bus assignment',
                body:
                    'If your assigned bus is wrong, send an urgent support request with the bus number shown in your profile.',
              ),
              _FaqItem(
                icon: Icons.route_rounded,
                title: l10n.t('routeGuidance'),
                body:
                    'Use Maps for route guidance. Report missing route data here so admin can update the vehicle record.',
              ),
              _FaqItem(
                icon: Icons.security_rounded,
                title: 'Account and login',
                body:
                    'OTP login works only with the phone number registered in your driver profile.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.driverName});

  final String driverName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDesign.shadowSM,
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We are here to help',
                  style: AppTextStyles.title.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppDesign.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppFontWeights.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportRequestCard extends StatelessWidget {
  const _SupportRequestCard({
    required this.category,
    required this.priority,
    required this.categories,
    required this.priorities,
    required this.controller,
    required this.submitting,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onSubmit,
  });

  final String category;
  final String priority;
  final List<String> categories;
  final List<String> priorities;
  final TextEditingController controller;
  final bool submitting;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPriorityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories.firstWhere(
      (item) => item == category,
      orElse: () => categories.first,
    );
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Create support request',
                style: AppTextStyles.title.copyWith(
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Category', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((item) {
              final selected = selectedCategory == item;
              return _CategoryChip(
                label: item,
                selected: selected,
                onTap: () => onCategoryChanged(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Priority', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Row(
            children: priorities.map((item) {
              final selected = priority == item;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == priorities.last ? 0 : 8,
                  ),
                  child: _PriorityChip(
                    label: item == 'urgent' ? 'Urgent' : 'Normal',
                    icon: item == 'urgent'
                        ? Icons.priority_high_rounded
                        : Icons.check_circle_rounded,
                    selected: selected,
                    urgent: item == 'urgent',
                    onTap: () => onPriorityChanged(item),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              labelText: 'Describe your issue',
              hintText: 'Example: My assigned bus is not showing today.',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
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
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Send request',
            icon: Icons.send_rounded,
            isLoading: submitting,
            onPressed: submitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.items});

  final List<_FaqItem> items;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Text(
              'Quick help',
              style: AppTextStyles.title.copyWith(
                fontWeight: AppFontWeights.extraBold,
              ),
            ),
          ),
          ...items.map(
            (item) => ExpansionTile(
              leading: Icon(item.icon, color: AppColors.primaryColor),
              title: Text(item.title, style: AppTextStyles.bodyMedium),
              childrenPadding: const EdgeInsets.fromLTRB(56, 0, 14, 12),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.body,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryColor : AppColors.cardTint,
          ),
          boxShadow: selected ? AppDesign.shadowSM : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
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
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.urgent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool urgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = urgent ? AppColors.dangerColor : AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeColor : AppColors.cardTint,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : icon,
              size: 18,
              color: selected ? activeColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected ? activeColor : AppColors.textPrimary,
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

class _FaqItem {
  const _FaqItem({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}
