import '../models/customer.dart';
import 'api_client.dart';

class CustomersApi {
  final ApiClient client;

  CustomersApi(this.client);

  Future<List<Customer>> list({String status = 'active'}) async {
    final data = await client.get('api/csrcustomers?status=$status') as List<dynamic>;
    return data.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Customer> get(int id) async {
    final data = await client.get('api/csrcustomers/$id') as Map<String, dynamic>;
    return Customer.fromJson(data);
  }

  Future<Customer> create(Customer customer) async {
    final data = await client.post('api/csrcustomers', customer.toJson()) as Map<String, dynamic>;
    return Customer.fromJson(data);
  }

  Future<Customer> update(int id, Customer customer) async {
    final data = await client.put('api/csrcustomers/$id', customer.toJson()) as Map<String, dynamic>;
    return Customer.fromJson(data);
  }

  Future<void> delete(int id) async {
    await client.delete('api/csrcustomers/$id');
  }
}
