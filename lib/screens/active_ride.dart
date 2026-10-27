import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';
import 'package:zenjigodriver/core/app_state.dart';
import 'package:zenjigodriver/core/api/driver_api.dart';
import 'package:zenjigodriver/core/map/map_markers.dart';
import 'package:zenjigodriver/core/map/map_motion.dart';
import 'package:zenjigodriver/core/map/map_style.dart';
import 'package:zenjigodriver/core/map/map_widgets.dart';
import 'package:zenjigodriver/core/map/route_utils.dart';
import 'package:zenjigodriver/core/theme.dart';
import 'package:zenjigodriver/core/utils/directions_service.dart';
import 'package:zenjigodriver/core/widgets.dart';
import 'chat.dart';

/// Full-screen navigation for an accepted ride.
///
/// Flow:  accepted → arriving → arrived → (rider PIN) started → reached destination → payment → completed
///  * The PIN (OTP) shown in the rider's app is required to start the ride.
///  * The ride only ends after the payment is verified: automatically for wallet / mobile money,
///    or when the driver confirms the cash was received.
class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key, this.rideId});
  final String? rideId;

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  // ---- server state ----------------------------------------------------------------
  Map<String, dynamic>? _ride;
  Timer? _ridePoll;
  bool _busy = false;
  bool _finished = false;

  // ---- map / navigation ------------------------------------------------------------
  gmaps.GoogleMapController? _map;
  MapMarkerSet? _markers;
  final MovingPoint _me = MovingPoint();
  StreamSubscription<Position>? _gps;
  Position? _pos;
  DateTime _lastPost = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRouteFetch = DateTime.fromMillisecondsSinceEpoch(0);
  String _routeKey = '';
  RouteTracker? _leg; // driver → current target
  RouteTracker? _tripRoute; // pickup → destination (preview before the ride starts)
  double _avgSpeed = 7; // m/s
  double _remainingMeters = 0;
  double _drivenMeters = 0;
  gmaps.LatLng? _lastDrivenPoint;
  bool _follow = true;
  DateTime _lastCamera = DateTime.fromMillisecondsSinceEpoch(0);
  bool _expanded = true;

  // ---- prompts / input -------------------------------------------------------------
  final _pinCtrl = TextEditingController();
  String? _pinError;
  bool _pickupPrompted = false;
  bool _destPrompted = false;
  bool _cashPrompted = false;

  AppState get _app => AppScope.of(context);
  String t(String en, String sw) => _app.t(en, sw);

  // ---- ride accessors --------------------------------------------------------------
  String get _status => '${_ride?['status'] ?? 'accepted'}'.toLowerCase();
  bool get _reached => _truthy(_field('reached_destination', 'reachedDestination'));
  String get _payStatus => '${_field('payment_status', 'paymentStatus') ?? 'not_due'}';
  String get _payMethod => '${_field('payment_method', 'paymentMethod') ?? 'cash'}'.toLowerCase();
  bool get _toPickup => const ['accepted', 'arriving', 'arrived'].contains(_status);
  bool get _inTrip => _status == 'started';
  bool get _awaitingPayment => _inTrip && _reached;

  static bool _truthy(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';
  static double? _num(dynamic v) {
    if (v is num && v.isFinite) return v.toDouble();
    return double.tryParse('${v ?? ''}');
  }

  /// Read a field that may arrive as snake_case or camelCase from the API.
  dynamic _field(String snake, [String? camel]) {
    final r = _ride;
    if (r == null) return null;
    final c = camel ?? _snakeToCamel(snake);
    return r[snake] ?? r[c];
  }

  static String _snakeToCamel(String s) {
    final parts = s.split('_');
    if (parts.length < 2) return s;
    final b = StringBuffer(parts.first);
    for (var i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.isEmpty) continue;
      b.write(p[0].toUpperCase());
      if (p.length > 1) b.write(p.substring(1));
    }
    return b.toString();
  }

  gmaps.LatLng? get _pickup {
    final la = _num(_field('pickup_lat', 'pickupLat'));
    final ln = _num(_field('pickup_lng', 'pickupLng'));
    return (la == null || ln == null) ? null : gmaps.LatLng(la, ln);
  }

  gmaps.LatLng? get _dest {
    final la = _num(_field('destination_lat', 'destinationLat'));
    final ln = _num(_field('destination_lng', 'destinationLng'));
    return (la == null || ln == null) ? null : gmaps.LatLng(la, ln);
  }

  gmaps.LatLng? get _target => _toPickup ? _pickup : _dest;

  String _s(String key, [String fallback = '—']) {
    final v = _field(key) ?? _ride?[key];
    return (v == null || '$v'.trim().isEmpty) ? fallback : '$v';
  }

  double get _amountDue =>
      _num(_field('amount_due', 'amountDue')) ??
      _num(_field('estimated_fare', 'estimatedFare')) ??
      0;
  String _tzs(num v) {
    final n = v.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) b.write(',');
      b.write(n[i]);
    }
    return 'TZS $b';
  }

  // ---- lifecycle -------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _loadRide();
    _ridePoll = Timer.periodic(const Duration(seconds: 3), (_) => _loadRide());
    _startGps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_markers == null) {
      MapMarkers.load(View.of(context).devicePixelRatio).then((set) {
        if (mounted) setState(() => _markers = set);
      });
    }
  }

  @override
  void dispose() {
    _ridePoll?.cancel();
    _gps?.cancel();
    _me.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _startGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
      ).catchError((_) => Geolocator.getLastKnownPosition().then((p) => p!));
      _onPosition(first);
      _gps = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 4),
      ).listen(_onPosition, onError: (_) {});
    } catch (_) {}
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    final here = gmaps.LatLng(p.latitude, p.longitude);

    // Accurate distance driven during the trip (ignore GPS jitter and poor fixes).
    if (_inTrip && !_reached && p.accuracy <= 35) {
      final last = _lastDrivenPoint;
      if (last != null) {
        final d = GeoUtils.distanceMeters(last, here);
        if (d >= 3 && d < 500) {
          _drivenMeters += d;
          _lastDrivenPoint = here;
        }
      } else {
        _lastDrivenPoint = here;
      }
    }

    // Glide the marker along the road when we are on the route.
    var shown = here;
    final leg = _leg;
    if (leg != null && leg.isUsable) {
      final snap = leg.snap(here);
      if (snap != null && snap.offset < 30) shown = snap.point;
    }
    _me.moveTo(shown, duration: const Duration(milliseconds: 1200));

    setState(() => _pos = p);
    _recomputeRemaining();
    _ensureRoute();
    _followCamera();
    _maybePrompts(here);

    // Share the live position with the server (and therefore the rider) every ~3 s.
    if (DateTime.now().difference(_lastPost).inMilliseconds >= 3000) {
      _lastPost = DateTime.now();
      DriverApi.updateLocation(
        p.latitude,
        p.longitude,
        heading: p.heading.isFinite && p.heading >= 0 ? p.heading : null,
        speed: p.speed.isFinite && p.speed >= 0 ? p.speed : null,
        rideId: widget.rideId,
      ).catchError((_) {});
    }
  }

  // ---- server polling --------------------------------------------------------------
  Future<void> _loadRide() async {
    final id = widget.rideId;
    if (id == null || _finished) return;
    try {
      final r = await DriverApi.ride(id);
      if (!mounted) return;
      final prevStatus = _status;
      final prevReached = _reached;
      final hadRoute = _leg != null;
      setState(() => _ride = r);
      if (prevStatus != _status) {
        _routeKey = '';
        _leg = null;
        _follow = true;
        _ensureRoute();
        _fitOverview();
      } else if (!hadRoute && _target != null) {
        // First successful parse of coordinates (handles camelCase/snake_case) → build route.
        _ensureRoute();
        _fitOverview();
      }
      _afterRideUpdate(prevStatus, prevReached);
    } catch (_) {}
  }

  void _afterRideUpdate(String prevStatus, bool prevReached) {
    if (_finished) return;
    if (_status == 'cancelled') {
      _finished = true;
      _onCancelled();
      return;
    }
    if (_status == 'completed') {
      _finished = true;
      _onCompleted();
      return;
    }
    // Rider chose cash (or booked cash): remind the driver to collect.
    if (_awaitingPayment && !_cashPrompted && (_payStatus == 'awaiting_cash' || _payMethod == 'cash')) {
      _cashPrompted = true;
      HapticFeedback.heavyImpact();
      _showMessage(
        icon: Icons.payments_rounded,
        color: ZenjiColors.green,
        title: t('Collect cash', 'Kusanya pesa taslimu'),
        message: t(
          'Collect ${_tzs(_amountDue)} cash from the rider, then tap “Cash received” to end the ride.',
          'Kusanya ${_tzs(_amountDue)} taslimu kutoka kwa abiria, kisha bonyeza “Pesa imepokelewa” kumaliza safari.',
        ),
      );
    }
  }

  // ---- routing ---------------------------------------------------------------------
  Future<void> _ensureRoute() async {
    final pos = _pos;
    final target = _target;
    if (pos == null || target == null) return;
    final key = _toPickup ? 'pickup' : 'dest';
    final here = gmaps.LatLng(pos.latitude, pos.longitude);

    var needFetch = _routeKey != key || _leg == null;
    if (!needFetch) {
      final snap = _leg!.snap(here);
      // Off route (wrong turn) → re-route, but never more than once every 8 s.
      if (snap == null || snap.offset > 60) {
        needFetch = DateTime.now().difference(_lastRouteFetch).inSeconds >= 8;
      }
    }
    if (!needFetch) return;
    _lastRouteFetch = DateTime.now();
    _routeKey = key;
    try {
      final res = await DirectionsService.fetch(
        originLat: here.latitude,
        originLng: here.longitude,
        destLat: target.latitude,
        destLng: target.longitude,
      );
      if (!mounted || _routeKey != key) return;
      setState(() {
        _leg = RouteTracker(GeoUtils.simplify(res.points));
        if (res.distanceMeters > 0 && res.durationSeconds > 0) {
          _avgSpeed = (res.distanceMeters / res.durationSeconds).clamp(3.0, 20.0).toDouble();
        }
      });
      _recomputeRemaining();
      _fitOverview();
    } catch (_) {}

    // Preview of the whole trip while heading to the pickup.
    if (_toPickup && _tripRoute == null && _pickup != null && _dest != null) {
      try {
        final trip = await DirectionsService.fetch(
          originLat: _pickup!.latitude,
          originLng: _pickup!.longitude,
          destLat: _dest!.latitude,
          destLng: _dest!.longitude,
        );
        if (mounted) setState(() => _tripRoute = RouteTracker(GeoUtils.simplify(trip.points)));
      } catch (_) {}
    }
  }

  void _recomputeRemaining() {
    final pos = _pos;
    if (pos == null) return;
    final here = gmaps.LatLng(pos.latitude, pos.longitude);
    final leg = _leg;
    double remaining;
    if (leg != null && leg.isUsable) {
      final snap = leg.snap(here);
      remaining = snap == null ? leg.totalMeters : (leg.totalMeters - snap.distanceAlong).clamp(0.0, double.infinity).toDouble();
      // Add the off-route gap so the number stays honest if the driver left the route.
      if (snap != null && snap.offset > 40) remaining += snap.offset;
    } else {
      final target = _target;
      remaining = target == null ? 0 : GeoUtils.distanceMeters(here, target) * 1.25;
    }
    if (mounted) setState(() => _remainingMeters = remaining);
  }

  int? get _etaMinutes {
    if (_remainingMeters <= 0) return null;
    var speed = _avgSpeed;
    final live = _pos?.speed ?? 0;
    if (live.isFinite && live > 2.5) speed = (live * 0.5 + _avgSpeed * 0.5).clamp(3.0, 22.0).toDouble();
    return (_remainingMeters / speed / 60).ceil().clamp(1, 999);
  }

  String get _remainingLabel {
    if (_remainingMeters <= 0) return '—';
    if (_remainingMeters < 1000) return '${_remainingMeters.round()} m';
    return '${(_remainingMeters / 1000).toStringAsFixed(1)} km';
  }

  // ---- camera ----------------------------------------------------------------------
  Future<void> _followCamera() async {
    final c = _map;
    final pos = _pos;
    if (c == null || pos == null || !_follow) return;
    if (DateTime.now().difference(_lastCamera).inMilliseconds < 1500) return;
    _lastCamera = DateTime.now();
    final bearing = (pos.speed > 2 && pos.heading.isFinite && pos.heading >= 0) ? pos.heading : 0.0;
    try {
      await c.animateCamera(gmaps.CameraUpdate.newCameraPosition(gmaps.CameraPosition(
        target: gmaps.LatLng(pos.latitude, pos.longitude),
        zoom: 17,
        tilt: 40,
        bearing: bearing,
      )));
    } catch (_) {}
  }

  Future<void> _fitOverview() async {
    final c = _map;
    if (c == null) return;
    final pts = <gmaps.LatLng>[];
    final pos = _pos;
    if (pos != null) pts.add(gmaps.LatLng(pos.latitude, pos.longitude));
    if (_target != null) pts.add(_target!);
    if (pts.length < 2) return;
    final b = GeoUtils.boundsOf(pts);
    if (b == null) return;
    try {
      await c.animateCamera(gmaps.CameraUpdate.newLatLngBounds(b, 90));
    } catch (_) {}
  }

  // ---- arrival prompts -------------------------------------------------------------
  void _maybePrompts(gmaps.LatLng here) {
    if (_finished || _busy) return;
    if ((_status == 'accepted' || _status == 'arriving') && !_pickupPrompted && _pickup != null) {
      if (GeoUtils.distanceMeters(here, _pickup!) <= 60) {
        _pickupPrompted = true;
        HapticFeedback.heavyImpact();
        _showMessage(
          icon: Icons.location_on_rounded,
          color: ZenjiColors.green,
          title: t('You have reached the pickup point', 'Umefika sehemu ya kuchukua'),
          message: t('The rider will be notified that you have arrived. Ask for their 4-digit PIN to start the ride.',
              'Abiria ataarifiwa kuwa umefika. Muombe PIN yake ya tarakimu 4 kuanza safari.'),
          actionLabel: t('Confirm arrival', 'Thibitisha kufika'),
          onAction: _confirmArrival,
        );
      }
    }
    if (_inTrip && !_reached && !_destPrompted && _dest != null && _drivenMeters > 150) {
      if (GeoUtils.distanceMeters(here, _dest!) <= 80) {
        _destPrompted = true;
        HapticFeedback.heavyImpact();
        _showMessage(
          icon: Icons.flag_rounded,
          color: ZenjiColors.green,
          title: t('You have reached the destination', 'Umefika unakokwenda'),
          message: _payMethod == 'cash'
              ? t('Confirm to ask the rider to pay. Then collect ${_tzs(_amountDue)} cash.', 'Thibitisha ili abiria alipe. Kisha kusanya ${_tzs(_amountDue)} taslimu.')
              : t('Confirm to ask the rider to pay ${_tzs(_amountDue)}.', 'Thibitisha ili abiria alipe ${_tzs(_amountDue)}.'),
          actionLabel: t('Confirm destination', 'Thibitisha mwisho wa safari'),
          onAction: () => _advance(),
        );
      }
    }
  }

  Future<void> _showMessage({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    if (!mounted) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: actionLabel == null,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Icon(icon, color: color, size: 54),
        title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (actionLabel != null) TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Later', 'Baadaye'))),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onAction != null) onAction();
            },
            child: Text(actionLabel ?? t('OK', 'Sawa')),
          ),
        ],
      ),
    );
  }

  // ---- actions ---------------------------------------------------------------------
  String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Performs the next step of the ride according to its current status.
  Future<void> _advance() async {
    final id = widget.rideId;
    if (id == null || _busy) return;
    setState(() {
      _busy = true;
      _pinError = null;
    });
    try {
      switch (_status) {
        case 'accepted':
          await DriverApi.status(id, 'arriving');
          break;
        case 'arriving':
          await DriverApi.status(id, 'arrived');
          break;
        case 'arrived':
          final pin = _pinCtrl.text.trim();
          if (pin.length != 4) {
            setState(() => _pinError = t('Enter the 4-digit PIN from the rider\'s app.', 'Weka PIN ya tarakimu 4 kutoka kwenye programu ya abiria.'));
            return;
          }
          await DriverApi.status(id, 'started', otp: pin);
          _pinCtrl.clear();
          _drivenMeters = 0;
          _lastDrivenPoint = _pos == null ? null : gmaps.LatLng(_pos!.latitude, _pos!.longitude);
          break;
        case 'started':
          if (!_reached) await DriverApi.reachedDestination(id);
          break;
      }
      await _loadRide();
    } catch (e) {
      final msg = _errorText(e);
      if (_status == 'arrived') {
        if (mounted) setState(() => _pinError = msg);
      } else if (mounted) {
        toast(context, msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One-tap arrival from the geofence prompt: tells the rider the driver is at the pickup.
  Future<void> _confirmArrival() async {
    final id = widget.rideId;
    if (id == null || _busy || _status == 'arrived' || _status == 'started') return;
    setState(() => _busy = true);
    try {
      await DriverApi.status(id, 'arrived');
      await _loadRide();
    } catch (e) {
      if (mounted) toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cashReceived() async {
    final id = widget.rideId;
    if (id == null || _busy) return;
    final yes = await confirmDialog(
      context,
      title: t('Cash received?', 'Pesa imepokelewa?'),
      message: t('Confirm only after you have received ${_tzs(_amountDue)} in cash. This ends the ride.',
          'Thibitisha tu baada ya kupokea ${_tzs(_amountDue)} taslimu. Hii inamaliza safari.'),
      confirm: t('Cash received', 'Pesa imepokelewa'),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    try {
      await DriverApi.collectCash(id);
      await _loadRide();
    } catch (e) {
      if (mounted) toast(context, _errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelRide() async {
    final id = widget.rideId;
    if (id == null) return;
    final yes = await confirmDialog(
      context,
      title: t('Cancel this ride?', 'Ghairi safari hii?'),
      message: t('Only cancel if you cannot safely complete the trip.', 'Ghairi tu ikiwa huwezi kukamilisha safari kwa usalama.'),
      confirm: t('Cancel ride', 'Ghairi safari'),
    );
    if (yes != true || !mounted) return;
    try {
      await DriverApi.status(id, 'cancelled');
      _finished = true;
      _app.setActiveRideId(null);
      if (!mounted) return;
      toast(context, t('Ride cancelled.', 'Safari imeghairiwa.'));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) toast(context, _errorText(e));
    }
  }

  Future<void> _onCancelled() async {
    _app.setActiveRideId(null);
    await _showMessage(
      icon: Icons.cancel_rounded,
      color: Colors.red,
      title: t('Ride cancelled', 'Safari imeghairiwa'),
      message: t('The rider cancelled this ride.', 'Abiria ameghairi safari hii.'),
    );
    _app.refreshFinance();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onCompleted() async {
    HapticFeedback.heavyImpact();
    _app.setActiveRideId(null);
    _app.refreshFinance();
    _app.refreshProfile();
    final fare = _num(_ride?['final_fare']) ?? _num(_ride?['gross_amount']) ?? _amountDue;
    final share = _num(_ride?['driver_earnings']);
    final commission = _num(_ride?['platform_commission']);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.check_circle, color: ZenjiColors.green, size: 58),
        title: Text(t('Ride completed', 'Safari imekamilika'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t('Payment received. Great job!', 'Malipo yamepokelewa. Kazi nzuri!'), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          KeyValueRow(t('Fare', 'Nauli'), _tzs(fare)),
          if (commission != null) KeyValueRow(t('ZenjiGO fee', 'Ada ya ZenjiGO'), _tzs(commission)),
          KeyValueRow(t('Your share', 'Sehemu yako'), share != null ? _tzs(share) : '—'),
          if (_drivenMeters > 0) KeyValueRow(t('Distance driven', 'Umbali uliosafiri'), '${(_drivenMeters / 1000).toStringAsFixed(1)} km'),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Back to Home', 'Rudi Nyumbani'))),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _callRider() async {
    final phone = _s('rider_phone', '');
    if (phone.isEmpty) {
      toast(context, t('Rider phone is not available for this ride.', 'Namba ya abiria haipatikani.'));
      return;
    }
    final ok = await launchUrl(Uri.parse('tel:$phone'));
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) toast(context, t('Number copied: $phone', 'Namba imenakiliwa: $phone'));
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(name: _s('rider_name', 'Rider'), support: false, rideId: widget.rideId),
      ),
    );
  }

  // ---- UI --------------------------------------------------------------------------
  String get _primaryLabel {
    switch (_status) {
      case 'accepted':
        return t('ON MY WAY', 'NIKO NJIANI');
      case 'arriving':
        return t('I HAVE ARRIVED', 'NIMEWASILI');
      case 'arrived':
        return t('START RIDE', 'ANZA SAFARI');
      case 'started':
        return t('REACHED DESTINATION', 'NIMEFIKA MWISHO');
      default:
        return '';
    }
  }

  IconData get _primaryIcon {
    switch (_status) {
      case 'accepted':
        return Icons.navigation_rounded;
      case 'arriving':
        return Icons.location_on_rounded;
      case 'arrived':
        return Icons.play_arrow_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Set<gmaps.Polyline> _polylines(bool isDark) {
    final set = <gmaps.Polyline>{};
    final leg = _leg;
    final pos = _pos;
    if (_toPickup && _tripRoute != null && _tripRoute!.isUsable) {
      set.addAll(MapUi.secondaryLine(id: 'trip', points: _tripRoute!.points, isDark: isDark));
    }
    if (leg != null && leg.isUsable) {
      List<gmaps.LatLng> remaining = leg.points;
      List<gmaps.LatLng> travelled = const [];
      if (pos != null) {
        final snap = leg.snap(gmaps.LatLng(pos.latitude, pos.longitude));
        if (snap != null && snap.offset < 80) {
          remaining = leg.sliceFrom(snap.distanceAlong);
          if (_inTrip) travelled = [...leg.points.sublist(0, snap.segment + 1), snap.point];
        }
      }
      set.addAll(MapUi.travelledLine(id: 'leg', points: travelled, isDark: isDark));
      set.addAll(MapUi.routeLine(id: 'leg', points: remaining, isDark: isDark, width: 7, zIndex: 3));
    }
    return set;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final start = _pos != null ? gmaps.LatLng(_pos!.latitude, _pos!.longitude) : (_pickup ?? const gmaps.LatLng(-6.1659, 39.2026));

    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) toast(context, t('Finish or cancel the active ride before leaving.', 'Maliza au ghairi safari inayoendelea kabla ya kuondoka.'));
      },
      child: Scaffold(
        body: Stack(children: [
          // ---------------------------------------------------------------- map
          Listener(
            onPointerDown: (_) {
              if (_follow) setState(() => _follow = false);
            },
            child: ValueListenableBuilder<MovingFrame?>(
              valueListenable: _me.frame,
              builder: (context, frame, _) {
                final set = _markers;
                final markers = <gmaps.Marker>{
                  if (_pickup != null && !_inTrip)
                    gmaps.Marker(
                      markerId: const gmaps.MarkerId('pickup'),
                      position: _pickup!,
                      icon: set?.pickup ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
                      anchor: const Offset(0.5, 0.5),
                      infoWindow: gmaps.InfoWindow(title: t('Pickup', 'Kuchukua'), snippet: _s('pickup_address', '')),
                    ),
                  if (_dest != null)
                    gmaps.Marker(
                      markerId: const gmaps.MarkerId('destination'),
                      position: _dest!,
                      icon: set?.destination ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange),
                      anchor: const Offset(0.5, 0.95),
                      infoWindow: gmaps.InfoWindow(title: t('Drop-off', 'Kushusha'), snippet: _s('destination_address', '')),
                    ),
                  if (frame != null)
                    gmaps.Marker(
                      markerId: const gmaps.MarkerId('me'),
                      position: frame.position,
                      rotation: frame.heading,
                      flat: true,
                      anchor: const Offset(0.5, 0.5),
                      zIndexInt: 5,
                      icon: set?.driverArrow ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
                    ),
                };
                return gmaps.GoogleMap(
                  style: MapStyles.forBrightness(isDark),
                  initialCameraPosition: gmaps.CameraPosition(target: start, zoom: 16),
                  onMapCreated: (c) {
                    _map = c;
                    _fitOverview();
                  },
                  padding: EdgeInsets.only(top: mq.padding.top + 120, bottom: _expanded ? 330 : 150),
                  markers: markers,
                  polylines: _polylines(isDark),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  buildingsEnabled: false,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                );
              },
            ),
          ),

          // ------------------------------------------------------- top banner
          // Positioned (top/left/right) gives the banner a bounded width and an *unbounded*
          // height, so it can only ever be as tall as its content and never covers the map.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _topBanner(isDark),
              ),
            ),
          ),

          // ---------------------------------------------------- map controls
          Positioned(
            right: 12,
            bottom: (_expanded ? 330 : 150) + 12,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              MapCircleButton(
                icon: Icons.zoom_out_map_rounded,
                isDark: isDark,
                tooltip: t('Overview', 'Muhtasari'),
                onTap: () {
                  setState(() => _follow = false);
                  _fitOverview();
                },
              ),
              const SizedBox(height: 10),
              MapCircleButton(
                icon: _follow ? Icons.navigation_rounded : Icons.near_me_outlined,
                isDark: isDark,
                tooltip: t('Follow me', 'Nifuate'),
                onTap: () {
                  setState(() => _follow = true);
                  _lastCamera = DateTime.fromMillisecondsSinceEpoch(0);
                  _followCamera();
                },
              ),
            ]),
          ),

          // ------------------------------------------------------ bottom panel
          Align(alignment: Alignment.bottomCenter, child: _bottomPanel(isDark, mq)),
        ]),
      ),
    );
  }

  Widget _topBanner(bool isDark) {
    final toPickup = _toPickup;
    final accent = MapUi.accent(isDark);
    final eta = _etaMinutes;
    final address = toPickup ? _s('pickup_address', t('Pickup location', 'Mahali pa kuchukua')) : _s('destination_address', t('Destination', 'Mahali pa kushusha'));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MapUi.panelColor(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: (toPickup ? ZenjiColors.green : Colors.deepOrange).withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(toPickup ? Icons.person_pin_circle_rounded : Icons.flag_rounded, color: toPickup ? ZenjiColors.green : Colors.deepOrange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              _awaitingPayment
                  ? t('Waiting for payment', 'Inasubiri malipo')
                  : toPickup
                      ? t('Go to pickup', 'Nenda kuchukua')
                      : t('Drive to drop-off', 'Endesha hadi kushusha'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MapUi.textSecondary(isDark)),
            ),
            const SizedBox(height: 2),
            Text(address, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
        if (!_awaitingPayment) ...[
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text(eta != null ? '$eta min' : '—', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: accent)),
            Text(_remainingLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MapUi.textSecondary(isDark))),
          ]),
        ],
      ]),
    );
  }

  Widget _bottomPanel(bool isDark, MediaQueryData mq) {
    final muted = MapUi.textSecondary(isDark);
    final rider = _s('rider_name', t('Rider', 'Abiria'));
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.62),
      decoration: BoxDecoration(
        color: MapUi.panelColor(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // handle: tap to minimise / expand
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: muted.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 2),
                Icon(_expanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, size: 20, color: muted),
              ]),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_expanded) ...[
                  Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: ZenjiColors.green.withValues(alpha: 0.15),
                      child: Text(rider.isEmpty ? '?' : rider[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: ZenjiColors.green)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(rider, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                        Text(
                          '${_s('ride_type', 'ride').toUpperCase()} · ${_payMethod.toUpperCase()}',
                          style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                    IconButton.filledTonal(onPressed: _callRider, icon: const Icon(Icons.call_rounded)),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(onPressed: _openChat, icon: const Icon(Icons.chat_bubble_outline_rounded)),
                  ]),
                  const SizedBox(height: 12),
                  _routeRow(Icons.radio_button_checked, ZenjiColors.green, t('Pickup', 'Kuchukua'), _s('pickup_address'), isDark),
                  _routeRow(Icons.location_on_rounded, Colors.deepOrange, t('Drop-off', 'Kushusha'), _s('destination_address'), isDark),
                  const SizedBox(height: 8),
                  Row(children: [
                    _stat(t('Fare', 'Nauli'), _tzs(_amountDue), isDark),
                    _stat(t('To go', 'Imebaki'), _remainingLabel, isDark),
                    _stat(t('ETA', 'Muda'), _etaMinutes != null ? '$_etaMinutes min' : '—', isDark),
                    if (_inTrip) _stat(t('Driven', 'Umesafiri'), '${(_drivenMeters / 1000).toStringAsFixed(1)} km', isDark),
                  ]),
                  const SizedBox(height: 12),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      Expanded(child: Text(rider, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                      Text('${_etaMinutes ?? '—'} min · $_remainingLabel', style: TextStyle(fontWeight: FontWeight.w800, color: MapUi.accent(isDark))),
                    ]),
                  ),
                ..._actionArea(isDark),
                if (_expanded && _toPickup)
                  TextButton.icon(
                    onPressed: _cancelRide,
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(t('Cancel ride', 'Ghairi safari')),
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _actionArea(bool isDark) {
    // Payment step: reached destination, waiting for the rider's payment.
    if (_awaitingPayment) {
      final cash = _payStatus == 'awaiting_cash' || _payMethod == 'cash';
      return [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ZenjiColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZenjiColors.green.withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            Text(cash ? t('Collect cash', 'Kusanya pesa taslimu') : t('Rider is paying', 'Abiria analipa'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_tzs(_amountDue), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              cash
                  ? t('Receive the cash from the rider, then confirm below.', 'Pokea pesa kutoka kwa abiria, kisha thibitisha hapa chini.')
                  : t('The ride ends automatically once the payment is verified.', 'Safari inaisha yenyewe malipo yakithibitishwa.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: MapUi.textSecondary(isDark)),
            ),
            if (!cash) ...[
              const SizedBox(height: 10),
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
            ],
          ]),
        ),
        const SizedBox(height: 10),
        if (cash)
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _busy ? null : _cashReceived,
              icon: const Icon(Icons.payments_rounded),
              label: Text(t('CASH RECEIVED · END RIDE', 'PESA IMEPOKELEWA · MALIZA'), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
      ];
    }

    final out = <Widget>[];
    if (_status == 'arrived') {
      out.add(Text(
        t('Ask the rider for the 4-digit PIN shown in their app', 'Muombe abiria PIN ya tarakimu 4 inayoonekana kwenye programu yake'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: MapUi.textSecondary(isDark), fontWeight: FontWeight.w600),
      ));
      out.add(const SizedBox(height: 8));
      out.add(TextField(
        controller: _pinCtrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 14),
        decoration: InputDecoration(
          counterText: '',
          hintText: '••••',
          errorText: _pinError,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
        ),
        onChanged: (_) {
          if (_pinError != null) setState(() => _pinError = null);
        },
        onSubmitted: (_) => _advance(),
      ));
      out.add(const SizedBox(height: 10));
    }
    if (_primaryLabel.isNotEmpty) {
      out.add(SizedBox(
        height: 56,
        child: FilledButton.icon(
          onPressed: _busy ? null : _advance,
          icon: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : Icon(_primaryIcon),
          label: Text(_primaryLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ));
    }
    return out;
  }

  Widget _routeRow(IconData icon, Color color, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MapUi.textSecondary(isDark))),
            Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(color: MapUi.panelSubtle(isDark), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: MapUi.textSecondary(isDark), fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
