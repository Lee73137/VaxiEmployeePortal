import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/promo_invoice.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi, same as the other Csr* apis in this app.
class PromoInvoicesApi {
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

  Future<PromoInvoicesResponse> get({
    List<String>? promo,
    String? salesRep,
    DateTime? dateStart,
    DateTime? dateEnd,
    String? status,
  }) async {
    final res = await http.get(_uri('api/csrpromoinvoices', {
      'promo': (promo == null || promo.isEmpty) ? null : promo.join(','),
      'salesRep': salesRep,
      'dateStart': dateStart?.toIso8601String(),
      'dateEnd': dateEnd?.toIso8601String(),
      'status': status,
    }));
    return PromoInvoicesResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }
}
