import '../models/clinic_history.dart';
import 'api_client.dart';

class ClinicHistoryApi {
  final ApiClient client;

  ClinicHistoryApi(this.client);

  Future<List<ClinicHistoryListItem>> list() async {
    final data = await client.get('api/csrclinichistory') as List<dynamic>;
    return data.map((e) => ClinicHistoryListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClinicHistoryDetail> get(int clinicId) async {
    final data = await client.get('api/csrclinichistory/$clinicId') as Map<String, dynamic>;
    return ClinicHistoryDetail.fromJson(data);
  }
}
