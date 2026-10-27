import 'package:flutter/foundation.dart';
import '../api/inventory_api.dart';
import '../api/api_client.dart';
import '../models/inventory_item.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryApi api;

  List<InventoryItem> _all = [];
  DateTime? lastSyncedAtPh;
  String search = '';
  bool isLoading = false;
  String? errorMessage;

  InventoryProvider(ApiClient client) : api = InventoryApi(client);

  List<InventoryItem> get items {
    if (search.trim().isEmpty) return _all;
    final term = search.trim().toLowerCase();
    return _all.where((i) => i.displayCode.toLowerCase().contains(term)).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await api.list();
      _all = response.items;
      lastSyncedAtPh = response.lastSyncedAtPh;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String term) {
    search = term;
    notifyListeners();
  }
}
