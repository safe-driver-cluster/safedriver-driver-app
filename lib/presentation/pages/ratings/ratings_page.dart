import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safe_driver_driver_app/l10n/app_localizations.dart';

import '../../../providers/auth_provider.dart';

// Model for Feedback from FEEDBACK table
class FeedbackModel {
  final String feedbackId;
  final String userId;
  final String busId;
  final String busNumber;
  final String driverId;
  final String category;
  final String comment;
  final String description;
  final Map<String, dynamic>? location;
  final List<String> attachments;
  final List<String> images;
  final int helpfulCount;
  final bool isAnonymous;
  final bool isPublic;
  final DateTime createdAt;

  FeedbackModel({
    required this.feedbackId,
    required this.userId,
    required this.busId,
    required this.busNumber,
    required this.driverId,
    required this.category,
    required this.comment,
    required this.description,
    this.location,
    required this.attachments,
    required this.images,
    required this.helpfulCount,
    required this.isAnonymous,
    required this.isPublic,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      feedbackId: json['feedbackId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      busId: json['busId'] ?? '',
      busNumber: json['busNumber'] ?? '',
      driverId: json['driverId'] ?? '',
      category: json['category'] ?? '',
      comment: json['comment'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      attachments: List<String>.from(json['attachments'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      helpfulCount: json['helpfulCount'] ?? 0,
      isAnonymous: json['isAnonymous'] ?? false,
      isPublic: json['isPublic'] ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(
              json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Provider to fetch feedback for current driver
final driverFeedbackProvider =
    StreamProvider.autoDispose<List<FeedbackModel>>((ref) {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('feedback')
      .where('driverId', isEqualTo: driverId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return FeedbackModel.fromJson(data);
    }).toList();
  });
});

// Provider to calculate average rating
final averageRatingProvider = Provider.autoDispose<double>((ref) {
  final feedbackAsync = ref.watch(driverFeedbackProvider);
  return feedbackAsync.when(
    data: (feedbacks) {
      if (feedbacks.isEmpty) return 0.0;
      // Calculate based on positive feedback count
      final positiveCount = feedbacks
          .where((f) =>
              f.category.toLowerCase().contains('good') ||
              f.category.toLowerCase().contains('excellent') ||
              f.category.toLowerCase().contains('polite'))
          .length;
      return (positiveCount / feedbacks.length) * 5.0;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

class RatingsPage extends ConsumerWidget {
  const RatingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feedbackAsync = ref.watch(driverFeedbackProvider);
    final averageRating = ref.watch(averageRatingProvider);
    final driver = ref.watch(authDriverProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ratings),
      ),
      body: feedbackAsync.when(
        data: (feedbacks) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Rating Summary Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.yourRating,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 48),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.totalRatings}: ${feedbacks.length}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        if (driver != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Safety Score: ${driver.safetyScore.toStringAsFixed(1)}/100',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Feedback Section
                Text(
                  l10n.recentFeedback,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                if (feedbacks.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.star_border,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noRatingsYet,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...feedbacks
                      .map((feedback) => _buildFeedbackCard(context, feedback)),
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

  Widget _buildFeedbackCard(BuildContext context, FeedbackModel feedback) {
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(feedback.category),
                  color: _getCategoryColor(feedback.category),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feedback.category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (!feedback.isAnonymous)
                  const Icon(Icons.person, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            if (feedback.comment.isNotEmpty)
              Text(
                feedback.comment,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (feedback.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                feedback.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(feedback.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                if (feedback.helpfulCount > 0)
                  Row(
                    children: [
                      const Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${feedback.helpfulCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('driving') || cat.contains('behaviour'))
      return Icons.drive_eta;
    if (cat.contains('polite') || cat.contains('friendly'))
      return Icons.sentiment_satisfied;
    if (cat.contains('safety')) return Icons.security;
    if (cat.contains('speed')) return Icons.speed;
    return Icons.feedback;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('good') ||
        cat.contains('excellent') ||
        cat.contains('polite')) {
      return Colors.green;
    }
    if (cat.contains('bad') || cat.contains('poor') || cat.contains('rude')) {
      return Colors.red;
    }
    return Colors.blue;
  }
}
