import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/arb/app_localizations.dart';
import 'package:safe_driver_driver_app/providers/providers.dart';

class BusesTab extends ConsumerWidget {
  const BusesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final buses = userId != null
        ? ref.watch(busesStreamProvider(userId))
        : const AsyncValue.loading();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale!.myBuses,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          buses.when(
            data: (busesList) {
              if (busesList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(locale.noData),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: busesList.length,
                itemBuilder: (context, index) {
                  final bus = busesList[index];
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
                              Text(
                                bus.busNumber,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: bus.status == 'active'
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  bus.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: bus.status == 'active'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Route: ${bus.route}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Capacity: ${bus.capacity}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }
}
