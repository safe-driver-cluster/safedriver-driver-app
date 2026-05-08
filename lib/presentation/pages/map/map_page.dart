import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_driver_driver_app/l10n/app_localizations.dart';

import '../../../providers/auth_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    final driver = ref.read(authDriverProvider).value;
    if (driver == null) return;

    try {
      // Get driver's current bus location from VEHICLES table
      final vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('driverId', isEqualTo: driver.id)
          .limit(1)
          .get();

      if (vehicleSnapshot.docs.isEmpty) return;

      final vehicleData = vehicleSnapshot.docs.first.data();
      final location = vehicleData['location'];

      if (location != null &&
          location['lat'] != null &&
          location['lng'] != null) {
        final busPosition = LatLng(
          location['lat'].toDouble(),
          location['lng'].toDouble(),
        );

        // Get route information from ROUTES table
        final routeId = vehicleData['routeId'];
        if (routeId != null) {
          final routeSnapshot = await FirebaseFirestore.instance
              .collection('routes')
              .doc(routeId)
              .get();

          if (routeSnapshot.exists) {
            final routeData = routeSnapshot.data()!;
            _buildRoutePolyline(routeData);
          }
        }

        setState(() {
          _markers = {
            Marker(
              markerId: const MarkerId('current_bus'),
              position: busPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: InfoWindow(
                title: 'My Bus',
                snippet: vehicleData['busNumber'] ?? 'Bus',
              ),
            ),
          };
        });

        // Move camera to bus location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(busPosition, 14),
        );
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
    }
  }

  void _buildRoutePolyline(Map<String, dynamic> routeData) {
    // Build polyline from route data if available
    // This is a simplified version - actual implementation would parse route coordinates
    final startPoint = routeData['startPoint'];
    final endPoint = routeData['endPoint'];

    if (startPoint != null && endPoint != null) {
      // Add start and end markers
      setState(() {
        _markers.addAll({
          Marker(
            markerId: const MarkerId('start'),
            position: LatLng(
              startPoint['lat']?.toDouble() ?? 0.0,
              startPoint['lng']?.toDouble() ?? 0.0,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Start Point'),
          ),
          Marker(
            markerId: const MarkerId('end'),
            position: LatLng(
              endPoint['lat']?.toDouble() ?? 0.0,
              endPoint['lng']?.toDouble() ?? 0.0,
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'End Point'),
          ),
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.map),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMapData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
          zoom: 12,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        onMapCreated: (controller) {
          _mapController = controller;
          _loadMapData();
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'route',
            onPressed: () {
              // Show route details
              _showRouteDetails();
            },
            child: const Icon(Icons.route),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'location',
            onPressed: () {
              // Center on current bus location
              _loadMapData();
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _showRouteDetails() async {
    final driver = ref.read(authDriverProvider).value;
    if (driver == null || driver.currentRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No route assigned')),
      );
      return;
    }

    // Fetch route details
    try {
      final routeSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .doc(driver.currentRoute)
          .get();

      if (!routeSnapshot.exists) return;

      final routeData = routeSnapshot.data()!;

      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routeData['name'] ?? 'Route',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildRouteInfo('Start', routeData['startPoint'] ?? 'N/A'),
                _buildRouteInfo('End', routeData['endPoint'] ?? 'N/A'),
                _buildRouteInfo('Distance', '${routeData['distance'] ?? 0} km'),
                _buildRouteInfo(
                    'Estimated Time', '${routeData['estimatedTime'] ?? 0} min'),
                _buildRouteInfo('Status', routeData['status'] ?? 'Unknown'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildRouteInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
