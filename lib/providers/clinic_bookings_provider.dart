import 'package:flutter/foundation.dart';
import '../api/clinic_bookings_api.dart';
import '../models/clinic_booking.dart';

class ClinicBookingsProvider extends ChangeNotifier {
  final ClinicBookingsApi api = ClinicBookingsApi();

  List<BookingOrder> items = [];
  bool repFilterLocked = false;
  DateTime dateFrom = DateTime.now();
  DateTime dateTo = DateTime.now();
  bool isLoading = false;
  String? errorMessage;

  Future<void> refresh(String? username) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await api.list(username: username, dateFrom: dateFrom, dateTo: dateTo);
      items = result.items;
      repFilterLocked = result.repFilterLocked;
    } catch (e) {
      errorMessage = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setDateRange(DateTime from, DateTime to, String? username) async {
    dateFrom = from;
    dateTo = to;
    await refresh(username);
  }
}
