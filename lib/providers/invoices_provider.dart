import 'package:flutter/foundation.dart';
import '../api/invoices_api.dart';
import '../api/api_client.dart';
import '../models/invoice.dart';

class InvoicesProvider extends ChangeNotifier {
  final InvoicesApi api;

  InvoiceDashboard? dashboard;
  int ovPage = 1;
  int dsPage = 1;
  bool isLoading = false;
  String? errorMessage;

  InvoicesProvider(ApiClient client) : api = InvoicesApi(client);

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      dashboard = await api.dashboard(ovPage: ovPage, dsPage: dsPage);
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> goToOverduePage(int page) async {
    ovPage = page;
    await refresh();
  }

  Future<void> goToDueSoonPage(int page) async {
    dsPage = page;
    await refresh();
  }
}
