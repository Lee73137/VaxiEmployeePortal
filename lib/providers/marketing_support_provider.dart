import 'package:flutter/foundation.dart';
import '../api/marketing_support_api.dart';
import '../models/marketing_support.dart';

class MarketingSupportProvider extends ChangeNotifier {
  final MarketingSupportApi api = MarketingSupportApi();

  List<MarketingSupportListItem> items = [];
  String search = '';
  String statusFilter = '';
  bool isLoading = false;
  String? errorMessage;

  Future<void> refresh(String? username) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await api.list(
        username: username,
        search: search.trim().isEmpty ? null : search.trim(),
        statusFilter: statusFilter.isEmpty ? null : statusFilter,
      );
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

  Future<void> setStatusFilter(String status, String? username) async {
    statusFilter = status;
    await refresh(username);
  }

  Future<int?> create(MarketingSupportSaveRequest request) async {
    try {
      return await api.create(request);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(int id, MarketingSupportSaveRequest request) async {
    try {
      await api.update(id, request);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(int id, String? username) async {
    try {
      await api.delete(id, username);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
