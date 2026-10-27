import 'package:flutter/foundation.dart';
import '../api/product_sales_api.dart';
import '../models/product_sales.dart';

class ProductSalesProvider extends ChangeNotifier {
  final ProductSalesApi api = ProductSalesApi();

  bool generated = false;
  List<ProductSalesRow> rows = [];
  double totalSales = 0;
  double uncollectedAmount = 0;
  double vaxishAppSales = 0;
  double vaxihubSales = 0;
  List<ProductSalesRow> vaxishAppItemRows = [];
  List<ProductSalesRow> vaxihubItemRows = [];
  List<ProductSalesCustomerRow> vaxishAppCustomerRows = [];
  List<ProductSalesCustomerRow> vaxihubCustomerRows = [];
  bool repFilterLocked = false;
  List<String> repOptions = [];
  List<String> prefixOptions = [];

  DateTime? dateFrom;
  DateTime? dateTo;
  final Set<String> selectedReps = {};
  final Set<String> selectedPrefixes = {};

  bool isLoading = false;
  String? errorMessage;

  Future<void> refresh(String? username, {bool generate = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.get(
        username: username,
        dateFrom: dateFrom,
        dateTo: dateTo,
        reps: selectedReps.toList(),
        prefixes: selectedPrefixes.toList(),
        generated: generate,
      );
      generated = result.generated;
      rows = result.rows;
      totalSales = result.totalSales;
      uncollectedAmount = result.uncollectedAmount;
      vaxishAppSales = result.vaxishAppSales;
      vaxihubSales = result.vaxihubSales;
      vaxishAppItemRows = result.vaxishAppItemRows;
      vaxihubItemRows = result.vaxihubItemRows;
      vaxishAppCustomerRows = result.vaxishAppCustomerRows;
      vaxihubCustomerRows = result.vaxihubCustomerRows;
      repFilterLocked = result.repFilterLocked;
      if (result.repOptions.isNotEmpty) repOptions = result.repOptions;
      if (result.prefixOptions.isNotEmpty) prefixOptions = result.prefixOptions;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  void setDateRange(DateTime start, DateTime end) {
    dateFrom = start;
    dateTo = end;
    notifyListeners();
  }

  void toggleRep(String rep) {
    if (!selectedReps.add(rep)) selectedReps.remove(rep);
    notifyListeners();
  }

  void togglePrefix(String prefix) {
    if (!selectedPrefixes.add(prefix)) selectedPrefixes.remove(prefix);
    notifyListeners();
  }

  void clearFilters() {
    selectedReps.clear();
    selectedPrefixes.clear();
    notifyListeners();
  }
}
