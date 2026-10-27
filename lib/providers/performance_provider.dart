import 'package:flutter/foundation.dart';
import '../api/performance_api.dart';
import '../models/performance.dart';

class PerformanceProvider extends ChangeNotifier {
  final PerformanceApi api = PerformanceApi();

  bool generated = false;
  int year = DateTime.now().year;
  List<PerformanceRow> rows = [];
  double totalSales = 0;
  int totalActualVisits = 0;
  int totalVirtualVisits = 0;
  int clinicCount = 0;
  double coveragePercent = 0;
  List<double> monthlySalesTotals = [];
  Map<String, List<double>> monthlySalesByRep = {};
  Map<String, double> targetMonthByRep = {};
  bool repFilterLocked = false;
  List<String> repOptions = [];
  List<String> locationOptions = [];
  List<int> yearOptions = [];

  final Set<String> selectedReps = {};
  final Set<String> selectedLocations = {};

  bool isLoading = false;
  String? errorMessage;
  bool _loadedOnce = false;

  Future<void> refresh(String? username, {bool generate = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.get(
        username: username,
        year: year,
        reps: selectedReps.toList(),
        locations: selectedLocations.toList(),
        generated: generate,
      );
      generated = result.generated;
      year = result.year;
      rows = result.rows;
      totalSales = result.totalSales;
      totalActualVisits = result.totalActualVisits;
      totalVirtualVisits = result.totalVirtualVisits;
      clinicCount = result.clinicCount;
      coveragePercent = result.coveragePercent;
      monthlySalesTotals = result.monthlySalesTotals;
      monthlySalesByRep = result.monthlySalesByRep;
      targetMonthByRep = result.targetMonthByRep;
      repFilterLocked = result.repFilterLocked;
      repOptions = result.repOptions;
      locationOptions = result.locationOptions;
      yearOptions = result.yearOptions;
      _loadedOnce = true;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> ensureOptionsLoaded(String? username) async {
    if (_loadedOnce) return;
    await refresh(username, generate: false);
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
}
