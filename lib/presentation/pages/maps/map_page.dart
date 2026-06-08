import 'dart:async';

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
  bool _hazardsVisible = true;
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
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showErrors) _message('Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _updatePosition(position, moveMap: true);
      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      ).listen(_updatePosition);
    } catch (_) {
      if (showErrors) _message('Could not get your current location.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _updatePosition(Position position, {bool moveMap = false}) {
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

  Future<void> _openNavigation() async {
    final driver = AppScope.of(context).driver!;
    final query = _searchController.text.trim();
    final bus = _assignedBus;
    final destination = query.isNotEmpty
        ? query
        : bus?.latitude != null && bus?.longitude != null
        ? '${bus!.latitude},${bus.longitude}'
        : driver.currentRoute.trim().isEmpty
        ? 'bus depot'
        : driver.currentRoute;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _message('Could not open Google Maps navigation.');
    }
  }

  void _focusBus() {
    final bus = _assignedBus;
    if (bus?.latitude == null || bus?.longitude == null) {
      _message('The assigned bus has not shared a location yet.');
      return;
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(bus!.latitude!, bus.longitude!), 16),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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
            return Scaffold(
              extendBody: true,
              body: _PassengerStyleMapScreen(
                title: 'Maps & Navigation',
                routeLabel: driver.currentRoute.isEmpty
                    ? l10n.t('routeGuidance')
                    : driver.currentRoute,
                searchController: _searchController,
                map: _buildMap(hazards),
                bus: _assignedBus,
                hazards: hazards,
                hazardsVisible: _hazardsVisible,
                trafficEnabled: _trafficEnabled,
                locating: _locating,
                selectedHazard: _selectedHazard,
                onBack: () => Navigator.maybePop(context),
                onSearch: _openNavigation,
                onNavigate: _openNavigation,
                onLocate: _locateDriver,
                onBus: _focusBus,
                onZoomIn: () => _zoom(1),
                onZoomOut: () => _zoom(-1),
                onToggleHazards: () =>
                    setState(() => _hazardsVisible = !_hazardsVisible),
                onToggleTraffic: () =>
                    setState(() => _trafficEnabled = !_trafficEnabled),
                onToggleMapType: () => setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.hybrid
                      : MapType.normal;
                }),
                onCloseHazard: () => setState(() => _selectedHazard = null),
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
          infoWindow: InfoWindow(title: _assignedBus!.busNumber),
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
                  '${_labelFor(hazard.type)} - radius ${hazard.radiusMeters.toStringAsFixed(0)} m',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            onTap: () => setState(() => _selectedHazard = hazard),
          ),
        ),
    };

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _fallbackCenter,
        zoom: 13,
      ),
      onMapCreated: (controller) => _mapController = controller,
      markers: markers,
      circles: _hazardsVisible
          ? hazards
                .map(
                  (hazard) => Circle(
                    circleId: CircleId('hazard_radius_${hazard.id}'),
                    center: LatLng(hazard.latitude, hazard.longitude),
                    radius: hazard.radiusMeters <= 0
                        ? 250
                        : hazard.radiusMeters,
                    fillColor: AppColors.dangerColor.withValues(alpha: 0.12),
                    strokeColor: AppColors.dangerColor,
                    strokeWidth: 2,
                  ),
                )
                .toSet()
          : const <Circle>{},
      mapType: _mapType,
      trafficEnabled: _trafficEnabled,
      myLocationEnabled: _currentPosition != null,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onTap: (_) => setState(() => _selectedHazard = null),
    );
  }

  String _labelFor(String value) {
    if (value.trim().isEmpty) return 'Hazard';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _PassengerStyleMapScreen extends StatelessWidget {
  const _PassengerStyleMapScreen({
    required this.title,
    required this.routeLabel,
    required this.searchController,
    required this.map,
    required this.bus,
    required this.hazards,
    required this.hazardsVisible,
    required this.trafficEnabled,
    required this.locating,
    required this.selectedHazard,
    required this.onBack,
    required this.onSearch,
    required this.onNavigate,
    required this.onLocate,
    required this.onBus,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleHazards,
    required this.onToggleTraffic,
    required this.onToggleMapType,
    required this.onCloseHazard,
  });

  final String title;
  final String routeLabel;
  final TextEditingController searchController;
  final Widget map;
  final DriverBus? bus;
  final List<DriverHazardZone> hazards;
  final bool hazardsVisible;
  final bool trafficEnabled;
  final bool locating;
  final DriverHazardZone? selectedHazard;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onNavigate;
  final VoidCallback onLocate;
  final VoidCallback onBus;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleHazards;
  final VoidCallback onToggleTraffic;
  final VoidCallback onToggleMapType;
  final VoidCallback onCloseHazard;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final horizontal = wide ? 24.0 : 14.0;
    final topGap = wide ? 12.0 : 10.0;
    final mapGap = wide ? 16.0 : 10.0;
    final endGap = wide ? 0.0 : 8.0;
    return Container(
      decoration: BoxDecoration(
        gradient: th.isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1A42), Color(0xFF071225)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF8DB5FF),
                ],
              ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, topGap, horizontal, endGap),
          child: wide
              ? Row(
                  children: [
                    SizedBox(
                      width: 430,
                      child: _TopControls(
                        title: title,
                        routeLabel: routeLabel,
                        searchController: searchController,
                        hazards: hazards,
                        hazardsVisible: hazardsVisible,
                        bus: bus,
                        onBack: onBack,
                        onSearch: onSearch,
                        onNavigate: onNavigate,
                        onToggleHazards: onToggleHazards,
                      ),
                    ),
                    SizedBox(width: mapGap),
                    Expanded(child: _mapCard()),
                  ],
                )
              : Column(
                  children: [
                    _TopControls(
                      title: title,
                      routeLabel: routeLabel,
                      searchController: searchController,
                      hazards: hazards,
                      hazardsVisible: hazardsVisible,
                      bus: bus,
                      onBack: onBack,
                      onSearch: onSearch,
                      onNavigate: onNavigate,
                      onToggleHazards: onToggleHazards,
                    ),
                    SizedBox(height: mapGap),
                    Expanded(child: _mapCard()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _mapCard() {
    return Builder(
      builder: (context) {
        final wide = MediaQuery.sizeOf(context).width >= 900;
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(child: map),
              Positioned(
                right: wide ? 16 : 12,
                top: wide ? 16 : 12,
                child: _FloatingMapControls(
                  locating: locating,
                  trafficEnabled: trafficEnabled,
                  onZoomIn: onZoomIn,
                  onZoomOut: onZoomOut,
                  onToggleMapType: onToggleMapType,
                  onToggleTraffic: onToggleTraffic,
                  onLocate: onLocate,
                ),
              ),
              if (bus != null && wide)
                Positioned(left: 20, top: 20, child: _BusMapPill(bus: bus!)),
              if (selectedHazard != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              if (selectedHazard != null)
                Positioned(
                  left: wide ? 18 : 12,
                  right: wide ? 18 : 12,
                  bottom: wide ? 18 : 12,
                  child: _HazardDetailsSheet(
                    hazard: selectedHazard!,
                    onClose: onCloseHazard,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.title,
    required this.routeLabel,
    required this.searchController,
    required this.hazards,
    required this.hazardsVisible,
    required this.bus,
    required this.onBack,
    required this.onSearch,
    required this.onNavigate,
    required this.onToggleHazards,
  });

  final String title;
  final String routeLabel;
  final TextEditingController searchController;
  final List<DriverHazardZone> hazards;
  final bool hazardsVisible;
  final DriverBus? bus;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onNavigate;
  final VoidCallback onToggleHazards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MapHeader(title: title, routeLabel: routeLabel, onBack: onBack),
        const SizedBox(height: 12),
        _SearchBox(controller: searchController, onSearch: onSearch),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PassengerActionButton(
                icon: Icons.warning_amber_rounded,
                label: hazardsVisible
                    ? 'Hazards'
                    : 'Hazards (${hazards.length})',
                color: AppColors.dangerColor,
                onTap: onToggleHazards,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PassengerActionButton(
                icon: Icons.directions_bus_rounded,
                label: 'Navigate',
                color: AppColors.purpleColor,
                onTap: onNavigate,
              ),
            ),
          ],
        ),
        if (bus != null) ...[const SizedBox(height: 9), _BusSummary(bus: bus!)],
      ],
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.title,
    required this.routeLabel,
    required this.onBack,
  });

  final String title;
  final String routeLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: const SizedBox(
              height: 48,
              width: 48,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline2.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: AppFontWeights.extraBold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                routeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Material(
      color: th.isDark ? const Color(0xFF0B111D) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        style: AppTextStyles.bodyMedium.copyWith(color: th.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search destination or bus stop',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: th.textSecondary.withValues(alpha: 0.72),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primaryColor,
            size: 22,
          ),
          suffixIcon: IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _PassengerActionButton extends StatelessWidget {
  const _PassengerActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    return Material(
      color: th.isDark ? const Color(0xFF111827) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: th.textPrimary,
                    fontSize: 15,
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

class _FloatingMapControls extends StatelessWidget {
  const _FloatingMapControls({
    required this.locating,
    required this.trafficEnabled,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onToggleMapType,
    required this.onToggleTraffic,
    required this.onLocate,
  });

  final bool locating;
  final bool trafficEnabled;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onToggleMapType;
  final VoidCallback onToggleTraffic;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapControl(icon: Icons.add_rounded, onTap: onZoomIn),
        const SizedBox(height: 8),
        _MapControl(icon: Icons.remove_rounded, onTap: onZoomOut),
        const SizedBox(height: 8),
        _MapControl(icon: Icons.image_rounded, onTap: onToggleMapType),
        const SizedBox(height: 8),
        _MapControl(
          icon: Icons.traffic_rounded,
          active: trafficEnabled,
          onTap: onToggleTraffic,
        ),
        const SizedBox(height: 8),
        _MapControl(
          icon: locating
              ? Icons.hourglass_top_rounded
              : Icons.my_location_rounded,
          onTap: onLocate,
        ),
      ],
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
    final th = ThemeHelper.of(context);
    return Material(
      color: active
          ? AppColors.primaryColor
          : th.isDark
          ? const Color(0xFF111827)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 44,
          width: 44,
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _BusSummary extends StatelessWidget {
  const _BusSummary({required this.bus});

  final DriverBus bus;

  @override
  Widget build(BuildContext context) {
    final th = ThemeHelper.of(context);
    final location = bus.locationAddress.isNotEmpty
        ? bus.locationAddress
        : bus.locationDepot;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: th.isDark ? 0.08 : 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cardTint,
            child: Icon(
              Icons.directions_bus_rounded,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bus.busNumber,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                Text(
                  location.isEmpty ? 'Assigned bus' : location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusMapPill extends StatelessWidget {
  const _BusMapPill({required this.bus});

  final DriverBus bus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus_rounded,
              color: AppColors.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              bus.busNumber,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppFontWeights.extraBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HazardDetailsSheet extends StatelessWidget {
  const _HazardDetailsSheet({required this.hazard, required this.onClose});

  final DriverHazardZone hazard;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1F2B3F),
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.dangerColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.car_crash_rounded,
                    color: AppColors.dangerColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hazard.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headline3.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: AppFontWeights.extraBold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labelFor(hazard.type),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.dangerColor,
                          fontWeight: AppFontWeights.extraBold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFD1D5DB),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HazardInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Location',
              value: hazard.location.isEmpty
                  ? 'Detected Location'
                  : hazard.location,
            ),
            _HazardInfoRow(
              icon: Icons.radar_rounded,
              label: 'Radius',
              value: '${hazard.radiusMeters.toStringAsFixed(0)} m',
            ),
            _HazardInfoRow(
              icon: Icons.gps_fixed_rounded,
              label: 'Coordinates',
              value:
                  '${hazard.latitude.toStringAsFixed(5)}, ${hazard.longitude.toStringAsFixed(5)}',
            ),
            if (hazard.updatedAt != null)
              _HazardInfoRow(
                icon: Icons.access_time_rounded,
                label: 'Updated',
                value: _formatDate(hazard.updatedAt!),
              ),
            if (hazard.createdAt != null)
              _HazardInfoRow(
                icon: Icons.add_circle_outline_rounded,
                label: 'Created',
                value: _formatDate(hazard.createdAt!),
              ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String value) {
    if (value.trim().isEmpty) return 'Hazard';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatDate(DateTime value) {
    return '${value.month}/${value.day}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _HazardInfoRow extends StatelessWidget {
  const _HazardInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFB9C3D5),
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: AppFontWeights.extraBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
