import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'api/driver_api.dart';

/// Native Google Maps counterpart to the web portal's js/map.js.
/// Uses real device GPS and the same driver location/ride endpoints.
class LiveDriverMap extends StatefulWidget {
  const LiveDriverMap({
    super.key,
    this.height = 320,
    this.showRequests = true,
    this.activeRideId,
    this.shareLocation = false,
  });

  final double height;
  final bool showRequests;
  final String? activeRideId;
  final bool shareLocation;

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

  static const LatLng _defaultCenter = LatLng(-6.1659, 39.2026);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _refreshRemote();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshRemote());
    _locationTimer = Timer.periodic(const Duration(seconds: 12), (_) => _updateLocation());
  }

  @override
  void didUpdateWidget(covariant LiveDriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeRideId != widget.activeRideId ||
        oldWidget.showRequests != widget.showRequests ||
        oldWidget.shareLocation != widget.shareLocation) {
      _refreshRemote();
    }
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _mapError = 'Allow location access to share your live position.');
        return;
      }
      _locationPermission = true;
      await _updateLocation();
    } catch (e) {
      if (mounted) setState(() => _mapError = 'Location unavailable: $e');
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
      if (_controller != null) {
        await _controller!.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
      try {
        if (widget.shareLocation || widget.activeRideId != null) {
          await DriverApi.updateLocation(
            pos.latitude,
            pos.longitude,
            heading: pos.heading.isFinite ? pos.heading : null,
            speed: pos.speed.isFinite ? pos.speed : null,
          );
        }
      } catch (_) {
        // GPS display remains useful while the backend is temporarily unreachable.
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
        if (mounted && found != null) setState(() => _ride = found);
      } else if (widget.showRequests) {
        final result = await DriverApi.requests();
        final raw = result['requests'] ?? result['data'] ?? [];
        if (mounted) setState(() {
          _requests = raw is List ? raw : [];
        });
      } else {
        if (mounted) setState(() => _requests = []);
      }
    } catch (_) {
      // Keep the last successful marker set; don't replace it with fabricated data.
    }
  }

  double? _num(dynamic value) {
    if (value is num && value.isFinite) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final pos = _position;
    if (pos != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver-current-location'),
        position: LatLng(pos.latitude, pos.longitude),
        infoWindow: const InfoWindow(title: 'Your location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
          infoWindow: InfoWindow(title: 'Pickup', snippet: '${ride['pickupAddress'] ?? ride['pickup_address'] ?? ''}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
      if (destLat != null && destLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('ride-destination'),
          position: LatLng(destLat, destLng),
          infoWindow: InfoWindow(title: 'Destination', snippet: '${ride['destinationAddress'] ?? ride['destination_address'] ?? ''}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
            title: '${r['pickupAddress'] ?? r['pickup_address'] ?? 'Rider pickup'}',
            snippet: '${r['rideType'] ?? r['ride_type'] ?? 'Ride'} · ${r['fare'] ?? r['estimated_fare'] ?? ''}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 14),
              onMapCreated: (controller) {
                _controller = controller;
                if (_position != null) {
                  controller.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
                }
              },
              markers: _markers,
              myLocationEnabled: _locationPermission,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: true,
              compassEnabled: true,
              mapType: MapType.normal,
            ),
            if (_mapError != null)
              Positioned(
                left: 10, right: 10, bottom: 10,
                child: Material(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(_mapError!, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
