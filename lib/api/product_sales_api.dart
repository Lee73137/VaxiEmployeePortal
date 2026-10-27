import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/product_sales.dart';
import 'api_client.dart' show ApiException;

// Talks to vaximobileapi, same as the other Csr* apis in this app.
class ProductSalesApi {
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

  Future<ProductSalesResponse> get({
    String? username,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? reps,
    List<String>? prefixes,
    bool generated = false,
  }) async {
    final res = await http.get(_uri('api/csrproductsales', {
      'username': username,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'reps': (reps == null || reps.isEmpty) ? null : reps.join(','),
      'prefixes': (prefixes == null || prefixes.isEmpty) ? null : prefixes.join(','),
      'generated': generated,
    }));
    return ProductSalesResponse.fromJson(_handle(res) as Map<String, dynamic>);
  }

  /// The invoices behind one Per Customer row; [channel] is VAXISHAPP or VAXIHUB.
  Future<List<ProductSalesCustomerInvoice>> customerInvoices({
    required DateTime dateFrom,
    required DateTime dateTo,
    required String customerName,
    required String channel,
    String? username,
    List<String>? reps,
    List<String>? prefixes,
  }) async {
    final res = await http.get(_uri('api/csrproductsales/customer-invoices', {
      'username': username,
      'dateFrom': dateFrom.toIso8601String(),
      'dateTo': dateTo.toIso8601String(),
      'customerName': customerName,
      'channel': channel,
      'reps': (reps == null || reps.isEmpty) ? null : reps.join(','),
      'prefixes': (prefixes == null || prefixes.isEmpty) ? null : prefixes.join(','),
    }));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => ProductSalesCustomerInvoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OtherProductRow>> others({required DateTime dateFrom, required DateTime dateTo, List<String>? reps}) async {
    final res = await http.get(_uri('api/csrproductsales/others', {
      'dateFrom': dateFrom.toIso8601String(),
      'dateTo': dateTo.toIso8601String(),
      'reps': (reps == null || reps.isEmpty) ? null : reps.join(','),
    }));
    final data = _handle(res) as List<dynamic>;
    return data.map((e) => OtherProductRow.fromJson(e as Map<String, dynamic>)).toList();
  }
}
