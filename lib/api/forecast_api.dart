import '../models/forecast.dart';
import 'api_client.dart';

class ForecastApi {
  final ApiClient client;

  ForecastApi(this.client);

  Future<List<ForecastRow>> generate(ForecastQuery query) async {
    final data = await client.post('api/csrforecast', query.toJson()) as Map<String, dynamic>;
    final rows = data['rows'] as List<dynamic>? ?? [];
    return rows.map((e) => ForecastRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<String>> searchLocations(String term) async {
    final data = await client.get('api/csrforecast/search-locations?term=${Uri.encodeQueryComponent(term)}') as List<dynamic>;
    return data.map((e) => e as String).toList();
  }

  Future<List<String>> searchProducts(String term) async {
    final data = await client.get('api/csrforecast/search-products?term=${Uri.encodeQueryComponent(term)}') as List<dynamic>;
    return data.map((e) => e as String).toList();
  }

  Future<List<String>> searchSuppliers(String term) async {
    final data = await client.get('api/csrforecast/search-suppliers?term=${Uri.encodeQueryComponent(term)}') as List<dynamic>;
    return data.map((e) => e as String).toList();
  }
}
