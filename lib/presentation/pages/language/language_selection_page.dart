import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  Locale _selected = const Locale('en');

  Future<void> _continue() async {
    await AppScope.of(context).setLocale(_selected);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F83FF),
              AppColors.primaryColor,
              Color(0xFF1D4ED8),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              return Padding(
                padding: EdgeInsets.all(wide ? 42 : 28),
                child: wide
                    ? Row(
                        children: [
                          Expanded(
                            child: _LanguageHero(
                              title: l10n.t('selectLanguage'),
                            ),
                          ),
                          const SizedBox(width: 36),
                          SizedBox(width: 480, child: _selector(l10n, wide)),
                        ],
                      )
                    : _selector(l10n, wide),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _selector(AppLocalizations l10n, bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!wide) ...[
          const Spacer(),
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white24,
            child: Icon(Icons.language_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.t('selectLanguage'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: AppFontWeights.extraBold,
            ),
          ),
          const SizedBox(height: 42),
        ] else
          const Spacer(),
        _LanguageTile(
          flag: '🇺🇸',
          title: 'English',
          subtitle: 'English',
          selected: _selected.languageCode == 'en',
          onTap: () => setState(() => _selected = const Locale('en')),
        ),
        _LanguageTile(
          flag: '🇱🇰',
          title: 'සිංහල',
          subtitle: 'Sinhala',
          selected: _selected.languageCode == 'si',
          onTap: () => setState(() => _selected = const Locale('si')),
        ),
        _LanguageTile(
          flag: '🇱🇰',
          title: 'தமிழ்',
          subtitle: 'Tamil',
          selected: _selected.languageCode == 'ta',
          onTap: () => setState(() => _selected = const Locale('ta')),
        ),
        const Spacer(),
        SizedBox(
          height: 56,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _continue,
            child: Text(
              l10n.t('continueText'),
              style: const TextStyle(fontWeight: AppFontWeights.extraBold),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageHero extends StatelessWidget {
  const _LanguageHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white24,
            child: Icon(Icons.language_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1.05,
              fontWeight: AppFontWeights.extraBold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose the language for your driver workspace. You can change this later from settings.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 17,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.22 : 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.85 : 0.18),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
