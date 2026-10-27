import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/clinic_account.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi, same as ItinerariesApi/CollectiblesApi - see those
// files and the module's memory entry for why (no bearer-token auth here).
class ClinicAccountsApi {
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null) q[k] = v.toString();
    });
    return Uri.parse('$itinerariesApiBaseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    Map<String, dynamic>? body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : null;
    } catch (_) {
      body = null;
    }
    final message = (body?['error'] as String?) ?? (body?['Message'] as String?) ?? response.reasonPhrase ?? 'Request failed';
    throw ApiException(response.statusCode, message, body: body);
  }

  Future<ClinicAccountListResponse> list({String? username, String? search, int page = 1}) async {
    final res = await http.get(_uri('api/csrclinicaccounts', {'username': username, 'search': search, 'page': page}));
    return ClinicAccountListResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  /// Sends a real password-reset email to the account's real address - the
  /// caller (the screen) must confirm with the user before calling this.
  Future<bool> sendPasswordReset(String userId, String userEmail) async {
    final res = await http.post(
      _uri('api/csrclinicaccounts/send-password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'userEmail': userEmail}),
    );
    final data = _handle(res) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(200, data['message'] as String? ?? 'Could not send reset link.');
    }
    return true;
  }
}
