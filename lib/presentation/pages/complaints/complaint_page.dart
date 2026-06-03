import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
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
  final _picker = ImagePicker();
  XFile? _media;
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
        media: _media,
      );
      _title.clear();
      _message.clear();
      setState(() => _media = null);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('complaintSent'))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickMedia(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() => _media = image);
  }

  Future<void> _showMediaPicker() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.t('camera')),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.t('gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DriverPageShell(
      title: l10n.t('complaints'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.dangerColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.report_problem_rounded,
                    color: AppColors.dangerColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t('submitComplaint'),
                    style: AppTextStyles.title.copyWith(
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SoftCard(
            padding: const EdgeInsets.all(14),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: l10n.t('complaintTitle'),
                      prefixIcon: const Icon(Icons.title_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.t('fieldRequired')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.t('complaintMessage'),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 72),
                        child: Icon(Icons.notes_rounded),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.t('fieldRequired')
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _MediaBox(
                    media: _media,
                    title: l10n.t('complaintMedia'),
                    addLabel: _media == null
                        ? l10n.t('addMedia')
                        : l10n.t('changeMedia'),
                    removeLabel: l10n.t('removeMedia'),
                    onAdd: _loading ? null : _showMediaPicker,
                    onRemove: _loading
                        ? null
                        : () => setState(() => _media = null),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: l10n.t('submit'),
                    icon: Icons.send_rounded,
                    isLoading: _loading,
                    onPressed: _loading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaBox extends StatelessWidget {
  const _MediaBox({
    required this.media,
    required this.title,
    required this.addLabel,
    required this.removeLabel,
    required this.onAdd,
    required this.onRemove,
  });

  final XFile? media;
  final String title;
  final String addLabel;
  final String removeLabel;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 10),
          if (media != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(media!.path),
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: Icon(
                    media == null
                        ? Icons.add_photo_alternate_rounded
                        : Icons.change_circle_rounded,
                  ),
                  label: Text(addLabel),
                ),
              ),
              if (media != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: removeLabel,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
