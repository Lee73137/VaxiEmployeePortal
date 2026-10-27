import '../models/invoice.dart';
import 'api_client.dart';

class InvoicesApi {
  final ApiClient client;

  InvoicesApi(this.client);

  Future<InvoiceDashboard> dashboard({
    int ovPage = 1,
    String ovSort = 'duedate',
    String ovDir = 'desc',
    int dsPage = 1,
    String dsSort = 'duedate',
    String dsDir = 'asc',
  }) async {
    final data = await client.get(
      'api/csrinvoices?ovPage=$ovPage&ovSort=$ovSort&ovDir=$ovDir&dsPage=$dsPage&dsSort=$dsSort&dsDir=$dsDir',
    ) as Map<String, dynamic>;
    return InvoiceDashboard.fromJson(data);
  }

  Future<InvoiceItemsResponse> items(int id) async {
    final data = await client.get('api/csrinvoices/$id/items') as Map<String, dynamic>;
    return InvoiceItemsResponse.fromJson(data);
  }
}
