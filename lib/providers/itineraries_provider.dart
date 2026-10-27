import 'package:flutter/foundation.dart';
import '../api/itineraries_api.dart';
import '../models/itinerary.dart';

class ItinerariesProvider extends ChangeNotifier {
  final ItinerariesApi api = ItinerariesApi();

  List<Itinerary> items = [];
  bool canApprove = false;
  bool repFilterLocked = false;
  String search = '';
  DateTime dateFrom = DateTime.now().subtract(const Duration(days: 6));
  DateTime dateTo = DateTime.now();
  bool pendingOnly = false;
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
        dateFrom: dateFrom,
        dateTo: dateTo,
        pendingOnly: pendingOnly,
      );
      items = result.items;
      canApprove = result.canApprove;
      repFilterLocked = result.repFilterLocked;
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

  Future<void> setDateRange(DateTime from, DateTime to, String? username) async {
    dateFrom = from;
    dateTo = to;
    await refresh(username);
  }

  Future<void> setPendingOnly(bool value, String? username) async {
    pendingOnly = value;
    await refresh(username);
  }

  Future<Itinerary?> save(ItinerarySaveRequest request, {int? itineraryId}) async {
    try {
      final saved = itineraryId == null ? await api.create(request) : await api.update(itineraryId, request);
      return saved;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
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

  Future<bool> approve(int id, String? username) async {
    try {
      await api.approve(id, username);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int?> approveAll(List<int> ids, String? username) async {
    try {
      return await api.approveAll(ids, username);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
