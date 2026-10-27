import 'package:flutter_test/flutter_test.dart';
import 'package:vaxicsr_mobile/models/clinic_booking.dart';
import 'package:vaxicsr_mobile/offline/booking_offline.dart';

// Expected values are the live server's own item-preview answers for the
// same items (captured from vaximobileapi), so offline pricing can't drift
// from what the server would charge.
List<String> _fmt(List<BookingLineInput> lines) =>
    lines.map((l) => '${l.itemCode}|${l.quantity}|${l.unitPrice}|${l.isFree}').toList();

void main() {
  final biocan = OfflineItem(
    itemCode: 'BC_BIOCAN DHPPI+L 5N1',
    regularPrice: 320,
    tiers: [
      OfflinePriceTier(minQty: 10, amount: 320),
      OfflinePriceTier(minQty: 50, amount: 309),
      OfflinePriceTier(minQty: 100, amount: 307),
    ],
    accessories: [OfflineAccessory(itemCode: 'SYRINGE 3ML', multiplier: 1)],
  );
  final aluspray = OfflineItem(
    itemCode: 'AG_ALUSPRAY',
    regularPrice: 818,
    tiers: [OfflinePriceTier(minQty: 10, amount: 818, freeQty: 1)],
  );

  test('volume tiers + free accessory match the server', () {
    expect(_fmt(priceItemOffline(biocan, 7)), ['BC_BIOCAN DHPPI+L 5N1|7|320.0|false', 'SYRINGE 3ML|7|0.0|true']);
    expect(_fmt(priceItemOffline(biocan, 55)), ['BC_BIOCAN DHPPI+L 5N1|55|309.0|false', 'SYRINGE 3ML|55|0.0|true']);
    expect(_fmt(priceItemOffline(biocan, 130)), ['BC_BIOCAN DHPPI+L 5N1|130|307.0|false', 'SYRINGE 3ML|130|0.0|true']);
  });

  test('buy-10-get-1 deal tier matches the server', () {
    expect(_fmt(priceItemOffline(aluspray, 9)), ['AG_ALUSPRAY|9|818.0|false']);
    expect(_fmt(priceItemOffline(aluspray, 25)), [
      'AG_ALUSPRAY|20|818.0|false',
      'AG_ALUSPRAY|2|0.0|true',
      'AG_ALUSPRAY|5|818.0|false',
    ]);
  });

  test('saved booking survives a JSON round trip', () {
    final d = BookingDraft(
      id: newClientReference(),
      createdAt: DateTime(2026, 10, 26, 9),
      updatedAt: DateTime(2026, 10, 26, 10),
      clinic: BookingClinicOption(clinicId: 7317, name: '3 KINGS VET CLINIC', areaName: 'Cavite - Lower'),
      repId: 1,
      repName: 'Axl',
      deliveryType: 'DELIVERY',
      items: [DraftItem(itemCode: aluspray.itemCode, quantity: 25, lines: priceItemOffline(aluspray, 25), pricedOffline: true)],
    );
    final back = BookingDraft.fromJson(d.toJson());
    expect(back.id, d.id);
    expect(back.clinic!.name, '3 KINGS VET CLINIC');
    expect(back.total, 25 * 818.0); // 20 + 5 paid, plus 2 free on top
    expect(back.items.single.pricedOffline, isTrue);
    expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(d.id), isTrue);
  });

  test('item search ignores spacing and word order', () {
    const name = 'MV_IMMUNO PET SHIELD 60TAB';
    expect(searchMatches(name, 'petshield'), isTrue);
    expect(searchMatches(name, 'pet shield'), isTrue);
    expect(searchMatches(name, 'PET_SHIELD'), isTrue);
    expect(searchMatches(name, 'shield immuno'), isTrue);
    expect(searchMatches(name, ''), isTrue);
    expect(searchMatches(name, 'vaxilaner'), isFalse);
    expect(searchMatches('VPI_HEMASHIELD 120ml', 'pet shield'), isFalse);
  });
}
