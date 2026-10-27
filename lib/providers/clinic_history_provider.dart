import 'package:flutter/foundation.dart';
import '../api/clinic_history_api.dart';
import '../api/api_client.dart';
import '../models/clinic_history.dart';

class ClinicHistoryProvider extends ChangeNotifier {
  final ClinicHistoryApi api;

  List<ClinicHistoryListItem> _all = [];
  String search = '';
  bool isLoading = false;
  String? errorMessage;

  ClinicHistoryProvider(ApiClient client) : api = ClinicHistoryApi(client);

  List<ClinicHistoryListItem> get items {
    if (search.trim().isEmpty) return _all;
    final term = search.trim().toLowerCase();
    return _all.where((c) {
      return (c.clinicName?.toLowerCase().contains(term) ?? false) ||
          (c.clinicMunicipality?.toLowerCase().contains(term) ?? false) ||
          (c.location?.toLowerCase().contains(term) ?? false) ||
          (c.salesRep?.toLowerCase().contains(term) ?? false);
    }).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _all = await api.list();
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
