import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/itinerary.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi (NOT vaxiCSR.Api) - see the Itineraries module's own
// memory entry for why. That API has no bearer-token auth at all, so every
// call here sends the logged-in username as a plain, client-asserted query
// param instead of an Authorization header - it's a real business-rule input
// (rep-scoping, approval rights), not a security boundary.
class ItinerariesApi {
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

  Future<ItineraryListResponse> list({
    String? username,
    String? search,
    int? repId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool pendingOnly = false,
  }) async {
    final res = await http.get(_uri('api/csritineraries', {
      'username': username,
      'search': search,
      'repId': repId,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'pendingOnly': pendingOnly,
    }));
    return ItineraryListResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<Itinerary> get(int id) async {
    final res = await http.get(_uri('api/csritineraries/$id'));
    return Itinerary.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<ItineraryActivity>> activities() async {
    final res = await http.get(_uri('api/csritineraries/activities'));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => ItineraryActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ItineraryClinicOption>> searchClinics(String term) async {
    final res = await http.get(_uri('api/csritineraries/search-clinics', {'term': term}));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => ItineraryClinicOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Itinerary> create(ItinerarySaveRequest request) async {
    final res = await http.post(_uri('api/csritineraries'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson()));
    return Itinerary.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<Itinerary> update(int id, ItinerarySaveRequest request) async {
    final res = await http.put(_uri('api/csritineraries/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson()));
    return Itinerary.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<void> delete(int id, String? username) async {
    _handle(await http.delete(_uri('api/csritineraries/$id', {'username': username})));
  }

  Future<void> approve(int id, String? username) async {
    _handle(await http.post(_uri('api/csritineraries/$id/approve', {'username': username})));
  }

  Future<int> approveAll(List<int> ids, String? username) async {
    final res = await http.post(
      _uri('api/csritineraries/approve-all'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ids': ids, 'username': username}),
    );
    final data = _handle(res) as Map<String, dynamic>;
    return data['count'] as int? ?? 0;
  }

  Future<ItineraryVisit> getVisit(int id) async {
    final res = await http.get(_uri('api/csritineraries/$id/visit'));
    return ItineraryVisit.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<void> submitVisit(int id, {String? drDelivery, double? drDeliveryAmount, double? drCollectionAmountCollected, String? visitRemarks}) async {
    _handle(await http.post(
      _uri('api/csritineraries/$id/visit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'drDelivery': drDelivery,
        'drDeliveryAmount': drDeliveryAmount,
        'drCollectionAmountCollected': drCollectionAmountCollected,
        'visitRemarks': visitRemarks,
      }),
    ));
  }
}
