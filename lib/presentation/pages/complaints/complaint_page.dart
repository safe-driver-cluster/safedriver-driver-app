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
  String _selectedType = 'Bus issue';
  bool _loading = false;

  static const _complaintTypes = [
    'Bus issue',
    'Route issue',
    'Safety issue',
    'App issue',
    'Other',
  ];

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
        title: _title.text.trim().isEmpty ? _selectedType : _title.text.trim(),
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
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.t('complaintMedia'),
                style: AppTextStyles.title.copyWith(
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.photo_camera_rounded,
                      label: l10n.t('camera'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickMedia(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.photo_library_rounded,
                      label: l10n.t('gallery'),
                      onTap: () {
                        Navigator.pop(context);
                        _pickMedia(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 96),
        children: [
          _ComplaintHero(title: l10n.t('submitComplaint')),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complaint type',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _complaintTypes.map((type) {
                      return _ComplaintTypeChip(
                        label: type,
                        selected: _selectedType == type,
                        onTap: () => setState(() => _selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _title,
                    decoration: _whiteInputDecoration(
                      labelText: l10n.t('complaintTitle'),
                      hintText: 'Example: Bus door issue',
                      icon: Icons.title_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 6,
                    decoration: _whiteInputDecoration(
                      labelText: l10n.t('complaintMessage'),
                      hintText: 'Explain what happened and where.',
                      alignLabelWithHint: true,
                      icon: Icons.notes_rounded,
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

  InputDecoration _whiteInputDecoration({
    required String labelText,
    required IconData icon,
    String? hintText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: alignLabelWithHint ? 72 : 0),
        child: Icon(icon, color: AppColors.primaryColor),
      ),
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
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.4),
      ),
    );
  }
}

class _ComplaintHero extends StatelessWidget {
  const _ComplaintHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dangerColor, Color(0xFFFF6B7B)],
        ),
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
              Icons.report_problem_rounded,
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
                  title,
                  style: AppTextStyles.title.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell admin what needs attention',
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

class _ComplaintTypeChip extends StatelessWidget {
  const _ComplaintTypeChip({
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
          color: selected ? AppColors.dangerColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.dangerColor : AppColors.cardTint,
          ),
          boxShadow: selected ? AppDesign.shadowSM : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 6),
            ],
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
