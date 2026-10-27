class BookingLine {
  final int bookingId;
  final String itemCode;
  final int quantity;
  final double unitPrice;
  final double unitTotal;
  final String unitOfMeasure;

  BookingLine({
    required this.bookingId,
    required this.itemCode,
    required this.quantity,
    required this.unitPrice,
    required this.unitTotal,
    required this.unitOfMeasure,
  });

  factory BookingLine.fromJson(Map<String, dynamic> json) => BookingLine(
        bookingId: json['bookingId'] as int,
        itemCode: json['itemCode'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        unitTotal: (json['unitTotal'] as num?)?.toDouble() ?? 0,
        unitOfMeasure: json['unitOfMeasure'] as String? ?? '',
      );
}

class BookingOrder {
  final String referenceNo;
  final String soNo;
  final String drNo;
  final String clinicName;
  final String clinicPhone;
  final String repName;
  final String areaName;
  final DateTime? dateOrder;
  final int status;
  final String statusName;
  final String encodedBy;
  final String promoCode;
  final String deliveryType;
  final String remarks;
  final double totalOverdue;
  final double totalNotDue;
  final int maxDaysOverdue;
  final bool hasPriceCorrection;
  final List<BookingLine> lines;

  BookingOrder({
    required this.referenceNo,
    required this.soNo,
    required this.drNo,
    required this.clinicName,
    required this.clinicPhone,
    required this.repName,
    required this.areaName,
    this.dateOrder,
    required this.status,
    required this.statusName,
    required this.encodedBy,
    required this.promoCode,
    required this.deliveryType,
    required this.remarks,
    this.totalOverdue = 0,
    this.totalNotDue = 0,
    this.maxDaysOverdue = 0,
    this.hasPriceCorrection = false,
    this.lines = const [],
  });

  double get grandTotal => lines.fold(0.0, (sum, l) => sum + l.unitTotal);
  int get itemCount => lines.length;

  factory BookingOrder.fromJson(Map<String, dynamic> json) => BookingOrder(
        referenceNo: json['referenceNo'] as String? ?? '',
        soNo: json['soNo'] as String? ?? '',
        drNo: json['drNo'] as String? ?? '',
        clinicName: json['clinicName'] as String? ?? '',
        clinicPhone: json['clinicPhone'] as String? ?? '',
        repName: json['repName'] as String? ?? '',
        areaName: json['areaName'] as String? ?? '',
        dateOrder: json['dateOrder'] == null ? null : DateTime.tryParse(json['dateOrder'] as String),
        status: json['status'] as int? ?? 0,
        statusName: json['statusName'] as String? ?? '',
        encodedBy: json['encodedBy'] as String? ?? '',
        promoCode: json['promoCode'] as String? ?? '',
        deliveryType: json['deliveryType'] as String? ?? '',
        remarks: json['remarks'] as String? ?? '',
        totalOverdue: (json['totalOverdue'] as num?)?.toDouble() ?? 0,
        totalNotDue: (json['totalNotDue'] as num?)?.toDouble() ?? 0,
        maxDaysOverdue: json['maxDaysOverdue'] as int? ?? 0,
        hasPriceCorrection: json['hasPriceCorrection'] as bool? ?? false,
        lines: (json['lines'] as List<dynamic>? ?? []).map((e) => BookingLine.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class BookingListResponse {
  final List<BookingOrder> items;
  final bool repFilterLocked;

  BookingListResponse({required this.items, required this.repFilterLocked});

  factory BookingListResponse.fromJson(Map<String, dynamic> json) => BookingListResponse(
        items: (json['items'] as List<dynamic>? ?? []).map((e) => BookingOrder.fromJson(e as Map<String, dynamic>)).toList(),
        repFilterLocked: json['repFilterLocked'] as bool? ?? false,
      );
}

class PriceCorrection {
  final String itemCode;
  final String itemName;
  final int submittedQuantity;
  final double submittedUnitPrice;
  final double correctedUnitPrice;
  final int submittedFreeQuantity;
  final int correctedFreeQuantity;
  final String? reason;
  final String? source;
  final DateTime correctedAt;

  PriceCorrection({
    required this.itemCode,
    required this.itemName,
    required this.submittedQuantity,
    required this.submittedUnitPrice,
    required this.correctedUnitPrice,
    required this.submittedFreeQuantity,
    required this.correctedFreeQuantity,
    this.reason,
    this.source,
    required this.correctedAt,
  });

  factory PriceCorrection.fromJson(Map<String, dynamic> json) => PriceCorrection(
        itemCode: json['itemCode'] as String? ?? '',
        itemName: json['itemName'] as String? ?? '',
        submittedQuantity: json['submittedQuantity'] as int? ?? 0,
        submittedUnitPrice: (json['submittedUnitPrice'] as num?)?.toDouble() ?? 0,
        correctedUnitPrice: (json['correctedUnitPrice'] as num?)?.toDouble() ?? 0,
        submittedFreeQuantity: json['submittedFreeQuantity'] as int? ?? 0,
        correctedFreeQuantity: json['correctedFreeQuantity'] as int? ?? 0,
        reason: json['reason'] as String?,
        source: json['source'] as String?,
        correctedAt: DateTime.tryParse(json['correctedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class BookingClinicOption {
  final int clinicId;
  final String name;
  final String? subtitle;
  final int areaId;
  final String areaName;

  BookingClinicOption({required this.clinicId, required this.name, this.subtitle, this.areaId = 0, this.areaName = ''});

  factory BookingClinicOption.fromJson(Map<String, dynamic> json) => BookingClinicOption(
        clinicId: json['clinicId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        subtitle: (json['subtitle'] as String?)?.trim(),
        areaId: json['areaId'] as int? ?? 0,
        areaName: json['areaName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'clinicId': clinicId, 'name': name, 'subtitle': subtitle, 'areaId': areaId, 'areaName': areaName};
}

class UnpaidInvoice {
  final String invoiceNumber;
  final String dueDate;
  final int daysOverdue;
  final double balance;

  UnpaidInvoice({required this.invoiceNumber, required this.dueDate, required this.daysOverdue, required this.balance});

  factory UnpaidInvoice.fromJson(Map<String, dynamic> json) => UnpaidInvoice(
        invoiceNumber: json['invoiceNumber'] as String? ?? '',
        dueDate: json['dueDate'] as String? ?? '',
        daysOverdue: json['daysOverdue'] as int? ?? 0,
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
      );
}

class UnpaidInvoicesResponse {
  final double totalBalance;
  final List<UnpaidInvoice> invoices;

  UnpaidInvoicesResponse({required this.totalBalance, required this.invoices});

  factory UnpaidInvoicesResponse.fromJson(Map<String, dynamic> json) => UnpaidInvoicesResponse(
        totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0,
        invoices: (json['invoices'] as List<dynamic>? ?? []).map((e) => UnpaidInvoice.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class PromoOption {
  final int promoId;
  final String promoCode;
  final String? promoName;

  PromoOption({required this.promoId, required this.promoCode, this.promoName});

  factory PromoOption.fromJson(Map<String, dynamic> json) => PromoOption(
        promoId: json['promoId'] as int? ?? 0,
        promoCode: json['promoCode'] as String? ?? '',
        promoName: json['promoName'] as String?,
      );

  Map<String, dynamic> toJson() => {'promoId': promoId, 'promoCode': promoCode, 'promoName': promoName};
}

class BookingRepOption {
  final int repId;
  final String repName;

  BookingRepOption({required this.repId, required this.repName});

  factory BookingRepOption.fromJson(Map<String, dynamic> json) => BookingRepOption(
        repId: json['repId'] as int? ?? 0,
        repName: json['repName'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'repId': repId, 'repName': repName};
}

// One cart line - produced locally from an item-preview call (tier
// breakdown + free accessories), or built by hand before preview runs.
class BookingLineInput {
  final String itemCode;
  final int quantity;
  final double unitPrice;
  final bool isFree;

  BookingLineInput({required this.itemCode, required this.quantity, required this.unitPrice, this.isFree = false});

  factory BookingLineInput.fromJson(Map<String, dynamic> json) => BookingLineInput(
        itemCode: json['itemCode'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        isFree: json['isFree'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'itemCode': itemCode,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'isFree': isFree,
      };

  double get total => isFree ? 0 : quantity * unitPrice;
}

class CreateBookingRequest {
  final String? username;
  final int clinicId;
  final int repId;
  final int promoId;
  final String deliveryType;
  final String? remarks;
  final List<BookingLineInput> lines;

  /// Set for bookings saved on the phone - the server uses it as the
  /// booking's reference so a retried submit can't create it twice.
  final String? clientReference;

  CreateBookingRequest({
    this.username,
    required this.clinicId,
    required this.repId,
    this.promoId = 0,
    required this.deliveryType,
    this.remarks,
    required this.lines,
    this.clientReference,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'clinicId': clinicId,
        'repId': repId,
        'promoId': promoId,
        'deliveryType': deliveryType,
        'remarks': remarks,
        'lines': lines.map((l) => l.toJson()).toList(),
        if (clientReference != null) 'clientReference': clientReference,
      };
}

class CreateBookingResponse {
  final String referenceNo;
  final String? soNo;
  final String clinicName;
  final int itemCount;
  final bool routedToDavao;

  /// The server already had this booking (an earlier submit got through).
  final bool alreadySubmitted;

  CreateBookingResponse({
    required this.referenceNo,
    this.soNo,
    required this.clinicName,
    required this.itemCount,
    required this.routedToDavao,
    this.alreadySubmitted = false,
  });

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) => CreateBookingResponse(
        referenceNo: json['referenceNo'] as String? ?? '',
        soNo: json['soNo'] as String?,
        clinicName: json['clinicName'] as String? ?? '',
        itemCount: json['itemCount'] as int? ?? 0,
        routedToDavao: json['routedToDavao'] as bool? ?? false,
        alreadySubmitted: json['alreadySubmitted'] as bool? ?? false,
      );
}

// Fixed delivery-type options - same `<select>` list as vaxiCSR's own
// _CreateForm.cshtml, not DB-driven there either.
const List<Map<String, String>> bookingDeliveryTypes = [
  {'value': 'PICKUP', 'label': 'Pickup'},
  {'value': 'CARGO', 'label': 'Cargo'},
  {'value': 'DELIVERY', 'label': 'Delivery'},
  {'value': 'LALAMOVE', 'label': 'Lalamove'},
];
