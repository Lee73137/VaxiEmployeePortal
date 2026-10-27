import 'package:flutter/foundation.dart';
import '../api/customers_api.dart';
import '../api/api_client.dart';
import '../models/customer.dart';

class CustomersProvider extends ChangeNotifier {
  final CustomersApi api;

  List<Customer> _all = [];
  String status = 'active';
  String search = '';
  bool isLoading = false;
  String? errorMessage;

  CustomersProvider(ApiClient client) : api = CustomersApi(client);

  List<Customer> get customers {
    if (search.trim().isEmpty) return _all;
    final term = search.trim().toLowerCase();
    return _all.where((c) {
      return (c.fullname?.toLowerCase().contains(term) ?? false) ||
          (c.name?.toLowerCase().contains(term) ?? false) ||
          (c.companyname?.toLowerCase().contains(term) ?? false) ||
          (c.city?.toLowerCase().contains(term) ?? false) ||
          (c.location?.toLowerCase().contains(term) ?? false);
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

  Future<Customer?> save(Customer customer) async {
    try {
      final saved = customer.customerid == null
          ? await api.create(customer)
          : await api.update(customer.customerid!, customer);
      await refresh();
      return saved;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
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
