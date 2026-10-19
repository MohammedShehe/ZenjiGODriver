import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class DriverApi {
  /* -------------------- Auth -------------------- */
  static Future<Map<String, dynamic>> sendOtp(String phone, {String purpose = 'login'}) async {
    final d = await ApiClient.data('POST', '/auth/driver/send-otp', body: {
      'phone': phone,
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

  static Future<Map<String, dynamic>> login(String phone, String code) async {
    final d = await ApiClient.data('POST', '/auth/driver/login', body: {
      'phone': phone,
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
    required String phoneOtpCode,
    required String emailOtpCode,
    required Map<String, List<String>> files,
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
      'phoneOtpCode': phoneOtpCode,
      'emailOtpCode': emailOtpCode,
    });
    for (final entry in files.entries) {
      for (final path in entry.value) {
        req.files.add(await http.MultipartFile.fromPath(entry.key, path));
      }
    }
    final streamed = await req.send().timeout(ApiClient.requestTimeout);
    final res = streamed;
    final body = await res.stream.bytesToString().timeout(ApiClient.requestTimeout);
    final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
    if (res.statusCode < 200 || res.statusCode >= 300 || data['success'] == false) {
      throw Exception(data['message'] ?? 'Registration failed');
    }
    return Map<String, dynamic>.from(data['data'] ?? {});
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

  static Future<void> updateLocation(double lat, double lng, {double? heading, double? speed}) async {
    await ApiClient.data('POST', '/driver/location', body: {
      'lat': lat,
      'lng': lng,
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

  static Future<void> status(String id, String status) async {
    await ApiClient.data('PATCH', '/driver/rides/$id/status', body: {'status': status});
  }

  static Future<List<dynamic>> history({int limit = 50}) async {
    final d = await ApiClient.data('GET', '/driver/rides?limit=$limit');
    return List<dynamic>.from(d is List ? d : []);
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

  static Future<Map<String, dynamic>> settle({String provider = 'example'}) async {
    final d = await ApiClient.data('POST', '/driver/settlements', body: {'provider': provider});
    return Map<String, dynamic>.from(d is Map ? d : {});
  }

  static Future<Map<String, dynamic>> markSettlementPaid(String id, String reference) async {
    final d = await ApiClient.data('POST', '/driver/settlements/$id/mark-paid', body: {
      'externalReference': reference,
    });
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

  static Future<Map<String, dynamic>> sendMessage(String conversationId, String text) async {
    final d = await ApiClient.data('POST', '/driver/chat/$conversationId/messages', body: {
      'text': text,
    });
    return Map<String, dynamic>.from(d is Map ? d : {});
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
}
