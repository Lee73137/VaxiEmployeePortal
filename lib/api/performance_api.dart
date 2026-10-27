import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/performance.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi, same as the other Csr* apis in this app.
class PerformanceApi {
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

  Future<PerformanceResponse> get({
    String? username,
    int? year,
    List<String>? reps,
    List<String>? locations,
    bool generated = false,
  }) async {
    final res = await http.get(_uri('api/csrperformance', {
      'username': username,
      'year': year,
      'reps': (reps == null || reps.isEmpty) ? null : reps.join(','),
      'locations': (locations == null || locations.isEmpty) ? null : locations.join(','),
      'generated': generated,
    }));
    return PerformanceResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<ClinicVisitRemark>> clinicRemarks({
    required String repCode,
    required String clinicName,
    required int month,
    required int year,
  }) async {
    final res = await http.get(_uri('api/csrperformance/clinic-remarks', {
      'repCode': repCode,
      'clinicName': clinicName,
      'month': month,
      'year': year,
    }));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => ClinicVisitRemark.fromJson(e as Map<String, dynamic>)).toList();
  }
}
