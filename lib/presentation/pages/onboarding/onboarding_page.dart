import 'package:flutter/material.dart';

import '../../../app/routes.dart';
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
    final pages = [
      _OnboardData(
        'assets/images/onboard-01.png',
        'Your driver console',
        'See assigned buses, attendance, alerts, and passenger feedback in one clean workspace.',
      ),
      _OnboardData(
        'assets/images/onboard-02.png',
        'Real-time safety awareness',
        'Receive driver-based alerts and keep your vehicle status visible.',
      ),
      _OnboardData(
        'assets/images/onboard-03.png',
        'Stay connected with admin',
        'Send complaints, review your profile, and get support without leaving the app.',
      ),
    ];
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(l10n.t('skip')),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: pages.length,
                  itemBuilder: (_, i) => _OnboardSlide(data: pages[i]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _index ? 24 : 7,
                    height: 7,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.primaryColor
                          : Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _index == pages.length - 1
                      ? _finish
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                  child: Text(
                    _index == pages.length - 1
                        ? l10n.t('getStarted')
                        : l10n.t('next'),
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

class _OnboardData {
  _OnboardData(this.image, this.title, this.subtitle);
  final String image;
  final String title;
  final String subtitle;
}

class _OnboardSlide extends StatelessWidget {
  const _OnboardSlide({required this.data});

  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(data.image, height: 260, fit: BoxFit.contain),
        const SizedBox(height: 32),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
