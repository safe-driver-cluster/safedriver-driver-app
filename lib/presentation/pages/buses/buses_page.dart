import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/bus_model.dart';
import '../../../providers/auth_provider.dart';

final assignedBusesProvider =
    FutureProvider.autoDispose<List<BusModel>>((ref) async {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('vehicles')
      .where('driverId', isEqualTo: driverId)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return BusModel.fromJson(data);
  }).toList();
});

class BusesPage extends ConsumerWidget {
  const BusesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final busesAsync = ref.watch(assignedBusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBuses),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(assignedBusesProvider);
        },
        child: busesAsync.when(
          data: (buses) {
            if (buses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_bus_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noBusesAssigned,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final bus = buses[index];
                return _buildBusCard(context, l10n, bus);
              },
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
      ),
    );
  }

  Widget _buildBusCard(
      BuildContext context, AppLocalizations l10n, BusModel bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.busNumberPlate,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        bus.model,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    bus.status.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getStatusColor(bus.status),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
                l10n.route, bus.routeId ?? 'Not assigned', Icons.route),
            const SizedBox(height: 8),
            _buildInfoRow(
                l10n.capacity, '${bus.capacity} passengers', Icons.people),
            const SizedBox(height: 8),
            _buildInfoRow('Mileage', '${bus.mileage} km', Icons.speed),
            const SizedBox(height: 8),
            _buildInfoRow('Year', bus.year.toString(), Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.shade100;
      case 'maintenance':
        return Colors.orange.shade100;
      case 'inactive':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
