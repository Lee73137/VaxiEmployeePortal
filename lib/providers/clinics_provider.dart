import 'package:flutter/foundation.dart';
import '../api/clinics_api.dart';
import '../api/api_client.dart';
import '../models/clinic.dart';

class ClinicsProvider extends ChangeNotifier {
  final ClinicsApi api;

  List<Clinic> _all = [];
  String status = 'active';
  String search = '';
  bool isLoading = false;
  String? errorMessage;

  ClinicsProvider(ApiClient client) : api = ClinicsApi(client);

  List<Clinic> get clinics {
    if (search.trim().isEmpty) return _all;
    final term = search.trim().toLowerCase();
    return _all.where((c) {
      return (c.clinicName?.toLowerCase().contains(term) ?? false) ||
          (c.clinicMunicipality?.toLowerCase().contains(term) ?? false) ||
          (c.areaCode?.toLowerCase().contains(term) ?? false) ||
          (c.contactPerson?.toLowerCase().contains(term) ?? false);
    }).toList();
  }

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _all = await api.list(status: status);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setStatus(String newStatus) async {
    status = newStatus;
    await refresh();
  }

  void setSearch(String term) {
    search = term;
    notifyListeners();
  }

  Future<Clinic?> save(Clinic clinic) async {
    try {
      final saved = clinic.clinicId == null
          ? await api.create(clinic)
          : await api.update(clinic.clinicId!, clinic);
      await refresh();
      return saved;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> setActive(int id, bool active) async {
    try {
      await api.setActive(id, active);
      await refresh();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      await api.delete(id);
      await refresh();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
