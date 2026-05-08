import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';

class ComplaintsTab extends ConsumerStatefulWidget {
  const ComplaintsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends ConsumerState<ComplaintsTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final complaints = userId != null ? ref.watch(complaintsStreamProvider(userId)) : const AsyncValue.loading();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale!.complaints,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          // Submit Complaint Button
          ElevatedButton.icon(
            onPressed: () {
              _showSubmitComplaintDialog(context, locale, ref, userId);
            },
            icon: const Icon(Icons.add),
            label: Text(locale.submitComplaint),
          ),
          const SizedBox(height: 20),
          // Complaints List
          complaints.when(
            data: (complaintsList) {
              if (complaintsList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(locale.noComplaints),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: complaintsList.length,
                itemBuilder: (context, index) {
                  final complaint = complaintsList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  complaint.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: complaint.status == 'resolved'
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  complaint.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: complaint.status == 'resolved'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            complaint.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            complaint.createdAt.toString().split(' ')[0],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Center(
              child: Text('Error: $err'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitComplaintDialog(
    BuildContext context,
    AppLocalizations locale,
    WidgetRef ref,
    String? userId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.submitComplaint),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: locale.complaintTitle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: locale.complaintDescription,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // Submit complaint logic
              Navigator.pop(context);
              _titleController.clear();
              _descriptionController.clear();
            },
            child: Text(locale.submitComplaint),
          ),
        ],
      ),
    );
  }
}
