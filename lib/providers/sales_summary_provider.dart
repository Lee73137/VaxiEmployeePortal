import 'package:flutter/foundation.dart';
import '../api/sales_summary_api.dart';
import '../models/sales_summary.dart';

class SalesSummaryProvider extends ChangeNotifier {
  final SalesSummaryApi api = SalesSummaryApi();

  bool generated = false;
  int year = DateTime.now().year;
  List<int> years = [];
  List<SalesSummaryRow> rows = [];
  List<SalesSummaryYearAmounts> grandTotalsByYear = [];
  List<String> repOptions = [];
  List<String> locationOptions = [];

  final Set<String> selectedReps = {};
  final Set<String> selectedLocations = {};

  bool isLoading = false;
  String? errorMessage;
  bool _loadedOnce = false;

  Future<void> refresh({bool generate = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.get(
        year: year,
        reps: selectedReps.toList(),
        locations: selectedLocations.toList(),
        generated: generate,
      );
      generated = result.generated;
      years = result.years;
      rows = result.rows;
      grandTotalsByYear = result.grandTotalsByYear;
      repOptions = result.repOptions;
      locationOptions = result.locationOptions;
      _loadedOnce = true;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> ensureOptionsLoaded() async {
    if (_loadedOnce) return;
    await refresh(generate: false);
  }

  void setYear(int y) {
    year = y;
    notifyListeners();
  }

  void toggleRep(String rep) {
    if (!selectedReps.add(rep)) selectedReps.remove(rep);
    notifyListeners();
  }

  void toggleLocation(String location) {
    if (!selectedLocations.add(location)) selectedLocations.remove(location);
    notifyListeners();
  }

  void clearFilters() {
    selectedReps.clear();
    selectedLocations.clear();
    notifyListeners();
  }

  double grandTotal() => grandTotalsByYear.fold(0, (sum, y) => sum + y.monthlyAmounts.fold(0.0, (s, a) => s + a));
}
