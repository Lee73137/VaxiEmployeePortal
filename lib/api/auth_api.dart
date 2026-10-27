import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class AuthResult {
  final String userName;
  final String? fullName;
  final String? repCode;

  AuthResult({required this.userName, this.fullName, this.repCode});
}

class AuthApiException implements Exception {
  final String message;
  AuthApiException(this.message);
  @override
  String toString() => message;
}

class AuthApi {
  // vaximobileapi's vaxiauthenticateController - validates against the
  // vaxitrack AspNetUsers table and returns the user's details. It issues no
  // token, so the session is just the returned username.
  Future<AuthResult> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${itinerariesApiBaseUrl}api/vaxiauthenticate/authenticate'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'Username': username, 'Password': password}),
    );

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthApiException('Login failed (${response.statusCode})');
    }

    if (response.statusCode != 200 || data['success'] != true) {
      throw AuthApiException((data['message'] as String?) ?? 'Login failed');
    }

    final user = data['data'] as Map<String, dynamic>? ?? const {};
    return AuthResult(
      userName: user['UserName'] as String? ?? username,
      fullName: user['fullname'] as String?,
      repCode: user['repcode'] as String?,
    );
  }
}
