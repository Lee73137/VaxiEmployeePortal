import 'package:flutter/foundation.dart';
import '../api/collectibles_api.dart';
import '../models/collectible.dart';

class CollectiblesProvider extends ChangeNotifier {
  final CollectiblesApi api = CollectiblesApi();

  List<CollectibleCustomer> items = [];
  List<String> locations = [];
  List<String> salesReps = [];
  int totalItems = 0;
  double totalOpenBalanceAll = 0;
  int customersWithBalanceAll = 0;
  bool repFilterLocked = false;
  bool isTruncated = false;

  String search = '';
  final Set<String> selectedLocations = {};
  final Set<String> selectedSalesReps = {};

  bool isLoading = false;
  String? errorMessage;

  Future<void> refresh(String? username) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.list(
        username: username,
        search: search.trim().isEmpty ? null : search.trim(),
        locations: selectedLocations.toList(),
        salesReps: selectedSalesReps.toList(),
      );
      items = result.items;
      locations = result.locations;
      salesReps = result.salesReps;
      totalItems = result.totalItems;
      totalOpenBalanceAll = result.totalOpenBalanceAll;
      customersWithBalanceAll = result.customersWithBalanceAll;
      repFilterLocked = result.repFilterLocked;
      isTruncated = result.isTruncated;
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

  Future<void> toggleLocation(String location, String? username) async {
    if (!selectedLocations.add(location)) selectedLocations.remove(location);
    await refresh(username);
  }

  Future<void> toggleSalesRep(String rep, String? username) async {
    if (!selectedSalesReps.add(rep)) selectedSalesReps.remove(rep);
    await refresh(username);
  }

  Future<void> clearFilters(String? username) async {
    selectedLocations.clear();
    selectedSalesReps.clear();
    await refresh(username);
  }
}
