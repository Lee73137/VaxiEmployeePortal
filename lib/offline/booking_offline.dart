import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clinic_booking.dart';

/// Offline support for Clinic Bookings: the downloaded lookup data the New
/// Booking form needs (clinics, items with pricing, reps, promos), the
/// bookings saved on the phone, and the server's item-pricing rules ported
/// so a booking can be priced with no signal. Everything lives in
/// SharedPreferences as JSON.

/// True when [e] means "couldn't reach the server" (no signal, DNS failure,
/// timeout) rather than the server rejecting the request.
bool isOfflineError(Object e) =>
    e is SocketException || e is TimeoutException || e is http.ClientException || e is HandshakeException;

/// Lowercase with spaces, underscores, dashes and other punctuation removed,
/// so "petshield", "pet shield" and "PET_SHIELD" all compare equal.
String normalizeForSearch(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Whether [text] matches what the user typed: ignoring spacing/punctuation,
/// either as one run ("petshield" in "MV_IMMUNO PET SHIELD") or word by word
/// in any order ("shield immuno").
bool searchMatches(String text, String term) {
  final t = normalizeForSearch(term);
  if (t.isEmpty) return true;
  final n = normalizeForSearch(text);
  if (n.contains(t)) return true;
  final words = term.trim().split(RegExp(r'\s+')).map(normalizeForSearch).where((w) => w.isNotEmpty).toList();
  return words.length > 1 && words.every(n.contains);
}

/// Random v4 UUID - a saved booking's clientReference.
String newClientReference() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) => b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

class OfflinePriceTier {
  final int minQty;
  final double? amount;
  final int freeQty;

  OfflinePriceTier({required this.minQty, this.amount, this.freeQty = 0});

  factory OfflinePriceTier.fromJson(Map<String, dynamic> j) => OfflinePriceTier(
        minQty: j['minQty'] as int? ?? 0,
        amount: (j['amount'] as num?)?.toDouble(),
        freeQty: j['freeQty'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'minQty': minQty, 'amount': amount, 'freeQty': freeQty};
}

class OfflineAccessory {
  final String itemCode;
  final int multiplier;

  OfflineAccessory({required this.itemCode, required this.multiplier});

  factory OfflineAccessory.fromJson(Map<String, dynamic> j) =>
      OfflineAccessory(itemCode: j['itemCode'] as String? ?? '', multiplier: j['multiplier'] as int? ?? 0);

  Map<String, dynamic> toJson() => {'itemCode': itemCode, 'multiplier': multiplier};
}

class OfflineItem {
  final String itemCode;
  final double regularPrice;
  final List<OfflinePriceTier> tiers;
  final List<OfflineAccessory> accessories;

  OfflineItem({required this.itemCode, this.regularPrice = 0, this.tiers = const [], this.accessories = const []});

  factory OfflineItem.fromJson(Map<String, dynamic> j) => OfflineItem(
        itemCode: j['itemCode'] as String? ?? '',
        regularPrice: (j['regularPrice'] as num?)?.toDouble() ?? 0,
        tiers: (j['tiers'] as List<dynamic>? ?? []).map((e) => OfflinePriceTier.fromJson(e as Map<String, dynamic>)).toList(),
        accessories: (j['accessories'] as List<dynamic>? ?? []).map((e) => OfflineAccessory.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'itemCode': itemCode,
        'regularPrice': regularPrice,
        'tiers': tiers.map((t) => t.toJson()).toList(),
        'accessories': accessories.map((a) => a.toJson()).toList(),
      };
}

/// Same result as the server's item-preview for [qty] of [item]: deal tiers
/// (free-quantity tiers, largest first, in whole multiples), leftover priced
/// at the largest qualifying tier or the regular price, then the free
/// accessories. Ported from vaximobileapi's ComputeTierBreakdown /
/// ComputeAccessories (themselves copies of vaxiCSR's BookingService).
List<BookingLineInput> priceItemOffline(OfflineItem item, int qty) {
  if (qty <= 0) return const [];
  final tiers = item.tiers.where((t) => t.minQty > 0).toList();
  final dealTiers = tiers.where((t) => t.freeQty > 0).toList()..sort((a, b) => b.minQty.compareTo(a.minQty));

  double priceFor(int q) {
    OfflinePriceTier? best;
    for (final t in tiers) {
      if (t.minQty <= q && (best == null || t.minQty > best.minQty)) best = t;
    }
    return best != null ? (best.amount ?? 0) : item.regularPrice;
  }

  var remaining = qty;
  final lines = <BookingLineInput>[];
  for (final t in dealTiers) {
    if (remaining < t.minQty) continue;
    final multiples = remaining ~/ t.minQty;
    final used = multiples * t.minQty;
    final free = multiples * t.freeQty;
    lines.add(BookingLineInput(itemCode: item.itemCode, quantity: used, unitPrice: t.amount ?? priceFor(used), isFree: false));
    if (free > 0) lines.add(BookingLineInput(itemCode: item.itemCode, quantity: free, unitPrice: 0, isFree: true));
    remaining -= used;
    if (remaining <= 0) break;
  }
  if (remaining > 0) {
    lines.add(BookingLineInput(itemCode: item.itemCode, quantity: remaining, unitPrice: priceFor(remaining), isFree: false));
  }
  for (final a in item.accessories) {
    if (a.multiplier == 0) continue;
    final accQty = a.multiplier > 0 ? qty * a.multiplier : qty ~/ a.multiplier.abs();
    if (accQty > 0) lines.add(BookingLineInput(itemCode: a.itemCode, quantity: accQty, unitPrice: 0, isFree: true));
  }
  return lines;
}

/// Everything the New Booking form looks up, downloaded while online.
class OfflinePack {
  final DateTime generatedAt;
  final List<BookingClinicOption> clinics;
  final List<OfflineItem> items;
  final List<BookingRepOption> reps;
  final List<PromoOption> promos;

  OfflinePack({required this.generatedAt, this.clinics = const [], this.items = const [], this.reps = const [], this.promos = const []});

  factory OfflinePack.fromJson(Map<String, dynamic> j) => OfflinePack(
        generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? '') ?? DateTime.now(),
        clinics: (j['clinics'] as List<dynamic>? ?? []).map((e) => BookingClinicOption.fromJson(e as Map<String, dynamic>)).toList(),
        items: (j['items'] as List<dynamic>? ?? []).map((e) => OfflineItem.fromJson(e as Map<String, dynamic>)).toList(),
        reps: (j['reps'] as List<dynamic>? ?? []).map((e) => BookingRepOption.fromJson(e as Map<String, dynamic>)).toList(),
        promos: (j['promos'] as List<dynamic>? ?? []).map((e) => PromoOption.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'clinics': clinics.map((c) => c.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'reps': reps.map((r) => r.toJson()).toList(),
        'promos': promos.map((p) => p.toJson()).toList(),
      };

  OfflineItem? item(String code) {
    for (final i in items) {
      if (i.itemCode == code) return i;
    }
    return null;
  }

  List<BookingClinicOption> searchClinics(String term) {
    if (normalizeForSearch(term).length < 2) return const [];
    return clinics.where((c) => searchMatches(c.name, term)).take(10).toList();
  }

  List<String> searchItems(String term) =>
      items.map((i) => i.itemCode).where((c) => searchMatches(c, term)).toList();
}

/// One ordered item in a booking - what the user typed (code + quantity)
/// plus the priced lines it expands into (tier split, free goods).
class DraftItem {
  final String itemCode;
  final int quantity;
  final List<BookingLineInput> lines;

  /// Priced from the phone's offline pack rather than the server.
  final bool pricedOffline;

  DraftItem({required this.itemCode, required this.quantity, required this.lines, this.pricedOffline = false});

  double get total => lines.fold<double>(0, (s, l) => s + l.total);

  factory DraftItem.fromJson(Map<String, dynamic> j) => DraftItem(
        itemCode: j['itemCode'] as String? ?? '',
        quantity: j['quantity'] as int? ?? 0,
        lines: (j['lines'] as List<dynamic>? ?? []).map((e) => BookingLineInput.fromJson(e as Map<String, dynamic>)).toList(),
        pricedOffline: j['pricedOffline'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'itemCode': itemCode,
        'quantity': quantity,
        'lines': lines.map((l) => l.toJson()).toList(),
        'pricedOffline': pricedOffline,
      };
}

/// A booking saved on the phone, not yet submitted. [id] doubles as the
/// clientReference sent at submit, so a retry can never duplicate it.
class BookingDraft {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BookingClinicOption? clinic;
  final int? repId;
  final String? repName;
  final int promoId;
  final String? promoCode;
  final String? deliveryType;
  final String? remarks;
  final List<DraftItem> items;

  /// Why the last submit attempt failed, shown on the saved booking.
  final String? lastError;

  /// The user pressed Submit but there was no signal - the app sends it by
  /// itself once it can. False for a booking they chose to keep on the
  /// phone ("Save to phone"); that one waits for them to tap Submit.
  final bool queued;

  BookingDraft({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.clinic,
    this.repId,
    this.repName,
    this.promoId = 0,
    this.promoCode,
    this.deliveryType,
    this.remarks,
    this.items = const [],
    this.lastError,
    this.queued = false,
  });

  double get total => items.fold<double>(0, (s, i) => s + i.total);

  List<BookingLineInput> get lines => [for (final i in items) ...i.lines];

  BookingDraft copyWith({String? lastError, bool clearError = false, List<DraftItem>? items, DateTime? updatedAt, bool? queued}) =>
      BookingDraft(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        clinic: clinic,
        repId: repId,
        repName: repName,
        promoId: promoId,
        promoCode: promoCode,
        deliveryType: deliveryType,
        remarks: remarks,
        items: items ?? this.items,
        lastError: clearError ? null : (lastError ?? this.lastError),
        queued: queued ?? this.queued,
      );

  factory BookingDraft.fromJson(Map<String, dynamic> j) => BookingDraft(
        id: j['id'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
        clinic: j['clinic'] == null ? null : BookingClinicOption.fromJson(j['clinic'] as Map<String, dynamic>),
        repId: j['repId'] as int?,
        repName: j['repName'] as String?,
        promoId: j['promoId'] as int? ?? 0,
        promoCode: j['promoCode'] as String?,
        deliveryType: j['deliveryType'] as String?,
        remarks: j['remarks'] as String?,
        items: (j['items'] as List<dynamic>? ?? []).map((e) => DraftItem.fromJson(e as Map<String, dynamic>)).toList(),
        lastError: j['lastError'] as String?,
        queued: j['queued'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'clinic': clinic?.toJson(),
        'repId': repId,
        'repName': repName,
        'promoId': promoId,
        'promoCode': promoCode,
        'deliveryType': deliveryType,
        'remarks': remarks,
        'items': items.map((i) => i.toJson()).toList(),
        'lastError': lastError,
        'queued': queued,
      };
}

/// SharedPreferences persistence, keyed per user so two accounts on one
/// phone never see each other's saved bookings.
class BookingOfflineStore {
  static String _packKey(String user) => 'offline_booking_pack::${user.toLowerCase()}';
  static String _draftsKey(String user) => 'offline_booking_drafts::${user.toLowerCase()}';

  static Future<OfflinePack?> loadPack(String user) async {
    final raw = (await SharedPreferences.getInstance()).getString(_packKey(user));
    if (raw == null) return null;
    try {
      return OfflinePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePack(String user, OfflinePack pack) async =>
      (await SharedPreferences.getInstance()).setString(_packKey(user), jsonEncode(pack.toJson()));

  static Future<List<BookingDraft>> loadDrafts(String user) async {
    final raw = (await SharedPreferences.getInstance()).getString(_draftsKey(user));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((e) => BookingDraft.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDrafts(String user, List<BookingDraft> drafts) async =>
      (await SharedPreferences.getInstance()).setString(_draftsKey(user), jsonEncode(drafts.map((d) => d.toJson()).toList()));
}
