import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';

Future<bool> showLogoutConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String logoutLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _LogoutConfirmationDialog(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      logoutLabel: logoutLabel,
    ),
  );
  return result ?? false;
}

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.logoutLabel,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String logoutLabel;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final borderColor = th.isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final subtleFill = th.isDark ? Colors.white10 : const Color(0xFFF8FAFC);

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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: th.isDark ? null : AppDesign.shadowLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.dangerColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.dangerColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppDesign.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.title.copyWith(
                            color: th.textPrimary,
                            fontWeight: AppFontWeights.extraBold,
                          ),
                        ),
                        const SizedBox(height: AppDesign.spaceXS),
                        Text(
                          message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: th.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spaceXL),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: th.textPrimary,
                          backgroundColor: subtleFill,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radiusMD,
                            ),
                            side: BorderSide(color: borderColor),
                          ),
                          textStyle: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDesign.spaceMD),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.dangerColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesign.radiusMD,
                            ),
                          ),
                          textStyle: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: AppFontWeights.extraBold,
                          ),
                        ),
                        child: Text(
                          logoutLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
}
