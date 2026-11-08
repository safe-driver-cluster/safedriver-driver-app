import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/design_constants.dart';

class DashboardActionTile extends StatelessWidget {
  const DashboardActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.92),
                color.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppDesign.shadowSM,
          ),
          child: _TileContent(
            title: title,
            subtitle: subtitle,
            icon: icon,
            decorativeIcon: false,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -26,
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.10),
                size: 104,
              ),
            ),
            _TileContent(
              title: title,
              subtitle: subtitle,
              icon: icon,
              decorativeIcon: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.decorativeIcon,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool decorativeIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(decorativeIcon ? 10 : 12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: decorativeIcon ? 19 : 20,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withValues(alpha: 0.82),
              size: 20,
            ),
          ],
        ),
        const Spacer(),
        Text(
          title,
          maxLines: decorativeIcon ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: AppFontWeights.extraBold,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: decorativeIcon ? 3 : 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(
                alpha: decorativeIcon ? 0.82 : 0.78,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
