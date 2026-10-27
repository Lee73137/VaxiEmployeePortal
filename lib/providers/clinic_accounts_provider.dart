import 'package:flutter/foundation.dart';
import '../api/clinic_accounts_api.dart';
import '../models/clinic_account.dart';

class ClinicAccountsProvider extends ChangeNotifier {
  final ClinicAccountsApi api = ClinicAccountsApi();

  List<ClinicAccount> items = [];
  int page = 1;
  int pageSize = 25;
  int totalItems = 0;
  bool repFilterLocked = false;
  String search = '';
  bool isLoading = false;
  String? errorMessage;

  int get totalPages => totalItems == 0 ? 1 : ((totalItems + pageSize - 1) ~/ pageSize);

  Future<void> refresh(String? username) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.list(username: username, search: search.trim().isEmpty ? null : search.trim(), page: page);
      items = result.items;
      page = result.page;
      pageSize = result.pageSize;
      totalItems = result.totalItems;
      repFilterLocked = result.repFilterLocked;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void setSearch(String term) {
    search = term;
    page = 1;
    notifyListeners();
  }

  Future<void> goToPage(int newPage, String? username) async {
    if (newPage < 1 || newPage > totalPages) return;
    page = newPage;
    await refresh(username);
  }

  Future<bool> sendPasswordReset(ClinicAccount account) async {
    try {
      await api.sendPasswordReset(account.id, account.email ?? '');
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
