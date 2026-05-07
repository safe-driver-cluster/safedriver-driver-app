import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    final List<Map<String, dynamic>> menuItems = [
      {'title': l10n.myAttendance, 'icon': Icons.calendar_today, 'color': Colors.orange},
      {'title': l10n.myBuses, 'icon': Icons.directions_bus, 'color': Colors.blue},
      {'title': l10n.myAlerts, 'icon': Icons.notifications_active, 'color': Colors.red},
      {'title': l10n.ratings, 'icon': Icons.star, 'color': Colors.amber},
      {'title': l10n.complain, 'icon': Icons.report_problem, 'color': Colors.purple},
      {'title': l10n.myProfile, 'icon': Icons.person, 'color': Colors.teal},
      {'title': l10n.map, 'icon': Icons.map, 'color': Colors.green},
      {'title': l10n.helpSupport, 'icon': Icons.help, 'color': Colors.blueGrey},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              ref.read(languageProvider.notifier).setLocale(locale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('English')),
              const PopupMenuItem(value: Locale('si'), child: Text('සිංහල')),
              const PopupMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () {
                  // Navigation logic will be added here
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'], size: 40, color: item['color']),
                    const SizedBox(height: 12),
                    Text(
                      item['title'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
