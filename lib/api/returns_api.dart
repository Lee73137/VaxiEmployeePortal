import '../models/return_record.dart';
import 'api_client.dart';

class ReturnsApi {
  final ApiClient client;

  ReturnsApi(this.client);

  Future<ReturnListResponse> list({String? search, int page = 1}) async {
    final query = (search != null && search.trim().isNotEmpty) ? '&search=${Uri.encodeQueryComponent(search.trim())}' : '';
    final data = await client.get('api/csrreturns?page=$page$query') as Map<String, dynamic>;
    return ReturnListResponse.fromJson(data);
  }

  Future<ReturnRow> details(int id) async {
    final data = await client.get('api/csrreturns/$id') as Map<String, dynamic>;
    // GetDetails doesn't include totalQuantity server-side; compute it here.
    final items = (data['items'] as List<dynamic>? ?? []).map((e) => ReturnItem.fromJson(e as Map<String, dynamic>)).toList();
    return ReturnRow(
      returnRecord: ReturnRecord.fromJson(data['return'] as Map<String, dynamic>),
      items: items,
      totalQuantity: items.fold(0, (sum, i) => sum + i.quantity),
    );
  }

  Future<List<InvoiceSearchResult>> searchInvoices(String term) async {
    final data = await client.get('api/csrreturns/search-invoices?term=${Uri.encodeQueryComponent(term)}') as List<dynamic>;
    return data.map((e) => InvoiceSearchResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InvoiceItemsForReturnResponse> invoiceItems(int invoiceId) async {
    final data = await client.get('api/csrreturns/invoice-items?invoiceId=$invoiceId') as Map<String, dynamic>;
    return InvoiceItemsForReturnResponse.fromJson(data);
  }

  Future<ReturnRow> create({
    required int invoiceId,
    String? referenceId,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await client.post('api/csrreturns', {
      'invoiceId': invoiceId,
      'referenceId': referenceId,
      'items': items,
    }) as Map<String, dynamic>;
    return ReturnRow.fromJson(data);
  }
}
