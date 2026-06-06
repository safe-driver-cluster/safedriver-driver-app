import 'package:country_code_picker/country_code_picker.dart' show codes;
import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
    required this.labelText,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String selectedCountryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  static const _countryFilter = ['LK', 'IN', 'BD', 'PK', 'NP', 'MV'];

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final countries = codes
        .where((country) => _countryFilter.contains(country['code']))
        .toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: th.inputFill,
            borderRadius: BorderRadius.circular(AppDesign.radiusMD),
            border: Border.all(color: th.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCountryCode,
              borderRadius: BorderRadius.circular(AppDesign.radiusMD),
              dropdownColor: th.cardBackground,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: th.textSecondary,
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: th.textPrimary,
                fontWeight: AppFontWeights.bold,
              ),
              selectedItemBuilder: (context) {
                return countries.map((country) {
                  final countryCode = country['code'] ?? '';
                  final dialCode = country['dial_code'] ?? '';
                  return _SelectedCountryCode(
                    flag: _flagFor(countryCode),
                    dialCode: dialCode,
                  );
                }).toList();
              },
              items: countries.map((country) {
                final countryCode = country['code'] ?? '';
                final dialCode = country['dial_code'] ?? '';
                final countryName = country['name'] ?? countryCode;
                return DropdownMenuItem<String>(
                  value: dialCode,
                  child: _CountryCodeOption(
                    flag: _flagFor(countryCode),
                    dialCode: dialCode,
                    countryName: countryName,
                  ),
                );
              }).toList(),
              onChanged: (dialCode) {
                if (dialCode == null || dialCode.isEmpty) return;
                onCountryCodeChanged(dialCode);
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
              hintText: labelText,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              filled: true,
              fillColor: th.inputFill,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                borderSide: BorderSide(color: th.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                borderSide: BorderSide(color: th.primary, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                borderSide: const BorderSide(color: AppColors.dangerColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                borderSide: const BorderSide(
                  color: AppColors.dangerColor,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _flagFor(String countryCode) {
    if (countryCode.length != 2) return countryCode;
    final upper = countryCode.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }
}

class _CountryCodeOption extends StatelessWidget {
  const _CountryCodeOption({
    required this.flag,
    required this.dialCode,
    required this.countryName,
  });

  final String flag;
  final String dialCode;
  final String countryName;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          dialCode,
          style: AppTextStyles.bodyMedium.copyWith(
            color: th.textPrimary,
            fontWeight: AppFontWeights.bold,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            countryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: th.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SelectedCountryCode extends StatelessWidget {
  const _SelectedCountryCode({required this.flag, required this.dialCode});

  final String flag;
  final String dialCode;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          dialCode,
          style: AppTextStyles.bodyMedium.copyWith(
            color: th.textPrimary,
            fontWeight: AppFontWeights.bold,
          ),
        ),
      ],
    );
  }
}
