import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'api/driver_api.dart';
import 'friendly_errors.dart';

/// Modern, professional live map for drivers:
/// - Custom map style (light/dark)
/// - Driver / pickup / destination / nearby rider markers
/// - Route polyline between pickup → destination (and driver → target)
/// - Continuous GPS while [shareLocation] is true
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
  GoogleMapController? _controller;
  Position? _position;
  List<dynamic> _requests = [];
  Map<String, dynamic>? _ride;
  Timer? _locationTimer;
  Timer? _pollTimer;
  String? _mapError;
  bool _locationPermission = false;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destIcon;
  BitmapDescriptor? _riderIcon;
  Set<Polyline> _polylines = {};

  static const LatLng _defaultCenter = LatLng(-6.1659, 39.2026);

  String t(String en, String sw) => widget.isSwahili ? sw : en;

  @override
  void initState() {
    super.initState();
    _buildMarkerIcons();
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
        oldWidget.shareLocation != widget.shareLocation ||
        oldWidget.isDark != widget.isDark) {
      _refreshRemote();
      if (oldWidget.isDark != widget.isDark && _controller != null) {
        _controller!.setMapStyle(widget.isDark ? _darkMapStyle : _lightMapStyle);
      }
    }
  }

  Future<void> _buildMarkerIcons() async {
    _driverIcon = await _circleMarker(const Color(0xFF0D9488), size: 56, ring: true);
    _pickupIcon = await _circleMarker(const Color(0xFF22C55E), size: 48);
    _destIcon = await _circleMarker(const Color(0xFFEF4444), size: 48);
    _riderIcon = await _circleMarker(const Color(0xFFF59E0B), size: 44);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _circleMarker(Color color, {int size = 48, bool ring = false}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    if (ring) {
      canvas.drawCircle(center, size / 2.2, Paint()..color = color.withOpacity(0.25));
    }
    canvas.drawCircle(center, size / 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(center, size / 3.8, Paint()..color = color);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List()); // ignore: deprecated_member_use_from_same_package
    // Fallback path for older plugin versions is BitmapDescriptor.fromBytes
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
      _rebuildPolylines();
      if (widget.shareLocation || widget.activeRideId != null) {
        try {
          await DriverApi.updateLocation(
            pos.latitude,
            pos.longitude,
            heading: pos.heading.isFinite ? pos.heading : null,
            speed: pos.speed.isFinite ? pos.speed : null,
          );
        } catch (_) {}
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
          _rebuildPolylines();
          _fitBounds();
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

  void _rebuildPolylines() {
    final points = <LatLng>[];
    final ride = _ride;
    if (widget.activeRideId != null && ride != null) {
      final pickupLat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
      final pickupLng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
      final destLat = _num(ride['destinationLat'] ?? ride['destination_lat']);
      final destLng = _num(ride['destinationLng'] ?? ride['destination_lng']);
      final pos = _position;
      final status = '${ride['status'] ?? ''}'.toLowerCase();

      // Driver → next target → remaining path
      if (pos != null) points.add(LatLng(pos.latitude, pos.longitude));
      if (pickupLat != null && pickupLng != null &&
          (status.contains('accept') || status.contains('arriv') || status == 'assigned' || status == 'searching')) {
        points.add(LatLng(pickupLat, pickupLng));
      }
      if (destLat != null && destLng != null) {
        if (points.isEmpty && pickupLat != null && pickupLng != null) {
          points.add(LatLng(pickupLat, pickupLng));
        }
        points.add(LatLng(destLat, destLng));
      } else if (pickupLat != null && pickupLng != null && points.length < 2) {
        points.add(LatLng(pickupLat, pickupLng));
      }
    }

    _polylines = points.length >= 2
        ? {
            Polyline(
              polylineId: const PolylineId('active-route'),
              points: points,
              color: const Color(0xFF0D9488),
              width: 5,
              jointType: JointType.round,
              endCap: Cap.roundCap,
              startCap: Cap.roundCap,
              geodesic: true,
            ),
            // Soft underlay for depth
            Polyline(
              polylineId: const PolylineId('active-route-glow'),
              points: points,
              color: const Color(0x550D9488),
              width: 10,
              jointType: JointType.round,
              geodesic: true,
              zIndex: -1,
            ),
          }
        : {};
  }

  Future<void> _fitBounds() async {
    final c = _controller;
    if (c == null) return;
    final pts = <LatLng>[];
    for (final p in _polylines) {
      pts.addAll(p.points);
    }
    for (final m in _markers) {
      pts.add(m.position);
    }
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15));
      return;
    }
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    try {
      await c.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        56,
      ));
    } catch (_) {}
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final pos = _position;
    if (pos != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver-current-location'),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: InfoWindow(title: t('You', 'Wewe')),
        icon: _driverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndex: 10,
        anchor: const Offset(0.5, 0.5),
      ));
    }

    if (widget.activeRideId != null && _ride != null) {
      final ride = _ride!;
      final pickupLat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
      final pickupLng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
      final destLat = _num(ride['destinationLat'] ?? ride['destination_lat']);
      final destLng = _num(ride['destinationLng'] ?? ride['destination_lng']);
      if (pickupLat != null && pickupLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('ride-pickup'),
          position: LatLng(pickupLat, pickupLng),
          infoWindow: InfoWindow(
            title: t('Pickup', 'Kuchukua'),
            snippet: '${ride['pickupAddress'] ?? ride['pickup_address'] ?? ''}',
          ),
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.5),
        ));
      }
      if (destLat != null && destLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('ride-destination'),
          position: LatLng(destLat, destLng),
          infoWindow: InfoWindow(
            title: t('Destination', 'Kwenda'),
            snippet: '${ride['destinationAddress'] ?? ride['destination_address'] ?? ''}',
          ),
          icon: _destIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 0.5),
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
        markers.add(Marker(
          markerId: MarkerId('request-$id'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: t('Rider pickup', 'Abiria — kuchukua'),
            snippet:
                '${r['pickupAddress'] ?? r['pickup_address'] ?? ''} · ${r['rideType'] ?? r['ride_type'] ?? ''}',
          ),
          icon: _riderIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 0.5),
        ));
      }
    }
    return markers;
  }

  LatLng get _center {
    final pos = _position;
    if (pos != null) return LatLng(pos.latitude, pos.longitude);
    final ride = _ride;
    if (ride != null) {
      final lat = _num(ride['pickupLat'] ?? ride['pickup_lat']);
      final lng = _num(ride['pickupLng'] ?? ride['pickup_lng']);
      if (lat != null && lng != null) return LatLng(lat, lng);
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: mapHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 14.2),
              onMapCreated: (controller) async {
                _controller = controller;
                await controller.setMapStyle(widget.isDark ? _darkMapStyle : _lightMapStyle);
                _fitBounds();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: true,
              liteModeEnabled: false,
              padding: EdgeInsets.only(bottom: 8 + bottomPad * 0.1, top: 8),
            ),
            // Top gradient + legend
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        (widget.isDark ? Colors.black : Colors.white).withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: widget.isDark ? const Color(0xEE1E293B) : Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await _updateLocation();
                    final pos = _position;
                    if (pos != null && _controller != null) {
                      await _controller!.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15.5),
                      );
                    } else {
                      await _fitBounds();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: const Color(0xFF0D9488),
                      size: 22,
                    ),
                  ),
                ),
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
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
    final bg = isDark ? const Color(0xEE0F172A) : Colors.white.withOpacity(0.95);
    final fg = isDark ? Colors.white70 : Colors.black87;
    String t(String en, String sw) => isSwahili ? sw : en;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2)),
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
              _dot(const Color(0xFFEF4444), t('Drop-off', 'Kushusha')),
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

/// Subtle modern dark map style (desaturated roads, teal water accents).
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c3d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a9bb0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d2c3d"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a63"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#1d2c3d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d5a73"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b4f5c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

const String _lightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f7fa"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#5c6b7a"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d9e2ec"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dbe7f0"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#b7e4e8"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e8a8f"}]}
]
''';
