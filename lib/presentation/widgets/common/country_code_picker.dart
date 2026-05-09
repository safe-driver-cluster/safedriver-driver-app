import 'package:flutter/material.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
    required this.labelText,
    this.validator,
  });

  final TextEditingController controller;
  final String selectedCountryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String labelText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPicker(context),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).inputDecorationTheme.fillColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🇱🇰'),
                const SizedBox(width: 6),
                Text(selectedCountryCode),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
              labelText: labelText,
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListTile(
          leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
          title: const Text('Sri Lanka'),
          subtitle: const Text('+94'),
          trailing: const Icon(Icons.check_circle_rounded),
          onTap: () {
            onCountryCodeChanged('+94');
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
