import 'package:flutter/foundation.dart';
import '../api/promo_invoices_api.dart';
import '../models/promo_invoice.dart';

class PromoInvoicesProvider extends ChangeNotifier {
  final PromoInvoicesApi api = PromoInvoicesApi();

  bool hasAnyFilter = false;
  List<PromoInvoice> invoices = [];
  double totalAmount = 0;
  List<PromoBookingLine> bookingItems = [];
  double bookingTotalAmount = 0;
  List<String> promoOptions = [];
  List<String> salesRepOptions = [];
  List<String> statusOptions = [];

  final Set<String> selectedPromos = {};
  String? selectedSalesRep;
  String? selectedStatus;
  DateTime? dateStart;
  DateTime? dateEnd;

  bool isLoading = false;
  String? errorMessage;
  bool _loadedOnce = false;

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.get(
        promo: selectedPromos.toList(),
        salesRep: selectedSalesRep,
        dateStart: dateStart,
        dateEnd: dateEnd,
        status: selectedStatus,
      );
      hasAnyFilter = result.hasAnyFilter;
      invoices = result.invoices;
      totalAmount = result.totalAmount;
      bookingItems = result.bookingItems;
      bookingTotalAmount = result.bookingTotalAmount;
      promoOptions = result.promoOptions;
      salesRepOptions = result.salesRepOptions;
      statusOptions = result.statusOptions;
      _loadedOnce = true;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> ensureOptionsLoaded() async {
    if (_loadedOnce) return;
    await refresh();
  }

  void togglePromo(String promo) {
    if (!selectedPromos.add(promo)) selectedPromos.remove(promo);
    notifyListeners();
  }

  void setSalesRep(String? rep) {
    selectedSalesRep = rep;
    notifyListeners();
  }

  void setStatus(String? status) {
    selectedStatus = status;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    dateStart = start;
    dateEnd = end;
    notifyListeners();
  }

  void clearFilters() {
    selectedPromos.clear();
    selectedSalesRep = null;
    selectedStatus = null;
    dateStart = null;
    dateEnd = null;
    notifyListeners();
  }
}
