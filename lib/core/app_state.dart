import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenjigodriver/core/api/api_client.dart';
import 'package:zenjigodriver/core/api/driver_api.dart';
import 'package:zenjigodriver/core/background_location.dart';

class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  bool isSwahili = false;
  bool online = false;
  int navIndex = 0;
  String applicationStatus = 'Pending';
  bool authenticated = false;
  Map<String, dynamic>? profile;
  Map<String, dynamic>? finance;
  String? activeRideId;
  int unreadMessages = 0;
  Timer? _ridePoll;
  String? lastPromptedRideId;
  Map<String, dynamic>? pendingRideRequest;
  void Function(Map<String, dynamic> request)? onRideRequest;

  AppState() {
    _restore();
  }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    authenticated = p.getString('accessToken')?.isNotEmpty == true;
    isSwahili = p.getBool('isSwahili') ?? false;
    final theme = p.getString('themeMode');
    if (theme == 'light') themeMode = ThemeMode.light;
    if (theme == 'dark') themeMode = ThemeMode.dark;
    if (authenticated) {
      try {
        await refreshProfile();
        await refreshFinance();
        await refreshUnreadMessages();
      } catch (_) {
        authenticated = false;
        await ApiClient.clear();
      }
    }
    notifyListeners();
  }

  Future<void> login(Map<String, dynamic> data) async {
    await ApiClient.save(data);
    authenticated = true;
    profile = Map<String, dynamic>.from(data['user'] ?? {});
    applicationStatus = (profile?['application_status'] ??
            profile?['applicationStatus'] ??
            'Pending')
        .toString();
    online = (profile?['online'] ?? false) == true;
    notifyListeners();
    // Load full profile + finance + unread chats in background
    refreshProfile();
    refreshFinance();
    refreshUnreadMessages();
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rt = prefs.getString('refreshToken');
      if (rt != null) {
        await ApiClient.request('POST', '/auth/logout', body: {'refreshToken': rt}, auth: false);
      }
    } catch (_) {}
    await ApiClient.clear();
    authenticated = false;
    profile = null;
    finance = null;
    online = false;
    activeRideId = null;
    unreadMessages = 0;
    applicationStatus = 'Pending';
    BackgroundLocationService.instance.stop();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      profile = await DriverApi.profile();
      applicationStatus = (profile?['application_status'] ??
              profile?['applicationStatus'] ??
              applicationStatus)
          .toString();
      online = (profile?['online'] ?? online) == true;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> refreshFinance() async {
    try {
      finance = await DriverApi.finance();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setOnlineRemote(bool value) async {
    await DriverApi.setOnline(value);
    online = value;
    notifyListeners();
    if (value) {
      startRidePolling();
    } else {
      stopRidePolling();
    }
  }

  void startRidePolling() {
    _ridePoll?.cancel();
    _ridePoll = Timer.periodic(const Duration(seconds: 8), (_) => _pollRides());
    _pollRides();
  }

  void stopRidePolling() {
    _ridePoll?.cancel();
    _ridePoll = null;
  }

  Future<void> _pollRides() async {
    if (!online || !authenticated) return;
    if (activeRideId != null) return; // busy with a ride: don't surface new requests
    try {
      final result = await DriverApi.requests();
      if (result['restricted'] == true) return;
      final raw = result['requests'] ?? result['data'] ?? [];
      final list = raw is List ? raw : <dynamic>[];
      if (list.isEmpty) return;
      final mapped = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      mapped.sort((a, b) {
        final da = double.tryParse('${a['estimated_distance_km'] ?? a['estimatedDistanceKm'] ?? 999}') ?? 999;
        final db = double.tryParse('${b['estimated_distance_km'] ?? b['estimatedDistanceKm'] ?? 999}') ?? 999;
        if (da != db) return da.compareTo(db);
        final fa = double.tryParse('${a['estimated_fare'] ?? a['fare'] ?? 0}') ?? 0;
        final fb = double.tryParse('${b['estimated_fare'] ?? b['fare'] ?? 0}') ?? 0;
        return fb.compareTo(fa);
      });
      final next = mapped.first;
      final id = '${next['id'] ?? ''}';
      if (id.isEmpty || id == lastPromptedRideId) return;
      lastPromptedRideId = id;
      pendingRideRequest = next;
      notifyListeners();
      onRideRequest?.call(next);
    } catch (_) {}
  }


  /// Total unread chat messages across conversations (for nav badge).
  Future<void> refreshUnreadMessages() async {
    if (!authenticated) {
      unreadMessages = 0;
      notifyListeners();
      return;
    }
    try {
      final list = await DriverApi.conversations();
      int total = 0;
      for (final item in list) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        total += int.tryParse((m['unreadCount'] ?? m['unread_count'] ?? 0).toString()) ?? 0;
      }
      unreadMessages = total < 0 ? 0 : total;
    } catch (_) {
      // Keep last known count on network errors
    }
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    SharedPreferences.getInstance().then((p) => p.setString(
          'themeMode',
          mode == ThemeMode.light ? 'light' : 'dark',
        ));
    notifyListeners();
  }

  void toggleTheme(bool dark) => setTheme(dark ? ThemeMode.dark : ThemeMode.light);

  void setLanguage(bool swahili) {
    isSwahili = swahili;
    SharedPreferences.getInstance().then((p) => p.setBool('isSwahili', swahili));
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    notifyListeners();
    if (value) {
      startRidePolling();
      DriverApi.setOnline(true).catchError((_) {});
      // Keep GPS alive even when the app is closed/backgrounded while online.
      BackgroundLocationService.instance.start(
        isSwahili: isSwahili,
        activeRideId: activeRideId,
      );
    } else {
      stopRidePolling();
      DriverApi.setOnline(false).catchError((_) {});
      // Stop background tracking only if there is no active ride.
      if (activeRideId == null) {
        BackgroundLocationService.instance.stop();
      }
    }
  }

  void setNav(int index) {
    navIndex = index;
    notifyListeners();
    // Refresh badge when user opens Chat tab (index 2)
    if (index == 2) {
      refreshUnreadMessages();
    }
  }

  void setApplicationStatus(String status) {
    applicationStatus = status;
    notifyListeners();
  }

  void setActiveRideId(String? id) {
    activeRideId = id;
    notifyListeners();
    if (id != null || online) {
      BackgroundLocationService.instance.restart(
        isSwahili: isSwahili,
        activeRideId: id,
      );
    } else {
      BackgroundLocationService.instance.stop();
    }
  }

  String get displayName {
    final n = profile?['full_name'] ?? profile?['fullName'] ?? profile?['name'];
    return (n == null || n.toString().isEmpty) ? 'Driver' : n.toString();
  }

  /// Translate helper: returns Swahili when language is Kiswahili, otherwise English.
  String t(String en, String sw) => isSwahili ? sw : en;
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child})
      : super(notifier: notifier);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
