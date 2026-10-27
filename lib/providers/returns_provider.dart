import 'package:flutter/foundation.dart';
import '../api/returns_api.dart';
import '../api/api_client.dart';
import '../models/return_record.dart';

class ReturnsProvider extends ChangeNotifier {
  final ReturnsApi api;

  ReturnListResponse? list;
  String search = '';
  int page = 1;
  bool isLoading = false;
  String? errorMessage;

  ReturnsProvider(ApiClient client) : api = ReturnsApi(client);

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      list = await api.list(search: search, page: page);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setSearch(String term) async {
    search = term;
    page = 1;
    await refresh();
  }

  Future<void> goToPage(int p) async {
    page = p;
    await refresh();
  }
}
