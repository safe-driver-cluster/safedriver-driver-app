import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../data/services/driver_data_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _message = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await DriverDataService().submitComplaint(
        driverId: AppScope.of(context).driver!.id,
        title: _title.text.trim(),
        message: _message.text.trim(),
      );
      _title.clear();
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('complaintSent'))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('complaints'))),
      body: Padding(
        padding: const EdgeInsets.all(AppDesign.spaceLG),
        child: SoftCard(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: l10n.t('complaintTitle'),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.t('fieldRequired')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _message,
                  minLines: 5,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: l10n.t('complaintMessage'),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.t('fieldRequired')
                      : null,
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: l10n.t('submit'),
                  icon: Icons.send_rounded,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
