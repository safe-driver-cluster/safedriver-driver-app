import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_font_weights.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/constants/design_constants.dart';
import '../../../core/utils/theme_helper.dart';
import '../../../data/models/driver_models.dart';
import '../../../data/services/driver_data_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_controller.dart';
import '../../widgets/common/professional_widgets.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _fallbackCenter = LatLng(6.9271, 79.8612);

  final _searchController = TextEditingController();
  final _service = DriverDataService();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPosition;
  DriverBus? _assignedBus;
  DriverHazardZone? _selectedHazard;
  bool _locating = false;
  bool _hazardsVisible = false;
  bool _trafficEnabled = false;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _locateDriver(showErrors: false),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _locateDriver({bool showErrors = true}) async {
    if (_locating) return;
    setState(() => _locating = true);
    var usedLastKnownPosition = false;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (showErrors) {
          _message(
            'Turn on location services to show your live position.',
            action: SnackBarAction(
              label: 'Location',
              onPressed: Geolocator.openLocationSettings,
            ),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showErrors) {
          _message(
            permission == LocationPermission.deniedForever
                ? 'Location permission is disabled in app settings.'
                : 'Location permission is required to show your position.',
            action: permission == LocationPermission.deniedForever
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: Geolocator.openAppSettings,
                  )
                : null,
          );
        }
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        usedLastKnownPosition = true;
        _updatePosition(lastKnown, moveMap: true);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      _updatePosition(position, moveMap: true);
      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(_updatePosition);
    } on TimeoutException {
      if (showErrors && !usedLastKnownPosition) {
        _message(
          'Waiting for GPS. On emulator, set a location from Extended controls.',
        );
      }
    } catch (_) {
      if (showErrors && !usedLastKnownPosition) {
        _message(
          'Could not get your current location. Check location permission and GPS.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _updatePosition(Position position, {bool moveMap = false}) {
    if (!mounted) return;
    final point = LatLng(position.latitude, position.longitude);
    setState(() => _currentPosition = point);
    if (moveMap) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    }
  }

  Future<void> _zoom(double amount) async {
    final controller = _mapController;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.zoomTo((zoom + amount).clamp(3, 20)),
    );
  }

  void _focusAssignedBus() {
    final bus = _assignedBus;
    if (bus?.latitude == null || bus?.longitude == null) {
      _message('The assigned bus has not shared a location yet.');
      return;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(bus!.latitude!, bus.longitude!), 16),
    );
  }

  Future<void> _openNavigation() async {
    final query = _searchController.text.trim();
    final bus = _assignedBus;
    final destination = query.isNotEmpty
        ? query
        : bus?.latitude != null && bus?.longitude != null
        ? '${bus!.latitude},${bus.longitude}'
        : AppScope.of(context).driver!.currentRoute.trim().isEmpty
        ? 'bus depot'
        : AppScope.of(context).driver!.currentRoute;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _message('Could not open navigation on this device.');
    }
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_searchController.text.trim().isEmpty) {
      _message('Enter a destination, bus stop, or route.');
      return;
    }
    await _openNavigation();
  }

  void _message(String text, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  void _showHazards(List<DriverHazardZone> hazards) {
    if (hazards.isEmpty) {
      _message('No hazard zones are available.');
      return;
    }
    setState(() {
      _hazardsVisible = true;
      _selectedHazard = null;
    });
    _fitHazards(hazards);
  }

  void _selectHazard(DriverHazardZone hazard) {
    setState(() => _selectedHazard = hazard);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(hazard.latitude, hazard.longitude)),
    );
  }

  void _fitHazards(List<DriverHazardZone> hazards) {
    final controller = _mapController;
    if (controller == null || hazards.isEmpty) return;
    final points = <LatLng>[
      if (_currentPosition != null) _currentPosition!,
      ...hazards.map((hazard) => LatLng(hazard.latitude, hazard.longitude)),
    ];
    if (points.length == 1) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        64,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = AppScope.of(context).driver!;
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<DriverBus>>(
      stream: _service.buses(driver),
      builder: (context, busSnapshot) {
        final buses = busSnapshot.data ?? const <DriverBus>[];
        _assignedBus = buses.isEmpty ? null : buses.first;
        return StreamBuilder<List<DriverHazardZone>>(
          stream: _service.hazardZones(),
          builder: (context, hazardSnapshot) {
            final hazards = hazardSnapshot.data ?? const <DriverHazardZone>[];
            return DriverPageShell(
              title: 'Maps & Navigation',
              subtitle: driver.currentRoute.isEmpty
                  ? l10n.t('routeGuidance')
                  : driver.currentRoute,
              body: _MapBody(
                searchController: _searchController,
                map: _buildMap(hazards),
                hazards: hazards,
                hazardsVisible: _hazardsVisible,
                selectedHazard: _selectedHazard,
                bus: _assignedBus,
                locating: _locating,
                trafficEnabled: _trafficEnabled,
                onSearch: _search,
                onNavigate: _openNavigation,
                onHazards: () => _showHazards(hazards),
                onCloseHazard: () => setState(() => _selectedHazard = null),
                onBus: _focusAssignedBus,
                onZoomIn: () => _zoom(1),
                onZoomOut: () => _zoom(-1),
                onMapStyle: () => setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.hybrid
                      : MapType.normal;
                }),
                onTraffic: () =>
                    setState(() => _trafficEnabled = !_trafficEnabled),
                onLocate: _locateDriver,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMap(List<DriverHazardZone> hazards) {
    final markers = <Marker>{
      if (_assignedBus?.latitude != null && _assignedBus?.longitude != null)
        Marker(
          markerId: const MarkerId('assigned_bus'),
          position: LatLng(_assignedBus!.latitude!, _assignedBus!.longitude!),
          infoWindow: InfoWindow(
            title: _assignedBus!.busNumber,
            snippet: _assignedBus!.locationAddress.isEmpty
                ? _assignedBus!.locationDepot
                : _assignedBus!.locationAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
      if (_hazardsVisible)
        ...hazards.map(
          (hazard) => Marker(
            markerId: MarkerId('hazard_${hazard.id}'),
            position: LatLng(hazard.latitude, hazard.longitude),
            infoWindow: InfoWindow(
              title: hazard.name,
              snippet:
                  '${_hazardTypeLabel(hazard.type)} - ${hazard.radiusMeters.toStringAsFixed(0)} m radius',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _hazardMarkerHue(hazard.type),
            ),
            onTap: () => _selectHazard(hazard),
          ),
        ),
    };
    final circles = _hazardsVisible
        ? hazards
              .map(
                (hazard) => Circle(
                  circleId: CircleId('hazard_radius_${hazard.id}'),
                  center: LatLng(hazard.latitude, hazard.longitude),
                  radius: hazard.radiusMeters <= 0 ? 250 : hazard.radiusMeters,
                  fillColor: _hazardColor(hazard.type).withValues(alpha: 0.16),
                  strokeColor: _hazardColor(hazard.type),
                  strokeWidth: 2,
                ),
              )
              .toSet()
        : const <Circle>{};

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _fallbackCenter,
        zoom: 14,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 16),
          );
        }
      },
      markers: markers,
      circles: circles,
      mapType: _mapType,
      trafficEnabled: _trafficEnabled,
      myLocationEnabled: _currentPosition != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      compassEnabled: true,
      onTap: (_) {
        if (_selectedHazard != null) setState(() => _selectedHazard = null);
      },
    );
  }

  Color _hazardColor(String type) {
    switch (type.toLowerCase().trim()) {
      case 'accident':
        return AppColors.dangerColor;
      case 'construction':
        return AppColors.warningColor;
      case 'flood':
      case 'flooding':
        return AppColors.infoColor;
      case 'traffic':
      case 'heavy_traffic':
        return Colors.deepOrange;
      case 'restricted':
      case 'restricted_area':
      case 'road_closed':
        return AppColors.purpleColor;
      default:
        return AppColors.textSecondary;
    }
  }

  double _hazardMarkerHue(String type) {
    switch (type.toLowerCase().trim()) {
      case 'accident':
        return BitmapDescriptor.hueRed;
      case 'construction':
        return BitmapDescriptor.hueYellow;
      case 'flood':
      case 'flooding':
        return BitmapDescriptor.hueAzure;
      case 'traffic':
      case 'heavy_traffic':
        return BitmapDescriptor.hueOrange;
      case 'restricted':
      case 'restricted_area':
      case 'road_closed':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRose;
    }
  }

  String _hazardTypeLabel(String type) {
    if (type.trim().isEmpty) return 'Hazard';
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({
    required this.searchController,
    required this.map,
    required this.hazards,
    required this.hazardsVisible,
    required this.selectedHazard,
    required this.bus,
    required this.locating,
    required this.trafficEnabled,
    required this.onSearch,
    required this.onNavigate,
    required this.onHazards,
    required this.onCloseHazard,
    required this.onBus,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMapStyle,
    required this.onTraffic,
    required this.onLocate,
  });

  final TextEditingController searchController;
  final Widget map;
  final List<DriverHazardZone> hazards;
  final bool hazardsVisible;
  final DriverHazardZone? selectedHazard;
  final DriverBus? bus;
  final bool locating;
  final bool trafficEnabled;
  final VoidCallback onSearch;
  final VoidCallback onNavigate;
  final VoidCallback onHazards;
  final VoidCallback onCloseHazard;
  final VoidCallback onBus;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMapStyle;
  final VoidCallback onTraffic;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Container(
      color: th.subtleBackground,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search destination, bus stop, or route',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Search in Google Maps',
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: th.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: th.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PrimaryAction(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.dangerColor,
                  label: hazards.isEmpty
                      ? 'Hazards'
                      : hazardsVisible
                      ? 'Hazards on map (${hazards.length})'
                      : 'Hazards (${hazards.length})',
                  onTap: onHazards,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PrimaryAction(
                  icon: Icons.navigation_rounded,
                  color: AppColors.purpleColor,
                  label: 'Navigate',
                  onTap: onNavigate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(child: map),
                  if (bus != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      right: 76,
                      child: _BusMapCard(bus: bus!, onTap: onBus),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Column(
                      children: [
                        _MapControl(icon: Icons.add_rounded, onTap: onZoomIn),
                        const SizedBox(height: 8),
                        _MapControl(
                          icon: Icons.remove_rounded,
                          onTap: onZoomOut,
                        ),
                        const SizedBox(height: 8),
                        _MapControl(
                          icon: Icons.layers_rounded,
                          onTap: onMapStyle,
                        ),
                        const SizedBox(height: 8),
                        _MapControl(
                          icon: Icons.traffic_rounded,
                          active: trafficEnabled,
                          onTap: onTraffic,
                        ),
                        const SizedBox(height: 8),
                        _MapControl(
                          icon: Icons.directions_bus_rounded,
                          onTap: onBus,
                        ),
                        const SizedBox(height: 8),
                        _MapControl(
                          icon: locating
                              ? Icons.hourglass_top_rounded
                              : Icons.my_location_rounded,
                          onTap: onLocate,
                        ),
                      ],
                    ),
                  ),
                  if (selectedHazard != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _HazardDetailsCard(
                        hazard: selectedHazard!,
                        onClose: onCloseHazard,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Material(
      color: th.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: th.borderColor),
            boxShadow: th.isDark ? null : AppDesign.shadowSM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: th.textPrimary,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.primaryColor
          : ThemeHelper.of(context).cardBackground,
      elevation: 3,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _BusMapCard extends StatelessWidget {
  const _BusMapCard({required this.bus, required this.onTap});

  final DriverBus bus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = bus.locationAddress.isNotEmpty
        ? bus.locationAddress
        : bus.locationDepot;
    return Material(
      color: ThemeHelper.of(context).cardBackground.withValues(alpha: 0.94),
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.cardTint,
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.busNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: AppFontWeights.extraBold,
                      ),
                    ),
                    Text(
                      location.isEmpty ? 'Assigned bus' : location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: ThemeHelper.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HazardDetailsCard extends StatelessWidget {
  const _HazardDetailsCard({required this.hazard, required this.onClose});

  final DriverHazardZone hazard;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Material(
      color: th.cardBackground.withValues(alpha: 0.96),
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.dangerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppColors.dangerColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hazard.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: AppFontWeights.extraBold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${hazard.type.replaceAll('_', ' ')} - ${hazard.radiusMeters.toStringAsFixed(0)} m radius',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.dangerColor,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hazard.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: th.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: th.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
