import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/collectible.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi, same as ItinerariesApi - see that file and the
// module's memory entry for why (no bearer-token auth on this backend).
class CollectiblesApi {
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

  Future<CollectibleListResponse> list({
    String? username,
    String? search,
    List<String>? locations,
    List<String>? salesReps,
  }) async {
    final res = await http.get(_uri('api/csrcollectibles', {
      'username': username,
      'search': search,
      'location': (locations == null || locations.isEmpty) ? null : locations.join(','),
      'salesRep': (salesReps == null || salesReps.isEmpty) ? null : salesReps.join(','),
    }));
    return CollectibleListResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<CollectibleInvoice>> invoices(String customerName) async {
    final res = await http.get(_uri('api/csrcollectibles/invoices', {'customerName': customerName}));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => CollectibleInvoice.fromJson(e as Map<String, dynamic>)).toList();
  }
}
