import 'package:flutter/material.dart';
import '../../../l10n/arb/app_localizations.dart';

class HelpSupportTab extends StatelessWidget {
  const HelpSupportTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale!.helpSupport,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 24),
          // FAQ Section
          _buildSection(
            context,
            title: locale.faq,
            icon: Icons.help,
            items: [
              _FAQItem(
                question: 'How do I check in?',
                answer:
                    'To check in, navigate to the Home tab and click the Check In button. Your location will be recorded.',
              ),
              _FAQItem(
                question: 'How can I submit a complaint?',
                answer:
                    'Go to the Complaints section from the menu and click "Submit Complaint" to file a new complaint with admin.',
              ),
              _FAQItem(
                question: 'Where can I see my attendance?',
                answer:
                    'Your attendance records are available in the Attendance tab at the bottom of the screen.',
              ),
              _FAQItem(
                question: 'How do I update my profile picture?',
                answer:
                    'In the Profile tab, click "Update Profile Picture" to upload a new photo. Other profile details cannot be edited.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Contact Section
          _buildContactSection(context, locale),
          const SizedBox(height: 24),
          // Support Resources
          _buildSection(
            context,
            title: 'Support Resources',
            icon: Icons.library_books,
            items: [
              _SupportItem(
                title: locale.privacyPolicy,
                icon: Icons.privacy_tip,
              ),
              _SupportItem(
                title: locale.termsConditions,
                icon: Icons.description,
              ),
              _SupportItem(
                title: 'User Guide',
                icon: Icons.menu_book,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<dynamic> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) {
          if (item is _FAQItem) {
            return _FAQTile(item: item);
          } else if (item is _SupportItem) {
            return _SupportTile(item: item);
          }
          return const SizedBox();
        }).toList(),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_support, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Text(
              locale.contactUs,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.phone, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text('+94 11 234 5678'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.email, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text('support@safedriver.lk'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('123 Main Street, Colombo, Sri Lanka'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({required this.question, required this.answer});
}

class _SupportItem {
  final String title;
  final IconData icon;

  _SupportItem({required this.title, required this.icon});
}

class _FAQTile extends StatefulWidget {
  final _FAQItem item;

  const _FAQTile({required this.item});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          widget.item.question,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.item.answer,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final _SupportItem item;

  const _SupportTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(item.icon),
        title: Text(item.title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {},
      ),
    );
  }
}
