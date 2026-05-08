import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final driverData = userId != null
        ? ref.watch(driverDataProvider(userId))
        : AsyncValue.loading();

    return driverData.when(
      data: (driver) {
        if (driver == null) {
          return Center(child: Text(locale!.noData));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Update profile picture
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(locale!.updateProfilePicture),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Profile Information
              Text(locale.name, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(driver.name),
                ),
              ),
              const SizedBox(height: 16),
              Text(locale.phone, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(driver.phone),
                ),
              ),
              const SizedBox(height: 16),
              Text(locale.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(driver.email),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                locale.licenseNumber,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(driver.licenseNumber),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                locale.busAssigned,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(driver.busId),
                ),
              ),
              const SizedBox(height: 16),
              Text(locale.status, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    driver.isActive ? locale!.active : locale!.inactive,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Profile information cannot be edited. Please contact admin for changes.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
