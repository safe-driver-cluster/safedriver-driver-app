import 'package:flutter/material.dart';

import '../../../app/routes.dart';
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
              Color(0xFF4F83FF),
              AppColors.primaryColor,
              Color(0xFF1D4ED8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 70),
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.language_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.t('selectLanguage'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 48),
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
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                    ),
                    onPressed: () async {
                      await AppScope.of(context).setLocale(_selected);
                      if (!context.mounted) return;
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.onboarding,
                      );
                    },
                    child: Text(
                      l10n.t('continueText'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(selected ? 0.22 : 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(selected ? 0.85 : 0.18),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
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
