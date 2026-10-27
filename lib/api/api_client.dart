import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;

  ApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin HTTP wrapper for the modules ported from vaxiCSR.Api to vaximobileapi
/// (Customers, Invoices, Clinics, Clinic History, Inventory, Forecast,
/// Returns - its api/csr* routes). That API has no bearer-token auth, so the
/// logged-in username rides along as a plain `username` query param on every
/// request instead - same client-asserted model as ItinerariesApi.
class ApiClient {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'vaxicsr_access_token';
  static const _userNameKey = 'vaxicsr_user_name';
  static const _fullNameKey = 'vaxicsr_full_name';
  static const _repCodeKey = 'vaxicsr_rep_code';

  // Fires whenever any request comes back 401 (expired/invalid/missing
  // token), so the app shell can react in one place - clear the stored
  // token and bounce back to the login screen - instead of every screen
  // having to handle it individually.
  final StreamController<void> _unauthorizedController = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  Future<String?> get token => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  // Persisted alongside the token so a restored session (app restart) knows
  // who's actually logged in, not just that *someone* is - needed by the
  // Itineraries module (vaximobileapi has no bearer-token auth of its own,
  // so it relies on this client-asserted username - see memory).
  Future<String?> get userName => _storage.read(key: _userNameKey);

  Future<void> saveUserName(String userName) => _storage.write(key: _userNameKey, value: userName);

  Future<void> clearUserName() => _storage.delete(key: _userNameKey);

  // Display name for the dashboard greeting/menu header, from the login reply.
  Future<String?> get fullName => _storage.read(key: _fullNameKey);

  Future<void> saveFullName(String? fullName) =>
      fullName == null ? _storage.delete(key: _fullNameKey) : _storage.write(key: _fullNameKey, value: fullName);

  // Rep code from the login reply, shown on the Profile page.
  Future<String?> get repCode => _storage.read(key: _repCodeKey);

  Future<void> saveRepCode(String? repCode) =>
      repCode == null ? _storage.delete(key: _repCodeKey) : _storage.write(key: _repCodeKey, value: repCode);

  Future<Map<String, String>> _authHeaders({bool json = true}) async {
    final t = await token;
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<Uri> _uri(String path) async {
    final uri = Uri.parse('$itinerariesApiBaseUrl$path');
    final u = await userName;
    if (u == null) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, 'username': u});
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(await _uri(path), headers: await _authHeaders());
    return _handle(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(await _uri(path), headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(await _uri(path), headers: await _authHeaders(), body: jsonEncode(body));
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(await _uri(path), headers: await _authHeaders());
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // Only a rejected token means the session expired. Login (vaximobileapi)
    // issues no token, so a 401 on a tokenless request must not log out.
    if (response.statusCode == 401 && (response.request?.headers.containsKey('Authorization') ?? false)) {
      clearToken();
      _unauthorizedController.add(null);
    }

    Map<String, dynamic>? body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : null;
    } catch (_) {
      body = null;
    }
    throw ApiException(response.statusCode, response.reasonPhrase ?? 'Request failed', body: body);
  }
}
