import '../models/clinic.dart';
import 'api_client.dart';

class ClinicsApi {
  final ApiClient client;

  ClinicsApi(this.client);

  Future<List<Clinic>> list({String status = 'active'}) async {
    final data = await client.get('api/csrclinics?status=$status') as List<dynamic>;
    return data.map((e) => Clinic.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Clinic> get(int id) async {
    final data = await client.get('api/csrclinics/$id') as Map<String, dynamic>;
    return Clinic.fromJson(data);
  }

  Future<List<ClinicArea>> areas() async {
    final data = await client.get('api/csrclinics/areas') as List<dynamic>;
    return data.map((e) => ClinicArea.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ClinicSalesRep>> salesReps() async {
    final data = await client.get('api/csrclinics/salesreps') as List<dynamic>;
    return data.map((e) => ClinicSalesRep.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Clinic> create(Clinic clinic) async {
    final data = await client.post('api/csrclinics', clinic.toSaveJson()) as Map<String, dynamic>;
    return Clinic.fromJson(data);
  }

  Future<Clinic> update(int id, Clinic clinic) async {
    final data = await client.put('api/csrclinics/$id', clinic.toSaveJson()) as Map<String, dynamic>;
    return Clinic.fromJson(data);
  }

  Future<void> setActive(int id, bool active) async {
    await client.put('api/csrclinics/$id/active', {'active': active});
  }

  Future<void> delete(int id) async {
    await client.delete('api/csrclinics/$id');
  }
}
