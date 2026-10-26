import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class DriverApi {
  /* -------------------- Auth -------------------- */
  static Future<Map<String, dynamic>> sendOtp({String? phone, required String email, String purpose = 'login'}) async {
    final d = await ApiClient.data('POST', '/auth/driver/send-otp', body: {
      if (phone != null) 'phone': phone,
      'email': email,
      'purpose': purpose,
    }, auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> sendEmailOtp(String email, {String purpose = 'driver_registration'}) async {
    final d = await ApiClient.data('POST', '/auth/driver/send-email-otp', body: {
      'email': email,
      'purpose': purpose,
    }, auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /// Validates a registration OTP without consuming it (backend uses peek/verify-check).
  static Future<Map<String, dynamic>> verifyRegistrationOtp({
    required String target,
    required String code,
    String purpose = 'driver_registration',
  }) async {
    final d = await ApiClient.data('POST', '/auth/driver/verify-otp', body: {
      'target': target,
      'code': code,
      'purpose': purpose,
    }, auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> login({required String email, required String code}) async {
    final d = await ApiClient.data('POST', '/auth/driver/login', body: {
      'email': email,
      'code': code,
    }, auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /* -------------------- Registration -------------------- */
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String email,
    required String nationalId,
    required String homeAddress,
    required String vehicleType,
    required String plateNumber,
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleColor,
    required int? modelYear,
    required String emailOtpCode,
    required Map<String, List<String>> files,
    Map<String, String>? expirations,
  }) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/driver/register');
    final req = http.MultipartRequest('POST', uri);
    req.fields.addAll({
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'nationalId': nationalId,
      'homeAddress': homeAddress,
      'vehicleType': vehicleType.toLowerCase(),
      'plateNumber': plateNumber,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'modelYear': modelYear?.toString() ?? '',
      'emailOtpCode': emailOtpCode,
    });
    for (final entry in files.entries) {
      for (final path in entry.value) {
        req.files.add(await http.MultipartFile.fromPath(entry.key, path));
      }
    }
    if (expirations != null) {
      for (final e in expirations.entries) {
        req.fields['expires_${e.key}'] = e.value;
      }
    }
    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final res = streamed;
    final body = await res.stream.bytesToString().timeout(const Duration(seconds: 30));
    Map<String, dynamic> data = {};
    try {
      if (body.isNotEmpty) data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      // Server may have completed even if body is truncated
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return <String, dynamic>{'status': 'pending', 'applicationStatus': 'pending'};
      }
      throw Exception('Registration response was unreadable');
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || data['success'] == false) {
      throw Exception(data['message'] ?? 'Registration failed (${res.statusCode})');
    }
    final payload = data['data'];
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return <String, dynamic>{'status': 'pending', 'applicationStatus': 'pending', 'raw': payload};
  }

  /* -------------------- Profile -------------------- */
  static Future<Map<String, dynamic>> profile() async {
    final d = await ApiClient.data('GET', '/driver/me');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<List<dynamic>> documents() async {
    final d = await ApiClient.data('GET', '/driver/documents');
    return List<dynamic>.from(d is List ? d : []);
  }

  /* -------------------- Availability & location -------------------- */
  static Future<void> setOnline(bool online) async {
    await ApiClient.data('PATCH', '/driver/online', body: {'online': online});
  }

  static Future<void> updateLocation(double lat, double lng, {double? heading, double? speed, String? rideId}) async {
    await ApiClient.data('POST', '/driver/location', body: {
      'lat': lat,
      'lng': lng,
      if (rideId != null) 'rideId': int.tryParse(rideId) ?? rideId,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
    });
  }

  /* -------------------- Rides -------------------- */
  static Future<Map<String, dynamic>> requests() async {
    final d = await ApiClient.data('GET', '/driver/ride-requests');
    return Map<String, dynamic>.from(d is Map ? d : {'requests': d is List ? d : []});
  }

  static Future<void> accept(String id) async {
    await ApiClient.data('POST', '/driver/rides/$id/accept');
  }

  /// Changes the ride status. `otp` is the rider's 4-digit PIN and is required for `started`.
  static Future<Map<String, dynamic>> status(String id, String status, {String? otp}) async {
    final d = await ApiClient.data('PATCH', '/driver/rides/$id/status', body: {
      'status': status,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
    });
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /// Full live ride (rider name/phone, coordinates, payment state, earnings once completed).
  static Future<Map<String, dynamic>> ride(String id) async {
    final d = await ApiClient.data('GET', '/driver/rides/$id');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /// Tells the rider the drop-off was reached; the rider then pays.
  static Future<Map<String, dynamic>> reachedDestination(String id) async {
    final d = await ApiClient.data('POST', '/driver/rides/$id/reached-destination');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /// Driver confirms the rider handed over the cash. Ends the ride.
  static Future<Map<String, dynamic>> collectCash(String id) async {
    final d = await ApiClient.data('POST', '/driver/rides/$id/collect-cash');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<List<dynamic>> history({int limit = 50}) async {
    final d = await ApiClient.data('GET', '/driver/rides?limit=$limit');
    if (d is List) return List<dynamic>.from(d);
    if (d is Map) {
      final rows = d['rides'] ?? d['data'] ?? d['items'] ?? [];
      return List<dynamic>.from(rows is List ? rows : []);
    }
    return <dynamic>[];
  }

  /* -------------------- Finance -------------------- */
  static Future<Map<String, dynamic>> finance() async {
    final d = await ApiClient.data('GET', '/driver/finance');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> earnings({String? from, String? to}) async {
    final q = <String>[];
    if (from != null) q.add('from=$from');
    if (to != null) q.add('to=$to');
    final path = '/driver/earnings${q.isEmpty ? '' : '?${q.join('&')}'}';
    final d = await ApiClient.data('GET', path);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> settle({Map<String, dynamic> options = const {}}) async {
    final d = await ApiClient.data('POST', '/driver/settlements', body: options);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<List<dynamic>> settlements() async {
    final d = await ApiClient.data('GET', '/driver/settlements');
    if (d is List) return List<dynamic>.from(d);
    if (d is Map) {
      final rows = d['settlements'] ?? d['data'] ?? d['items'] ?? [];
      return List<dynamic>.from(rows is List ? rows : []);
    }
    return <dynamic>[];
  }

  static Future<Map<String, dynamic>> settlementStatus(String id) async {
    final d = await ApiClient.data('GET', '/driver/settlements/$id');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> autopay({
    required bool enabled,
    String? provider,
    String? providerToken,
  }) async {
    final d = await ApiClient.data('POST', '/driver/autopay', body: {
      'enabled': enabled,
      if (provider != null) 'provider': provider,
      if (providerToken != null) 'providerToken': providerToken,
    });
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<List<dynamic>> paymentMethods() async {
    final d = await ApiClient.data('GET', '/driver/payment-methods');
    return List<dynamic>.from(d is List ? d : []);
  }

  static Future<Map<String, dynamic>> addPaymentMethod(Map<String, dynamic> body) async {
    final d = await ApiClient.data('POST', '/driver/payment-methods', body: body);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<void> removePaymentMethod(String id) async {
    await ApiClient.data('DELETE', '/driver/payment-methods/$id');
  }

  static Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String method,
    Map<String, dynamic>? accountDetails,
  }) async {
    final d = await ApiClient.data('POST', '/driver/payout', body: {
      'amount': amount,
      'method': method,
      if (accountDetails != null) 'accountDetails': accountDetails,
    });
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /* -------------------- Chat -------------------- */
  static Future<List<dynamic>> conversations() async {
    final d = await ApiClient.data('GET', '/driver/chat');
    return List<dynamic>.from(d is List ? d : []);
  }

  static Future<Map<String, dynamic>> openSupport() async {
    final d = await ApiClient.data('POST', '/driver/chat/support');
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<List<dynamic>> messages(String conversationId) async {
    final d = await ApiClient.data('GET', '/driver/chat/$conversationId/messages');
    return List<dynamic>.from(d is List ? d : []);
  }

  /// Opens (or creates) the chat thread for a ride and returns its conversation id.
  static Future<String> rideConversation(String rideId) async {
    final d = await ApiClient.data('POST', '/driver/chat/ride/$rideId');
    final m = Map<String, dynamic>.from(d is Map ? d : {});
    return (m['conversationId'] ?? m['id'] ?? '').toString();
  }

  static Future<void> editMessage(String conversationId, String messageId, String text) async {
    await ApiClient.data('PATCH', '/driver/chat/$conversationId/messages/$messageId', body: {'text': text});
  }

  static Future<void> markRead(String conversationId) async {
    await ApiClient.data('POST', '/driver/chat/$conversationId/read');
  }

  static Future<void> deleteMessage(String conversationId, String messageId) async {
    await ApiClient.data('DELETE', '/driver/chat/$conversationId/messages/$messageId');
  }

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String text) async {
    final d = await ApiClient.data('POST', '/driver/chat/$conversationId/messages', body: {
      'text': text,
    });
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  
  static Future<Map<String, dynamic>> applicationStatus(String driverId) async {
    final d = await ApiClient.data('GET', '/driver/application-status/$driverId', auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<List<dynamic>> reviews() async {
    final d = await ApiClient.data('GET', '/driver/reviews');
    return List<dynamic>.from(d is List ? d : []);
  }

  static Future<List<dynamic>> changeRequests() async {
    final d = await ApiClient.data('GET', '/driver/change-requests');
    return List<dynamic>.from(d is List ? d : []);
  }

  static Future<Map<String, dynamic>> requestProfileChange({
    required String field,
    required String newValue,
    String? reason,
  }) async {
    final d = await ApiClient.data('POST', '/driver/change-requests/profile', body: {
      'field': field,
      'newValue': newValue,
      if (reason != null) 'reason': reason,
    });
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> requestVehicleChange(Map<String, dynamic> body) async {
    final d = await ApiClient.data('POST', '/driver/change-requests/vehicle', body: body);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> updateProfilePhoto(String path) async {
    final uri = Uri.parse('${ApiClient.baseUrl}/driver/profile-photo');
    final req = http.MultipartRequest('POST', uri);
    final token = await ApiClient.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Access token required. Please log in again.');
    }
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';
    req.files.add(await http.MultipartFile.fromPath('photo', path));
    final streamed = await req.send().timeout(ApiClient.requestTimeout);
    final body = await streamed.stream.bytesToString();
    Map<String, dynamic> data = {};
    try {
      if (body.isNotEmpty) data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {}
    if (streamed.statusCode == 401) {
      throw Exception(data['message'] ?? 'Access token required. Please log in again.');
    }
    if (streamed.statusCode < 200 || streamed.statusCode >= 300 || data['success'] == false) {
      throw Exception(data['message'] ?? 'Photo upload failed (${streamed.statusCode})');
    }
    return Map<String, dynamic>.from(data['data'] ?? {});
  }

  static Future<void> removeProfilePhoto() async {
    await ApiClient.data('DELETE', '/driver/profile-photo');
  }

  /* -------------------- Notifications -------------------- */
  static Future<void> registerFcmToken(String token, {String platform = 'android'}) async {
    await ApiClient.data('POST', '/driver/notifications/token', body: {
      'token': token,
      'platform': platform,
    });
  }

  static Future<List<dynamic>> notifications() async {
    final d = await ApiClient.data('GET', '/driver/notifications');
    return List<dynamic>.from(d is List ? d : []);
  }


  static Future<List<Map<String, dynamic>>> placesAutocomplete(String input) async {
    if (input.trim().length < 2) return [];
    final d = await ApiClient.data('GET', '/driver/places/autocomplete?input=${Uri.encodeQueryComponent(input)}', auth: false);
    final preds = (d is Map ? (d['predictions'] ?? []) : []) as List;
    return preds.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> placeDetails(String placeId) async {
    final d = await ApiClient.data('GET', '/driver/places/details?placeId=${Uri.encodeQueryComponent(placeId)}', auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  /// Exchange driverId + email for access/refresh tokens (post-registration / post-approval).
  static Future<Map<String, dynamic>> bootstrapSession({
    required String driverId,
    required String email,
  }) async {
    final d = await ApiClient.data('POST', '/driver/bootstrap-session', body: {
      'driverId': driverId,
      'email': email,
    }, auth: false);
    return Map<String, dynamic>.from(d is Map ? d : {});
  }
}
