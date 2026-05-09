import 'package:flutter/material.dart';

import '../../../core/constants/design_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = AppScope.of(context).driver!;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(AppDesign.spaceLG),
        children: [
          SoftCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundImage: driver.profileImageUrl == null
                      ? null
                      : NetworkImage(driver.profileImageUrl!),
                  child: driver.profileImageUrl == null
                      ? const Icon(Icons.person_rounded, size: 44)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(driver.fullName, style: AppTextStyles.headline3),
                Text(driver.email),
                const SizedBox(height: 12),
                Text(l10n.t('profilePhotoOnly'), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: l10n.t('employeeId'), value: driver.employeeId),
          _InfoRow(label: l10n.t('phoneNumber'), value: driver.phoneNumber),
          _InfoRow(
            label: l10n.t('license'),
            value: '${driver.licenseType} ${driver.licenseNumber}',
          ),
          _InfoRow(label: l10n.t('currentBus'), value: driver.currentBusId),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
            Text(value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}
