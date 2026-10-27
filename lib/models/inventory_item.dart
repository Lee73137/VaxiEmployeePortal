class InventoryItem {
  final String? itemcode;
  final String? uom;
  final String? lotnumbers;
  final int quantityOnHand;
  final int pending;
  final int forDr;
  final int invoice;
  final int adjustment;
  final int returned;
  final int available;
  final String? statusLabel;

  InventoryItem({
    this.itemcode,
    this.uom,
    this.lotnumbers,
    required this.quantityOnHand,
    required this.pending,
    required this.forDr,
    required this.invoice,
    required this.adjustment,
    required this.returned,
    required this.available,
    this.statusLabel,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      itemcode: json['itemcode'] as String?,
      uom: (json['uom'] as String?)?.trim(),
      lotnumbers: json['lotnumbers'] as String?,
      quantityOnHand: json['quantityOnHand'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      forDr: json['forDr'] as int? ?? 0,
      invoice: json['invoice'] as int? ?? 0,
      adjustment: json['adjustment'] as int? ?? 0,
      returned: json['returned'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      statusLabel: json['statusLabel'] as String?,
    );
  }

  String get displayCode => (itemcode ?? '').trim();
}

class InventoryListResponse {
  final DateTime? lastSyncedAtPh;
  final List<InventoryItem> items;

  InventoryListResponse({required this.lastSyncedAtPh, required this.items});

  factory InventoryListResponse.fromJson(Map<String, dynamic> json) {
    return InventoryListResponse(
      lastSyncedAtPh: json['lastSyncedAtPh'] == null ? null : DateTime.tryParse(json['lastSyncedAtPh'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PendingBookingEntry {
  final int bookingid;
  final DateTime? dateorder;
  final String? sono;
  final String? clinicname;
  final String? repname;
  final String? areaname;
  final int? quantity;
  final int? preparedcount;
  final String? unitofmeasure;

  PendingBookingEntry({
    required this.bookingid,
    this.dateorder,
    this.sono,
    this.clinicname,
    this.repname,
    this.areaname,
    this.quantity,
    this.preparedcount,
    this.unitofmeasure,
  });

  factory PendingBookingEntry.fromJson(Map<String, dynamic> json) {
    return PendingBookingEntry(
      bookingid: json['bookingid'] as int,
      dateorder: json['dateorder'] == null ? null : DateTime.tryParse(json['dateorder'] as String),
      sono: json['sono'] as String?,
      clinicname: json['clinicname'] as String?,
      repname: json['repname'] as String?,
      areaname: (json['areaname'] as String?)?.trim(),
      quantity: json['quantity'] as int?,
      preparedcount: json['preparedcount'] as int?,
      unitofmeasure: (json['unitofmeasure'] as String?)?.trim(),
    );
  }
}

class PendingBookingsResponse {
  final String itemCode;
  final bool isForDr;
  final List<PendingBookingEntry> entries;
  final int totalQuantity;
  final int totalPrepared;
  final int totalRemaining;

  PendingBookingsResponse({
    required this.itemCode,
    required this.isForDr,
    required this.entries,
    required this.totalQuantity,
    required this.totalPrepared,
    required this.totalRemaining,
  });

  factory PendingBookingsResponse.fromJson(Map<String, dynamic> json) {
    return PendingBookingsResponse(
      itemCode: json['itemCode'] as String? ?? '',
      isForDr: json['isForDr'] as bool? ?? false,
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => PendingBookingEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalQuantity: json['totalQuantity'] as int? ?? 0,
      totalPrepared: json['totalPrepared'] as int? ?? 0,
      totalRemaining: json['totalRemaining'] as int? ?? 0,
    );
  }
}

class InventoryAuditEntry {
  final DateTime changedat;
  final String? action;
  final int? oldQuantityOnHand;
  final int newQuantityOnHand;
  final String? oldUom;
  final String? newUom;
  final String? oldLotnumbers;
  final String? newLotnumbers;
  final String? changedby;

  InventoryAuditEntry({
    required this.changedat,
    this.action,
    this.oldQuantityOnHand,
    required this.newQuantityOnHand,
    this.oldUom,
    this.newUom,
    this.oldLotnumbers,
    this.newLotnumbers,
    this.changedby,
  });

  factory InventoryAuditEntry.fromJson(Map<String, dynamic> json) {
    return InventoryAuditEntry(
      changedat: DateTime.tryParse(json['changedat'] as String? ?? '') ?? DateTime.now(),
      action: json['action'] as String?,
      oldQuantityOnHand: json['old_quantityonhand'] as int?,
      newQuantityOnHand: json['new_quantityonhand'] as int? ?? 0,
      oldUom: (json['old_uom'] as String?)?.trim(),
      newUom: (json['new_uom'] as String?)?.trim(),
      oldLotnumbers: json['old_lotnumbers'] as String?,
      newLotnumbers: json['new_lotnumbers'] as String?,
      changedby: json['changedby'] as String?,
    );
  }
}
