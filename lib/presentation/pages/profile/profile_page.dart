import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:safe_driver_driver_app/l10n/app_localizations.dart';

import '../../../providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploading = false;

  Future<void> _updateProfilePicture() async {
    final driver = ref.read(authDriverProvider).value;
    if (driver == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('driver_profiles')
          .child('${driver.id}.jpg');

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Update driver profile
      await ref
          .read(authDriverProvider.notifier)
          .updateProfileImage(driver.id, downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authDriverProvider.notifier).signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final driverAsync = ref.watch(authDriverProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: driverAsync.when(
        data: (driver) {
          if (driver == null) {
            return const Center(child: Text('No driver data'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Picture Section
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: driver.profileImageUrl != null
                          ? NetworkImage(driver.profileImageUrl!)
                          : null,
                      child: driver.profileImageUrl == null
                          ? Text(
                              driver.firstName[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 48, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.black54,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                          onPressed:
                              _isUploading ? null : _updateProfilePicture,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  driver.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  driver.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 24),

                // Profile Information Cards
                _buildInfoCard(
                  context,
                  l10n.phoneNumber,
                  driver.phoneNumber,
                  Icons.phone,
                ),
                _buildInfoCard(
                  context,
                  l10n.licenseNumber,
                  driver.licenseNumber,
                  Icons.badge,
                ),
                _buildInfoCard(
                  context,
                  'License Type',
                  driver.licenseType,
                  Icons.card_membership,
                ),
                _buildInfoCard(
                  context,
                  'Experience',
                  '${driver.experience.totalYears} years',
                  Icons.work,
                ),
                _buildInfoCard(
                  context,
                  'Current Route',
                  driver.currentRoute ?? 'Not assigned',
                  Icons.route,
                ),
                _buildInfoCard(
                  context,
                  'Current Bus',
                  driver.currentBusId ?? 'Not assigned',
                  Icons.directions_bus,
                ),
                _buildInfoCard(
                  context,
                  'Safety Score',
                  '${driver.safetyScore.toStringAsFixed(1)}/100',
                  Icons.security,
                  valueColor: _getScoreColor(driver.safetyScore),
                ),
                _buildInfoCard(
                  context,
                  'Alertness Level',
                  driver.alertnessLevelDisplay,
                  Icons.visibility,
                ),
                _buildInfoCard(
                  context,
                  l10n.status,
                  driver.statusDisplay,
                  Icons.info,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        subtitle: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
