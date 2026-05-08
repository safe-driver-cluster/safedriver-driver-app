import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_driver_driver_app/l10n/app_localizations.dart';

import '../../../data/models/bus_model.dart';
import '../../../providers/auth_provider.dart';

// Provider to fetch buses assigned to the current driver
final assignedBusesProvider = StreamProvider.autoDispose<List<BusModel>>((ref) {
  final driverId = ref.watch(currentDriverIdProvider);
  if (driverId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('vehicles')
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return BusModel.fromJson(data);
    }).toList();
  });
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
      body: busesAsync.when(
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(assignedBusesProvider),
                child: const Text('Retry'),
              ),
            ],
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
                        bus.busNumber,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        bus.registration,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    bus.statusDisplay,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: _getStatusColor(bus.status),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(l10n.route, bus.routeDisplay, Icons.route),
            const SizedBox(height: 8),
            _buildInfoRow(l10n.capacity, '${bus.passengerCapacity} passengers',
                Icons.people),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Mileage', '${bus.maintenanceInfo.mileage} km', Icons.speed),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Model',
                '${bus.specifications.manufacturer} ${bus.specifications.model}',
                Icons.info),
            const SizedBox(height: 8),
            _buildInfoRow('Safety Score',
                '${bus.safetyScore.toStringAsFixed(1)}/100', Icons.security),
            if (bus.currentLocation != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                  'Location',
                  bus.currentLocation!.address ??
                      'GPS: ${bus.currentLocation!.latitude.toStringAsFixed(4)}, ${bus.currentLocation!.longitude.toStringAsFixed(4)}',
                  Icons.location_on),
            ],
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

  Color _getStatusColor(BusStatus status) {
    switch (status) {
      case BusStatus.online:
      case BusStatus.active:
      case BusStatus.inTransit:
      case BusStatus.enRoute:
        return Colors.green.shade100;
      case BusStatus.atStop:
        return Colors.blue.shade100;
      case BusStatus.maintenance:
        return Colors.orange.shade100;
      case BusStatus.emergency:
        return Colors.red.shade100;
      case BusStatus.offline:
        return Colors.grey.shade100;
    }
  }
}
