import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zenjigodriver/core/api/driver_api.dart';

/// Keeps sharing the driver's GPS while they are online — including when the
/// app is in the background (Android foreground-service notification).
///
/// Call [start] when the driver goes online / has an active ride, and [stop]
/// when they go offline and have no active ride.
class BackgroundLocationService {
  BackgroundLocationService._();
  static final BackgroundLocationService instance = BackgroundLocationService._();

  StreamSubscription<Position>? _sub;
  bool _running = false;
  DateTime? _lastSent;

  bool get isRunning => _running;

  Future<bool> ensurePermission({bool always = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    // Prefer "always" so tracking continues after the screen is locked.
    if (always &&
        permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      // On some platforms requestPermission may prompt for always.
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> start({
    required bool isSwahili,
    String? activeRideId,
  }) async {
    if (_running) return;
    final ok = await ensurePermission(always: true);
    if (!ok) {
      debugPrint('[BackgroundLocation] permission denied');
      return;
    }

    final notificationTitle = isSwahili ? 'ZenjiGO — Mtandaoni' : 'ZenjiGO — Online';
    final notificationBody = isSwahili
        ? 'Inashiriki eneo lako kwa ombi la safari. Gusa kurudi kwenye programu.'
        : 'Sharing your location for ride requests. Tap to return to the app.';

    final settings = _platformSettings(
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
    );

    _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) => _onPosition(pos, activeRideId: activeRideId),
      onError: (e) => debugPrint('[BackgroundLocation] stream error: $e'),
      cancelOnError: false,
    );
    _running = true;
    debugPrint('[BackgroundLocation] started');
  }

  LocationSettings _platformSettings({
    required String notificationTitle,
    required String notificationBody,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 12),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle,
          notificationText: notificationBody,
          enableWakeLock: true,
          setOngoing: true,
          notificationChannelName: 'ZenjiGO Live Tracking',
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
  }

  Future<void> _onPosition(Position pos, {String? activeRideId}) async {
    final now = DateTime.now();
    // Throttle network posts (stream may fire more often than needed).
    if (_lastSent != null && now.difference(_lastSent!).inSeconds < 8) return;
    _lastSent = now;
    try {
      await DriverApi.updateLocation(
        pos.latitude,
        pos.longitude,
        heading: pos.heading.isFinite ? pos.heading : null,
        speed: pos.speed.isFinite ? pos.speed : null,
      );
    } catch (e) {
      debugPrint('[BackgroundLocation] update failed: $e');
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _running = false;
    _lastSent = null;
    debugPrint('[BackgroundLocation] stopped');
  }

  /// Restart with fresh language strings / ride context.
  Future<void> restart({required bool isSwahili, String? activeRideId}) async {
    await stop();
    await start(isSwahili: isSwahili, activeRideId: activeRideId);
  }
}
