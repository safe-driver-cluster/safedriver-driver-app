import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  static const _standardTiles =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const _detailTiles =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _service = DriverDataService();

  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentPosition;
  DriverBus? _assignedBus;
  bool _locating = false;
  bool _detailMap = false;
  bool _hazardsVisible = false;

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
    _mapController.dispose();
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
    if (moveMap) _mapController.move(point, 16);
  }

  void _zoom(double amount) {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + amount).clamp(3, 19));
  }

  void _focusAssignedBus() {
    final bus = _assignedBus;
    if (bus?.latitude == null || bus?.longitude == null) {
      _message('The assigned bus has not shared a location yet.');
      return;
    }
    _mapController.move(LatLng(bus!.latitude!, bus.longitude!), 16);
  }

  Future<void> _openNavigation() async {
    final query = _searchController.text.trim();
    final bus = _assignedBus;
    final destination = query.isNotEmpty
        ? Uri.encodeComponent(query)
        : bus?.latitude != null && bus?.longitude != null
        ? '${bus!.latitude},${bus.longitude}'
        : Uri.encodeComponent(
            AppScope.of(context).driver!.currentRoute.trim().isEmpty
                ? 'bus depot'
                : AppScope.of(context).driver!.currentRoute,
          );
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination'
      '&travelmode=driving',
    );
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
    if (hazards.isNotEmpty) {
      setState(() => _hazardsVisible = true);
      final first = hazards.first;
      _mapController.move(LatLng(first.latitude, first.longitude), 15);
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        builder: (context, controller) =>
            _HazardSheet(hazards: hazards, controller: controller),
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
                bus: _assignedBus,
                locating: _locating,
                onSearch: _search,
                onNavigate: _openNavigation,
                onHazards: () => _showHazards(hazards),
                onBus: _focusAssignedBus,
                onZoomIn: () => _zoom(1),
                onZoomOut: () => _zoom(-1),
                onMapStyle: () => setState(() => _detailMap = !_detailMap),
                onLocate: _locateDriver,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMap(List<DriverHazardZone> hazards) {
    final markers = <Marker>[
      if (_currentPosition != null)
        Marker(
          point: _currentPosition!,
          width: 54,
          height: 64,
          child: const _MapMarker(
            icon: Icons.navigation_rounded,
            color: AppColors.primaryColor,
            label: 'You',
          ),
        ),
      if (_assignedBus?.latitude != null && _assignedBus?.longitude != null)
        Marker(
          point: LatLng(_assignedBus!.latitude!, _assignedBus!.longitude!),
          width: 64,
          height: 70,
          child: _MapMarker(
            icon: Icons.directions_bus_rounded,
            color: AppColors.purpleColor,
            label: _assignedBus!.busNumber,
          ),
        ),
      if (_hazardsVisible) ...hazards.map(_hazardMarker),
    ];
    final hazardCircles = _hazardsVisible
        ? hazards.map(_hazardCircle).toList()
        : const <CircleMarker>[];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? _fallbackCenter,
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _detailMap ? _detailTiles : _standardTiles,
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.safedriver.driver',
        ),
        if (hazardCircles.isNotEmpty)
          CircleLayer(circles: hazardCircles, optimizeRadiusInMeters: true),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
            TextSourceAttribution('CARTO'),
          ],
        ),
      ],
    );
  }

  Marker _hazardMarker(DriverHazardZone hazard) {
    return Marker(
      point: LatLng(hazard.latitude, hazard.longitude),
      width: 58,
      height: 58,
      child: Tooltip(
        message: hazard.name,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppDesign.shadowSM,
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: AppColors.dangerColor,
            size: 38,
          ),
        ),
      ),
    );
  }

  CircleMarker _hazardCircle(DriverHazardZone hazard) {
    return CircleMarker(
      point: LatLng(hazard.latitude, hazard.longitude),
      radius: hazard.radiusMeters <= 0 ? 250 : hazard.radiusMeters,
      useRadiusInMeter: true,
      color: AppColors.dangerColor.withValues(alpha: 0.16),
      borderColor: AppColors.dangerColor.withValues(alpha: 0.55),
      borderStrokeWidth: 2,
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({
    required this.searchController,
    required this.map,
    required this.hazards,
    required this.hazardsVisible,
    required this.bus,
    required this.locating,
    required this.onSearch,
    required this.onNavigate,
    required this.onHazards,
    required this.onBus,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMapStyle,
    required this.onLocate,
  });

  final TextEditingController searchController;
  final Widget map;
  final List<DriverHazardZone> hazards;
  final bool hazardsVisible;
  final DriverBus? bus;
  final bool locating;
  final VoidCallback onSearch;
  final VoidCallback onNavigate;
  final VoidCallback onHazards;
  final VoidCallback onBus;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMapStyle;
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
                tooltip: 'Search in maps',
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
  const _MapControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ThemeHelper.of(context).cardBackground,
      elevation: 3,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.primaryColor),
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

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(Icons.location_on_rounded, color: color, size: 58),
          Positioned(top: 8, child: Icon(icon, color: Colors.white, size: 23)),
        ],
      ),
    );
  }
}

class _HazardSheet extends StatelessWidget {
  const _HazardSheet({required this.hazards, required this.controller});

  final List<DriverHazardZone> hazards;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    if (hazards.isEmpty) {
      return const Center(
        child: EmptyState(
          message: 'No hazard zones are available.',
          icon: Icons.verified_user_rounded,
        ),
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: hazards.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Hazard zones shown on map',
              style: AppTextStyles.headline3,
            ),
          );
        }
        final hazard = hazards[index - 1];
        return ListTile(
          tileColor: AppColors.dangerColor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: const Icon(
            Icons.warning_rounded,
            color: AppColors.dangerColor,
          ),
          title: Text(hazard.name),
          subtitle: Text(
            '${hazard.location} - ${hazard.radiusMeters.toStringAsFixed(0)} m radius',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            hazard.type,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.dangerColor,
              fontWeight: AppFontWeights.bold,
            ),
          ),
        );
      },
    );
  }
}
