import 'package:flutter/foundation.dart';
import '../api/sales_pivot_api.dart';
import '../models/sales_pivot.dart';

class SalesPivotProvider extends ChangeNotifier {
  final SalesPivotApi api = SalesPivotApi();

  bool generated = false;
  List<SalesPivotMonth> months = [];
  List<SalesPivotRow> rows = [];
  List<double> grandTotalsByMonth = [];
  double grandTotal = 0;
  List<String> repOptions = [];

  DateTime? startDate;
  DateTime? endDate;
  final Set<String> selectedReps = {};
  bool onlyEveryMonth = false;

  bool isLoading = false;
  String? errorMessage;
  bool _loadedOnce = false;

  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.get(
        startDate: startDate,
        endDate: endDate,
        reps: selectedReps.toList(),
        onlyEveryMonth: onlyEveryMonth,
      );
      generated = result.generated;
      months = result.months;
      rows = result.rows;
      grandTotalsByMonth = result.grandTotalsByMonth;
      grandTotal = result.grandTotal;
      repOptions = result.repOptions;
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

  void setDateRange(DateTime start, DateTime end) {
    startDate = start;
    endDate = end;
    notifyListeners();
  }

  void toggleRep(String rep) {
    if (!selectedReps.add(rep)) selectedReps.remove(rep);
    notifyListeners();
  }

  void setOnlyEveryMonth(bool value) {
    onlyEveryMonth = value;
    notifyListeners();
  }

  void clearFilters() {
    startDate = null;
    endDate = null;
    selectedReps.clear();
    onlyEveryMonth = false;
    notifyListeners();
  }
}
