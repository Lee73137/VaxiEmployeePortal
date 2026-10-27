class PromoInvoice {
  final int qbExtractedId;
  final String? refNumber;
  final String? customerName;
  final DateTime? txnDate;
  final String? salesRep;
  final String? promo;
  final String? status;
  final double amount;

  PromoInvoice({
    required this.qbExtractedId,
    this.refNumber,
    this.customerName,
    this.txnDate,
    this.salesRep,
    this.promo,
    this.status,
    this.amount = 0,
  });

  factory PromoInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return PromoInvoice(
      qbExtractedId: json['qbExtractedId'] as int,
      refNumber: (json['refNumber'] as String?)?.trim(),
      customerName: json['customerName'] as String?,
      txnDate: parseDate(json['txnDate']),
      salesRep: (json['salesRep'] as String?)?.trim(),
      promo: json['promo'] as String?,
      status: json['status'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PromoBookingLine {
  final int bookingId;
  final String? sono;
  final DateTime? dateOrder;
  final String? clinicName;
  final String? repName;
  final String? promoCode;
  final String? itemCode;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  PromoBookingLine({
    required this.bookingId,
    this.sono,
    this.dateOrder,
    this.clinicName,
    this.repName,
    this.promoCode,
    this.itemCode,
    this.quantity = 0,
    this.unitPrice = 0,
    this.lineTotal = 0,
  });

  factory PromoBookingLine.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return PromoBookingLine(
      bookingId: json['bookingId'] as int,
      sono: json['sono'] as String?,
      dateOrder: parseDate(json['dateOrder']),
      clinicName: json['clinicName'] as String?,
      repName: json['repName'] as String?,
      promoCode: json['promoCode'] as String?,
      itemCode: json['itemCode'] as String?,
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PromoInvoicesResponse {
  final bool hasAnyFilter;
  final List<PromoInvoice> invoices;
  final double totalAmount;
  final List<PromoBookingLine> bookingItems;
  final double bookingTotalAmount;
  final List<String> promoOptions;
  final List<String> salesRepOptions;
  final List<String> statusOptions;

  PromoInvoicesResponse({
    this.hasAnyFilter = false,
    this.invoices = const [],
    this.totalAmount = 0,
    this.bookingItems = const [],
    this.bookingTotalAmount = 0,
    this.promoOptions = const [],
    this.salesRepOptions = const [],
    this.statusOptions = const [],
  });

  factory PromoInvoicesResponse.fromJson(Map<String, dynamic> json) => PromoInvoicesResponse(
        hasAnyFilter: json['hasAnyFilter'] as bool? ?? false,
        invoices: (json['invoices'] as List<dynamic>? ?? []).map((e) => PromoInvoice.fromJson(e as Map<String, dynamic>)).toList(),
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        bookingItems: (json['bookingItems'] as List<dynamic>? ?? []).map((e) => PromoBookingLine.fromJson(e as Map<String, dynamic>)).toList(),
        bookingTotalAmount: (json['bookingTotalAmount'] as num?)?.toDouble() ?? 0,
        promoOptions: (json['promoOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        salesRepOptions: (json['salesRepOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        statusOptions: (json['statusOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}
