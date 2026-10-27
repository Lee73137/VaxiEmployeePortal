import 'package:flutter/foundation.dart';
import '../api/clinic_bookings_api.dart';
import '../models/clinic_booking.dart';
import '../offline/booking_offline.dart';

enum DraftSubmitStatus { submitted, priceChanged, offline, failed }

class DraftSubmitOutcome {
  final DraftSubmitStatus status;
  final CreateBookingResponse? response;

  /// priceChanged only: the booking re-priced at today's server prices,
  /// for the user to confirm before it's sent.
  final BookingDraft? repriced;
  final String? message;

  const DraftSubmitOutcome(this.status, {this.response, this.repriced, this.message});
}

/// Bookings saved on this phone (not yet submitted) plus the downloaded
/// offline pack. Saved bookings can be edited, deleted or submitted any time;
/// once one submits it's removed from the phone.
class BookingDraftsProvider extends ChangeNotifier {
  final ClinicBookingsApi api;

  BookingDraftsProvider(this.api);

  String? _user;
  List<BookingDraft> drafts = [];
  OfflinePack? pack;
  bool refreshingPack = false;
  String? packError;
  final Set<String> submitting = {};

  /// Loads this user's saved bookings and offline pack from the phone.
  Future<void> load(String? username) async {
    final user = (username ?? '').trim();
    if (user.isEmpty || user == _user) return;
    _user = user;
    drafts = await BookingOfflineStore.loadDrafts(user);
    pack = await BookingOfflineStore.loadPack(user);
    notifyListeners();
  }

  /// Re-downloads the offline pack. Quietly keeps the old one when offline.
  Future<bool> refreshPack(String? username) async {
    await load(username);
    final user = _user;
    if (user == null || refreshingPack) return false;
    refreshingPack = true;
    packError = null;
    notifyListeners();
    try {
      final fresh = await api.offlinePack(username: user);
      pack = fresh;
      await BookingOfflineStore.savePack(user, fresh);
      return true;
    } catch (e) {
      packError = isOfflineError(e) ? 'No connection - using the copy saved on ${_fmt(pack?.generatedAt)}.' : '$e';
      return false;
    } finally {
      refreshingPack = false;
      notifyListeners();
    }
  }

  /// Refreshes the pack when it's missing or older than [maxAge].
  Future<void> ensureFreshPack(String? username, {Duration maxAge = const Duration(hours: 12)}) async {
    await load(username);
    final p = pack;
    if (p == null || DateTime.now().difference(p.generatedAt) > maxAge) {
      await refreshPack(username);
    }
  }

  Future<void> saveDraft(BookingDraft draft) async {
    final user = _user;
    if (user == null) return;
    final i = drafts.indexWhere((d) => d.id == draft.id);
    if (i >= 0) {
      drafts[i] = draft;
    } else {
      drafts.insert(0, draft);
    }
    await BookingOfflineStore.saveDrafts(user, drafts);
    notifyListeners();
  }

  Future<void> deleteDraft(String id) async {
    final user = _user;
    if (user == null) return;
    drafts.removeWhere((d) => d.id == id);
    await BookingOfflineStore.saveDrafts(user, drafts);
    notifyListeners();
  }

  /// Submits a saved booking. Unless [confirmedPrices], it's first re-priced
  /// through the server - if today's total differs from the saved one,
  /// nothing is sent and the re-priced booking comes back for the user to
  /// confirm. The booking's id goes along as clientReference, so a retry
  /// after a dropped connection can't create a second booking.
  Future<DraftSubmitOutcome> submit(BookingDraft draft, {required String? username, bool confirmedPrices = false}) async {
    if (submitting.contains(draft.id)) return const DraftSubmitOutcome(DraftSubmitStatus.failed, message: 'Already submitting.');
    submitting.add(draft.id);
    notifyListeners();
    try {
      var toSend = draft;
      if (!confirmedPrices) {
        final repricedItems = <DraftItem>[];
        for (final item in draft.items) {
          final lines = await api.itemPreview(item.itemCode, item.quantity);
          repricedItems.add(DraftItem(itemCode: item.itemCode, quantity: item.quantity, lines: lines));
        }
        toSend = draft.copyWith(items: repricedItems);
        if ((toSend.total - draft.total).abs() > 0.009) {
          await saveDraft(toSend.copyWith(updatedAt: DateTime.now()));
          return DraftSubmitOutcome(DraftSubmitStatus.priceChanged, repriced: toSend);
        }
      }

      final response = await api.create(CreateBookingRequest(
        username: username,
        clinicId: toSend.clinic!.clinicId,
        repId: toSend.repId!,
        promoId: toSend.promoId,
        deliveryType: toSend.deliveryType!,
        remarks: toSend.remarks,
        lines: toSend.lines,
        clientReference: toSend.id,
      ));
      await deleteDraft(draft.id);
      return DraftSubmitOutcome(DraftSubmitStatus.submitted, response: response);
    } catch (e) {
      final offline = isOfflineError(e);
      final message = offline ? 'No signal - will send automatically when back online.' : '$e';
      if (drafts.any((d) => d.id == draft.id)) {
        // No signal: the user wanted it sent, so queue it for automatic
        // sending. A server-side rejection stays for the user to fix.
        await saveDraft(drafts.firstWhere((d) => d.id == draft.id).copyWith(lastError: message, queued: offline ? true : null));
      }
      return DraftSubmitOutcome(offline ? DraftSubmitStatus.offline : DraftSubmitStatus.failed, message: message);
    } finally {
      submitting.remove(draft.id);
      notifyListeners();
    }
  }

  /// What still has to be filled in before [d] can be submitted, or null.
  static String? problemOf(BookingDraft d) {
    if (d.clinic == null || d.clinic!.clinicId <= 0) return 'Needs a clinic';
    if (d.repId == null) return 'Needs a sales rep';
    if (d.deliveryType == null) return 'Needs a delivery type';
    if (d.items.isEmpty) return 'Needs items';
    return null;
  }

  bool syncing = false;

  /// Sends every queued booking (Submit was pressed with no signal), oldest
  /// first - run automatically whenever the app starts, comes back to the
  /// foreground, and every minute while open. Stops at the first "no
  /// connection". Bookings kept with "Save to phone" are left alone, and one
  /// whose prices changed since it was saved is taken out of the queue for
  /// the user to open and confirm the new total. Returns how many were sent.
  Future<int> syncPending(String? username) async {
    await load(username);
    if (syncing || drafts.isEmpty) return 0;
    syncing = true;
    var sent = 0;
    try {
      final waiting = drafts.where((d) => d.queued && problemOf(d) == null && !submitting.contains(d.id)).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final d in waiting) {
        final outcome = await submit(d, username: username);
        if (outcome.status == DraftSubmitStatus.submitted) {
          sent++;
        } else if (outcome.status == DraftSubmitStatus.priceChanged) {
          await saveDraft(outcome.repriced!.copyWith(
            lastError: 'Prices changed - open it and tap Submit to confirm the new total.',
            queued: false,
          ));
        } else if (outcome.status == DraftSubmitStatus.offline) {
          break;
        }
      }
    } finally {
      syncing = false;
      notifyListeners();
    }
    return sent;
  }

  static String _fmt(DateTime? d) {
    if (d == null) return 'never';
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${m[d.month - 1]} ${d.day}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String formatWhen(DateTime? d) => _fmt(d);
}
