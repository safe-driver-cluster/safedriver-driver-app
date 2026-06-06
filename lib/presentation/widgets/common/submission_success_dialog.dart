import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';

Future<void> showSubmissionSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String actionLabel = 'Done',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _SubmissionSuccessDialog(
      title: title,
      message: message,
      actionLabel: actionLabel,
    ),
  );
}

class _SubmissionSuccessDialog extends StatelessWidget {
  const _SubmissionSuccessDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final borderColor = th.isDark ? Colors.white10 : const Color(0xFFD1FAE5);
    final successColor = AppColors.secondaryColor;

    return Dialog(
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          padding: const EdgeInsets.all(AppDesign.spaceLG),
          decoration: BoxDecoration(
            color: th.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: th.isDark ? null : AppDesign.shadowLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      successColor.withValues(alpha: 0.18),
                      successColor.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: successColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: AppDesign.spaceLG),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.headline3.copyWith(
                  color: successColor,
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
              const SizedBox(height: AppDesign.spaceSM),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: th.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDesign.spaceXL),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesign.radiusMD),
                    ),
                    textStyle: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
