import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/clinic_booking.dart';
import '../offline/booking_offline.dart' show OfflinePack;
import 'api_client.dart' show ApiException;

// A dead/weak connection should fail fast enough to fall back to saving on
// the phone, not hang the form.
const _timeout = Duration(seconds: 25);

// Talks to vaximobileapi (NOT vaxiCSR.Api) - same no-bearer-token-auth
// caveat as every other Csr* module here (see ItinerariesApi).
class ClinicBookingsApi {
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

  Future<BookingListResponse> list({String? username, required DateTime dateFrom, required DateTime dateTo}) async {
    final res = await http.get(_uri('api/csrclinicbookings', {
      'username': username,
      'dateFrom': dateFrom.toIso8601String(),
      'dateTo': dateTo.toIso8601String(),
    }));
    return BookingListResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<PriceCorrection>> priceCorrections(String referenceNo) async {
    final res = await http.get(_uri('api/csrclinicbookings/price-corrections', {'referenceNo': referenceNo}));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => PriceCorrection.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BookingClinicOption>> searchClinics(String term, {String? username}) async {
    final res = await http.get(_uri('api/csrclinicbookings/search-clinics', {'term': term, 'username': username}));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => BookingClinicOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UnpaidInvoicesResponse> unpaidInvoices(String clinicName) async {
    final res = await http.get(_uri('api/csrclinicbookings/unpaid-invoices', {'clinicName': clinicName}));
    return UnpaidInvoicesResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  Future<List<String>> searchItems(String term) async {
    final res = await http.get(_uri('api/csrclinicbookings/search-items', {'term': term}));
    final data = _handle(res) as List<dynamic>;
    return data.cast<String>();
  }

  Future<List<BookingLineInput>> itemPreview(String itemCode, int qty) async {
    final res = await http.get(_uri('api/csrclinicbookings/item-preview', {'itemcode': itemCode, 'qty': qty})).timeout(_timeout);
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => BookingLineInput.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PromoOption>> promos() async {
    final res = await http.get(_uri('api/csrclinicbookings/promos'));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => PromoOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BookingRepOption>> reps({String? username}) async {
    final res = await http.get(_uri('api/csrclinicbookings/reps', {'username': username}));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => BookingRepOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreateBookingResponse> create(CreateBookingRequest request) async {
    final res = await http
        .post(_uri('api/csrclinicbookings'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(request.toJson()))
        .timeout(_timeout);
    return CreateBookingResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  /// Clinics, items with pricing, reps and promos for offline booking.
  Future<OfflinePack> offlinePack({String? username}) async {
    final res = await http.get(_uri('api/csrclinicbookings/offline-pack', {'username': username})).timeout(const Duration(seconds: 90));
    return OfflinePack.fromJson(_handle(res) as Map<String, dynamic>);
  }
}
