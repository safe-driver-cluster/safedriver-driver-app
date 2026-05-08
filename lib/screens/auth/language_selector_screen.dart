import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';

enum DriverAppLanguage {
  english('en', 'English', 'English'),
  sinhala('si', 'සිංහල', 'Sinhala'),
  tamil('ta', 'தமிழ்', 'Tamil');

  final String code;
  final String nativeName;
  final String englishName;

  const DriverAppLanguage(this.code, this.nativeName, this.englishName);
}

class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  DriverAppLanguage? selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = DriverAppLanguage.english;
  }

  Future<void> _selectLanguage() async {
    if (selectedLanguage != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', selectedLanguage!.code);
        await prefs.setBool('language_selected', true);

        if (mounted) {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error selecting language: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4, 0.8, 1.0],
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1E40AF),
              Color(0xFF1E3A8A),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 50),
                Expanded(child: _buildLanguageOptions()),
                _buildContinueButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Language Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: const Icon(
            Icons.language_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        // Title
        const Text(
          'Choose Your Language',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Subtitle
        Text(
          'Select your preferred language to continue',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLanguageOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        ...DriverAppLanguage.values.map(
          (language) => _buildLanguageOption(language),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLanguageOption(DriverAppLanguage language) {
    final isSelected = selectedLanguage == language;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedLanguage = language;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Flag
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _getLanguageEmoji(language),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Language Names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language.englishName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ElevatedButton(
        onPressed: selectedLanguage != null ? _selectLanguage : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedLanguage != null
              ? Colors.white
              : Colors.white.withOpacity(0.3),
          foregroundColor: const Color(0xFF2563EB),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Continue',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: selectedLanguage != null
                ? const Color(0xFF2563EB)
                : const Color(0xFF2563EB).withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  String _getLanguageEmoji(DriverAppLanguage language) {
    switch (language) {
      case DriverAppLanguage.english:
        return '🇺🇸';
      case DriverAppLanguage.sinhala:
        return '🇱🇰';
      case DriverAppLanguage.tamil:
        return '🇱🇰';
    }
  }
}
