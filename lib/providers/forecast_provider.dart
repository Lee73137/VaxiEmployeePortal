import 'package:flutter/foundation.dart';
import '../api/forecast_api.dart';
import '../api/api_client.dart';
import '../models/forecast.dart';

class ForecastProvider extends ChangeNotifier {
  final ForecastApi api;

  final ForecastQuery query = ForecastQuery();
  List<ForecastRow> rows = [];
  bool isLoading = false;
  bool generated = false;
  String? errorMessage;

  ForecastProvider(ApiClient client) : api = ForecastApi(client);

  Future<void> generate() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      rows = await api.generate(query);
      generated = true;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
