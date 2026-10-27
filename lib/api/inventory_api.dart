import '../models/inventory_item.dart';
import 'api_client.dart';

class InventoryApi {
  final ApiClient client;

  InventoryApi(this.client);

  Future<InventoryListResponse> list({String? search}) async {
    final query = (search != null && search.trim().isNotEmpty) ? '?search=${Uri.encodeQueryComponent(search.trim())}' : '';
    final data = await client.get('api/csrinventory$query') as Map<String, dynamic>;
    return InventoryListResponse.fromJson(data);
  }

  Future<PendingBookingsResponse> pending(String itemcode, {bool forDr = false}) async {
    final view = forDr ? 'fordr' : 'pending';
    final data = await client.get('api/csrinventory/pending?itemcode=${Uri.encodeQueryComponent(itemcode)}&view=$view') as Map<String, dynamic>;
    return PendingBookingsResponse.fromJson(data);
  }

  Future<String?> description(String itemcode) async {
    final data = await client.get('api/csrinventory/description?itemcode=${Uri.encodeQueryComponent(itemcode)}') as Map<String, dynamic>;
    return data['description'] as String?;
  }

  Future<List<InventoryAuditEntry>> audit(String itemcode) async {
    final data = await client.get('api/csrinventory/audit?itemcode=${Uri.encodeQueryComponent(itemcode)}') as List<dynamic>;
    return data.map((e) => InventoryAuditEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}
