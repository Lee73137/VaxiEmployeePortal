import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/marketing_support.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi (NOT vaxiCSR.Api) - same no-bearer-token-auth
// caveat as every other Csr* module here (see ItinerariesApi). The clinic
// picker reuses api/csritineraries/search-clinics directly rather than
// duplicating it (see ItinerariesApi.searchClinics / ItineraryClinicOption).
class MarketingSupportApi {
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

  Future<List<MarketingSupportListItem>> list({String? username, String? search, String? statusFilter, String? requestTypeFilter}) async {
    final res = await http.get(_uri('api/csrmarketingsupport', {
      'username': username,
      'search': search,
      'statusFilter': statusFilter,
      'requestTypeFilter': requestTypeFilter,
    }));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => MarketingSupportListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MarketingSupportDetail> get(int id, {String? username}) async {
    final res = await http.get(_uri('api/csrmarketingsupport/$id', {'username': username}));
    return MarketingSupportDetail.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<String>> searchItems(String term) async {
    final res = await http.get(_uri('api/csrmarketingsupport/search-items', {'term': term}));
    final data = _handle(res) as List<dynamic>;
    return data.cast<String>();
  }

  Future<int> create(MarketingSupportSaveRequest request) async {
    final res = await http.post(_uri('api/csrmarketingsupport'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson()));
    final data = _handle(res) as Map<String, dynamic>;
    return data['requestId'] as int;
  }

  Future<void> update(int id, MarketingSupportSaveRequest request) async {
    _handle(await http.put(_uri('api/csrmarketingsupport/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson())));
  }

  Future<void> delete(int id, String? username) async {
    _handle(await http.delete(_uri('api/csrmarketingsupport/$id', {'username': username})));
  }

  Future<MarketingSupportItem> addItem(int requestId, String itemCode, int qty) async {
    final res = await http.post(
      _uri('api/csrmarketingsupport/$requestId/items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'itemCode': itemCode, 'qty': qty}),
    );
    return MarketingSupportItem.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<void> updateItem(int requestDetailId, String itemCode, int qty) async {
    _handle(await http.put(
      _uri('api/csrmarketingsupport/items/$requestDetailId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'itemCode': itemCode, 'qty': qty}),
    ));
  }

  Future<void> deleteItem(int requestDetailId) async {
    _handle(await http.delete(_uri('api/csrmarketingsupport/items/$requestDetailId')));
  }

  Future<void> decision(int requestId, String? username, String status, String? reason) async {
    _handle(await http.post(
      _uri('api/csrmarketingsupport/$requestId/decision'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'status': status, 'reason': reason}),
    ));
  }

  Future<void> markFulfilled(int requestId, String? username, String status) async {
    _handle(await http.post(
      _uri('api/csrmarketingsupport/$requestId/mark-fulfilled'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'status': status}),
    ));
  }
}
