import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:zenjigodriver/core/api/driver_api.dart';
import 'package:zenjigodriver/core/friendly_errors.dart';
import 'package:zenjigodriver/core/map/map_markers.dart';
import 'package:zenjigodriver/core/map/map_style.dart';
import 'package:zenjigodriver/core/map/map_widgets.dart';
import 'package:zenjigodriver/core/map/route_utils.dart';
import 'package:zenjigodriver/core/utils/directions_service.dart';

/// Professional live map for drivers — same road-following quality as the rider app.
///
/// - Google Routes API → OSRM fallback (never a silent straight line when roads exist)
/// - Dual glow + solid polylines along real roads
/// - Custom canvas markers (driver / pickup / drop-off / nearby riders)
/// - Styled dark / light map
class LiveDriverMap extends StatefulWidget {
  const LiveDriverMap({
    super.key,
    this.height = 320,
    this.showRequests = true,
    this.activeRideId,
    this.shareLocation = false,
    this.isSwahili = false,
    this.isDark = true,
  });

  final double height;
  final bool showRequests;
  final String? activeRideId;
  final bool shareLocation;
  final bool isSwahili;
  final bool isDark;

  @override
  State<LiveDriverMap> createState() => _LiveDriverMapState();
}

class _LiveDriverMapState extends State<LiveDriverMap> {
  gmaps.GoogleMapController? _controller;
  Position? _position;
  List<dynamic> _requests = [];
  Map<String, dynamic>? _ride;
  Timer? _locationTimer;
  Timer? _pollTimer;
  String? _mapError;
  bool _locationPermission = false;

  List<gmaps.LatLng> _routePoints = [];
  RouteResult? _routeMeta;
  List<gmaps.LatLng> _toPickupPoints = [];
  MapMarkerSet? _markers;
  bool _routeLoading = false;

  static const gmaps.LatLng _defaultCenter = gmaps.LatLng(-6.1659, 39.2026);

  String t(String en, String sw) => widget.isSwahili ? sw : en;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _initLocation();
    _refreshRemote();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshRemote());
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateLocation());
  }

  @override
  void didUpdateWidget(covariant LiveDriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRideId != widget.activeRideId ||
        oldWidget.showRequests != widget.showRequests ||
        oldWidget.shareLocation != widget.shareLocation) {
      _refreshRemote();
    }
    if (oldWidget.isDark != widget.isDark && _controller != null) {
      _controller!.setMapStyle(widget.isDark ? MapStyles.dark : MapStyles.light);
    }
  }

  Future<void> _loadMarkers() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final set = await MapMarkers.load(ratio);
    if (mounted) setState(() => _markers = set);
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _mapError = t(
                'Allow location access to share your live position.',
                'Ruhusu eneo ili kushiriki nafasi yako moja kwa moja.',
              ));
        }
        return;
      }
      _locationPermission = true;
      await _updateLocation();
    } catch (e) {
      if (mounted) {
        setState(() => _mapError = FriendlyErrors.message(e, swahili: widget.isSwahili));
      }
    }
  }

  Future<void> _updateLocation() async {
    if (!_locationPermission) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = pos;
        _mapError = null;
      });
      if (widget.shareLocation || widget.activeRideId != null) {
        try {
          await DriverApi.updateLocation(
            pos.latitude,
            pos.longitude,
            heading: pos.heading.isFinite ? pos.heading : null,
            speed: pos.speed.isFinite ? pos.speed : null,
          );
        } catch (_) {}
        // Refresh driver→target road path when we move
        if (widget.activeRideId != null) {
          unawaited(_rebuildRoutes());
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshRemote() async {
    try {
      if (widget.activeRideId != null) {
        final result = await DriverApi.history(limit: 100);
        final rideId = widget.activeRideId;
        Map<String, dynamic>? found;
        for (final item in result) {
          if (item is Map) {
            final candidate = Map<String, dynamic>.from(item);
            if ('${candidate['id'] ?? candidate['rideId'] ?? candidate['ride_id']}' == rideId) {
              found = candidate;
              break;
            }
          }
        }
        if (mounted && found != null) {
          setState(() => _ride = found);
          await _rebuildRoutes();
        }
      } else if (widget.showRequests) {
        final result = await DriverApi.requests();
        final raw = result['requests'] ?? result['data'] ?? [];
        if (mounted) {
          setState(() => _requests = raw is List ? raw : []);
        }
      } else {
        if (mounted) setState(() => _requests = []);
      }
    } catch (_) {}
  }

  double? _num(dynamic value) {
    if (value is num && value.isFinite) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _rebuildRoutes() async {
    final ride = _ride;
    if (ride == null || widget.activeRideId == null) {
      if (mounted) {
        setState(() {
          _routePoints = [];
          _toPickupPoints = [];
          _routeMeta = null;
        });
      }
      return;
    }
    if (_routeLoading) return;
    _routeLoading = true;

    final pickupLat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
    final pickupLng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
    final destLat = _num(ride['destinationLat'] ?? ride['destination_lat']);
    final destLng = _num(ride['destinationLng'] ?? ride['destination_lng']);
    final status = '${ride['status'] ?? ''}'.toLowerCase();
    final pos = _position;

    try {
      // Full trip corridor: pickup → destination (road-following)
      if (pickupLat != null && pickupLng != null && destLat != null && destLng != null) {
        final trip = await DirectionsService.fetch(
          originLat: pickupLat,
          originLng: pickupLng,
          destLat: destLat,
          destLng: destLng,
        );
        if (mounted) {
          setState(() {
            _routePoints = GeoUtils.simplify(trip.points);
            _routeMeta = trip;
          });
        }
      }

      // Driver → next target (pickup while arriving, else destination)
      if (pos != null) {
        final goingToPickup = status.contains('accept') ||
            status.contains('arriv') ||
            status == 'assigned' ||
            status == 'searching';
        final tLat = goingToPickup ? pickupLat : destLat;
        final tLng = goingToPickup ? pickupLng : destLng;
        if (tLat != null && tLng != null) {
          final leg = await DirectionsService.route(
            originLat: pos.latitude,
            originLng: pos.longitude,
            destLat: tLat,
            destLng: tLng,
          );
          if (mounted) {
            setState(() => _toPickupPoints = GeoUtils.simplify(leg));
          }
        }
      }
      await _fitBounds();
    } finally {
      _routeLoading = false;
    }
  }

  Future<void> _fitBounds() async {
    final c = _controller;
    if (c == null) return;
    final pts = <gmaps.LatLng>[
      ..._routePoints,
      ..._toPickupPoints,
      ..._markerPositions,
    ];
    final bounds = GeoUtils.boundsOf(pts);
    if (bounds == null) return;
    try {
      await c.animateCamera(gmaps.CameraUpdate.newLatLngBounds(bounds, 56));
    } catch (_) {}
  }

  List<gmaps.LatLng> get _markerPositions {
    final out = <gmaps.LatLng>[];
    final pos = _position;
    if (pos != null) out.add(gmaps.LatLng(pos.latitude, pos.longitude));
    final ride = _ride;
    if (ride != null) {
      final plat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
      final plng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
      final dlat = _num(ride['destinationLat'] ?? ride['destination_lat']);
      final dlng = _num(ride['destinationLng'] ?? ride['destination_lng']);
      if (plat != null && plng != null) out.add(gmaps.LatLng(plat, plng));
      if (dlat != null && dlng != null) out.add(gmaps.LatLng(dlat, dlng));
    }
    return out;
  }

  Set<gmaps.Marker> get _mapMarkers {
    final markers = <gmaps.Marker>{};
    final icons = _markers;
    final pos = _position;
    if (pos != null) {
      markers.add(gmaps.Marker(
        markerId: const gmaps.MarkerId('driver'),
        position: gmaps.LatLng(pos.latitude, pos.longitude),
        infoWindow: gmaps.InfoWindow(title: t('You', 'Wewe')),
        icon: icons?.driverArrow ??
            gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
        rotation: pos.heading.isFinite ? pos.heading : 0,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        zIndex: 10,
      ));
    }

    if (widget.activeRideId != null && _ride != null) {
      final ride = _ride!;
      final pickupLat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
      final pickupLng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
      final destLat = _num(ride['destinationLat'] ?? ride['destination_lat']);
      final destLng = _num(ride['destinationLng'] ?? ride['destination_lng']);
      if (pickupLat != null && pickupLng != null) {
        markers.add(gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: gmaps.LatLng(pickupLat, pickupLng),
          infoWindow: gmaps.InfoWindow(
            title: t('Pickup', 'Kuchukua'),
            snippet: '${ride['pickupAddress'] ?? ride['pickup_address'] ?? ''}',
          ),
          icon: icons?.pickup ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.92),
        ));
      }
      if (destLat != null && destLng != null) {
        markers.add(gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: gmaps.LatLng(destLat, destLng),
          infoWindow: gmaps.InfoWindow(
            title: t('Destination', 'Kwenda'),
            snippet: '${ride['destinationAddress'] ?? ride['destination_address'] ?? ''}',
          ),
          icon: icons?.destination ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 0.92),
        ));
      }
    } else {
      for (var i = 0; i < _requests.length; i++) {
        final item = _requests[i];
        if (item is! Map) continue;
        final r = Map<String, dynamic>.from(item);
        final lat = _num(r['pickupLat'] ?? r['pickup_lat']);
        final lng = _num(r['pickupLng'] ?? r['pickup_lng']);
        if (lat == null || lng == null) continue;
        final id = '${r['id'] ?? i}';
        final type = '${r['rideType'] ?? r['ride_type'] ?? 'taxi'}';
        markers.add(gmaps.Marker(
          markerId: gmaps.MarkerId('request-$id'),
          position: gmaps.LatLng(lat, lng),
          infoWindow: gmaps.InfoWindow(
            title: t('Rider pickup', 'Abiria — kuchukua'),
            snippet:
                '${r['pickupAddress'] ?? r['pickup_address'] ?? ''} · $type',
          ),
          icon: icons?.nearbyFor(type) ??
              gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 0.92),
        ));
      }
    }
    return markers;
  }

  Set<gmaps.Polyline> get _polylines {
    final set = <gmaps.Polyline>{};
    final isDark = widget.isDark;

    if (_routePoints.length >= 2) {
      set.addAll(MapUi.routeLine(
        id: 'trip',
        points: _routePoints,
        isDark: isDark,
      ));
    }
    if (_toPickupPoints.length >= 2) {
      // Active navigation leg — slightly brighter dashed overlay feel via second solid
      set.addAll(MapUi.routeLine(
        id: 'leg',
        points: _toPickupPoints,
        isDark: isDark,
        width: 5,
      ));
    }
    return set;
  }

  gmaps.LatLng get _center {
    final pos = _position;
    if (pos != null) return gmaps.LatLng(pos.latitude, pos.longitude);
    final ride = _ride;
    if (ride != null) {
      final lat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
      final lng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
      if (lat != null && lng != null) return gmaps.LatLng(lat, lng);
    }
    return _defaultCenter;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final mapHeight = widget.height.isFinite
        ? widget.height
        : (MediaQuery.sizeOf(context).height * 0.42).clamp(220.0, 480.0);
    final meta = _routeMeta;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: mapHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(target: _center, zoom: 14.2),
              onMapCreated: (controller) async {
                _controller = controller;
                try {
                  await controller.setMapStyle(
                    widget.isDark ? MapStyles.dark : MapStyles.light,
                  );
                } catch (_) {}
                await _fitBounds();
              },
              markers: _mapMarkers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: true,
              padding: EdgeInsets.only(bottom: 8 + bottomPad * 0.1, top: 8),
            ),
            // Legend
            Positioned(
              left: 12,
              top: 12,
              child: _Legend(
                isSwahili: widget.isSwahili,
                isDark: widget.isDark,
                showRoute: widget.activeRideId != null,
                showRiders: widget.showRequests && widget.activeRideId == null,
              ),
            ),
            // Route chip (distance / ETA) when we have a road path
            if (meta != null && meta.followsRoads)
              Positioned(
                left: 12,
                right: 64,
                bottom: 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: RouteInfoChip(
                    duration: meta.durationLabel,
                    distance: meta.distanceLabel,
                    isDark: widget.isDark,
                    approximate: false,
                  ),
                ),
              ),
            // Recenter
            Positioned(
              right: 12,
              bottom: 12,
              child: MapCircleButton(
                icon: Icons.my_location_rounded,
                isDark: widget.isDark,
                tooltip: t('My location', 'Eneo langu'),
                onTap: () async {
                  await _updateLocation();
                  final pos = _position;
                  if (pos != null && _controller != null) {
                    await _controller!.animateCamera(
                      gmaps.CameraUpdate.newLatLngZoom(
                        gmaps.LatLng(pos.latitude, pos.longitude),
                        15.5,
                      ),
                    );
                  } else {
                    await _fitBounds();
                  }
                },
              ),
            ),
            if (_mapError != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.red.shade800.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      _mapError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.isSwahili,
    required this.isDark,
    required this.showRoute,
    required this.showRiders,
  });
  final bool isSwahili;
  final bool isDark;
  final bool showRoute;
  final bool showRiders;

  @override
  Widget build(BuildContext context) {
    final bg = MapUi.panelColor(isDark);
    final fg = isDark ? Colors.white70 : Colors.black87;
    String t(String en, String sw) => isSwahili ? sw : en;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(const Color(0xFF0D9488), t('You', 'Wewe')),
            if (showRoute) ...[
              const SizedBox(height: 4),
              _dot(const Color(0xFF22C55E), t('Pickup', 'Kuchukua')),
              const SizedBox(height: 4),
              _dot(const Color(0xFFF97316), t('Drop-off', 'Kushusha')),
            ],
            if (showRiders) ...[
              const SizedBox(height: 4),
              _dot(const Color(0xFFF59E0B), t('Nearby riders', 'Abiria karibu')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}
