import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  late final List<_OnboardData> _pages = [
    _OnboardData(
      image: 'assets/images/onboard-01.png',
      icon: Icons.space_dashboard_rounded,
      accent: AppColors.primaryColor,
      eyebrow: 'Driver workspace',
      title: 'Your daily route, clear from the first stop',
      subtitle:
          'See assigned buses, attendance, alerts, and feedback in a focused console built for driver routines.',
      stats: const [
        _OnboardStat(Icons.directions_bus_filled_rounded, 'Bus details'),
        _OnboardStat(Icons.fact_check_rounded, 'Attendance'),
      ],
    ),
    _OnboardData(
      image: 'assets/images/onboard-02.png',
      icon: Icons.shield_rounded,
      accent: AppColors.secondaryColor,
      eyebrow: 'Safety awareness',
      title: 'Stay visible when every minute matters',
      subtitle:
          'Receive alert updates, keep duty status current, and give admins the context they need quickly.',
      stats: const [
        _OnboardStat(Icons.notifications_active_rounded, 'Live alerts'),
        _OnboardStat(Icons.verified_user_rounded, 'Duty status'),
      ],
    ),
    _OnboardData(
      image: 'assets/images/onboard-03.png',
      icon: Icons.support_agent_rounded,
      accent: AppColors.infoColor,
      eyebrow: 'Admin support',
      title: 'Reach support without leaving the road flow',
      subtitle:
          'Raise complaints, review profile details, and keep communication organized in one secure app.',
      stats: const [
        _OnboardStat(Icons.rate_review_rounded, 'Feedback'),
        _OnboardStat(Icons.headset_mic_rounded, 'Support'),
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppScope.of(context).completeOnboarding();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              AppColors.surfaceLight,
              Color(0xFFE8F2FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.drive_eta_rounded,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SafeDriver',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: AppFontWeights.extraBold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(l10n.t('skip')),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _OnboardSlide(data: _pages[i]),
                  ),
                ),
                _OnboardFooter(
                  activeIndex: _index,
                  pageCount: _pages.length,
                  accent: _pages[_index].accent,
                  l10n: l10n,
                  onNext: _index == _pages.length - 1
                      ? _finish
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardFooter extends StatelessWidget {
  const _OnboardFooter({
    required this.activeIndex,
    required this.pageCount,
    required this.accent,
    required this.l10n,
    required this.onNext,
  });

  final int activeIndex;
  final int pageCount;
  final Color accent;
  final AppLocalizations l10n;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = activeIndex == pageCount - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pageCount,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: i == activeIndex ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == activeIndex
                    ? accent
                    : AppColors.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              shadowColor: accent.withValues(alpha: 0.35),
              elevation: 8,
            ),
            icon: Icon(
              isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              size: 20,
            ),
            label: Text(
              isLast ? l10n.t('getStarted') : l10n.t('next'),
              style: const TextStyle(fontWeight: AppFontWeights.extraBold),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardData {
  _OnboardData({
    required this.image,
    required this.icon,
    required this.accent,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  final String image;
  final IconData icon;
  final Color accent;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<_OnboardStat> stats;
}

class _OnboardStat {
  const _OnboardStat(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({required this.data});

  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 610;
        final imageHeight = compact ? 210.0 : 285.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IllustrationPanel(
                  data: data,
                  imageHeight: imageHeight,
                  compact: compact,
                ),
                SizedBox(height: compact ? 20 : 26),
                _CopyPanel(data: data, compact: compact),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({
    required this.data,
    required this.imageHeight,
    required this.compact,
  });

  final _OnboardData data;
  final double imageHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, compact ? 16 : 22, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [data.accent.withValues(alpha: 0.98), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(data.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.eyebrow,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: AppFontWeights.semiBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Image.asset(data.image, height: imageHeight, fit: BoxFit.contain),
        ],
      ),
    );
  }
}

class _CopyPanel extends StatelessWidget {
  const _CopyPanel({required this.data, required this.compact});

  final _OnboardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: compact ? 24 : 28,
            height: 1.12,
            fontWeight: AppFontWeights.extraBold,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.55,
            fontSize: 15,
          ),
        ),
        SizedBox(height: compact ? 18 : 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final stat in data.stats) ...[
              _FeaturePill(stat: stat, accent: data.accent),
              if (stat != data.stats.last) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.stat, required this.accent});

  final _OnboardStat stat;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardTint),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(stat.icon, color: accent, size: 18),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
