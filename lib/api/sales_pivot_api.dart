import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/sales_pivot.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi, same as the other Csr* apis in this app.
class SalesPivotApi {
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

  Future<SalesPivotResponse> get({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? reps,
    bool onlyEveryMonth = false,
  }) async {
    final res = await http.get(_uri('api/csrsalespivot', {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'reps': (reps == null || reps.isEmpty) ? null : reps.join(','),
      'onlyEveryMonth': onlyEveryMonth,
    }));
    return SalesPivotResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<SalesPivotInvoice>> clinicInvoices(String clinicName, DateTime startDate, DateTime endDate) async {
    final res = await http.get(_uri('api/csrsalespivot/clinic-invoices', {
      'clinicName': clinicName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    }));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => SalesPivotInvoice.fromJson(e as Map<String, dynamic>)).toList();
  }
}
