class ClinicHistoryListItem {
  final int clinicId;
  final String? clinicName;
  final String? clinicMunicipality;
  final double openBalance;
  final String? location;
  final String? salesRep;

  ClinicHistoryListItem({
    required this.clinicId,
    this.clinicName,
    this.clinicMunicipality,
    this.openBalance = 0,
    this.location,
    this.salesRep,
  });

  factory ClinicHistoryListItem.fromJson(Map<String, dynamic> json) => ClinicHistoryListItem(
        clinicId: json['clinicId'] as int,
        clinicName: json['clinicName'] as String?,
        clinicMunicipality: json['clinicMunicipality'] as String?,
        openBalance: (json['openBalance'] as num?)?.toDouble() ?? 0,
        location: json['location'] as String?,
        salesRep: json['salesRep'] as String?,
      );
}

class ClinicHistoryInvoice {
  final int qbExtractedId;
  final String? refNumber;
  final DateTime? txnDate;
  final DateTime? dueDate;
  final double subtotal;
  final double balanceRemaining;
  final String? location;
  final String? shipMethod;
  final bool isReturned;

  ClinicHistoryInvoice({
    required this.qbExtractedId,
    this.refNumber,
    this.txnDate,
    this.dueDate,
    this.subtotal = 0,
    this.balanceRemaining = 0,
    this.location,
    this.shipMethod,
    this.isReturned = false,
  });

  factory ClinicHistoryInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return ClinicHistoryInvoice(
      qbExtractedId: json['qbExtractedId'] as int,
      refNumber: (json['refNumber'] as String?)?.trim(),
      txnDate: parseDate(json['txnDate']),
      dueDate: parseDate(json['dueDate']),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      balanceRemaining: (json['balanceRemaining'] as num?)?.toDouble() ?? 0,
      location: json['location'] as String?,
      shipMethod: json['shipMethod'] as String?,
      isReturned: json['isReturned'] as bool? ?? false,
    );
  }
}

class ClinicHistoryBooking {
  final int bookingId;
  final String? sono;
  final String? drno;
  final DateTime? dateOrder;
  final String? itemCode;
  final int? quantity;
  final String? repName;
  final int? status;
  final String? statusName;

  ClinicHistoryBooking({
    required this.bookingId,
    this.sono,
    this.drno,
    this.dateOrder,
    this.itemCode,
    this.quantity,
    this.repName,
    this.status,
    this.statusName,
  });

  factory ClinicHistoryBooking.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return ClinicHistoryBooking(
      bookingId: json['bookingId'] as int,
      sono: json['sono'] as String?,
      drno: json['drno'] as String?,
      dateOrder: parseDate(json['dateOrder']),
      itemCode: json['itemCode'] as String?,
      quantity: json['quantity'] as int?,
      repName: json['repName'] as String?,
      status: json['status'] as int?,
      statusName: json['statusName'] as String?,
    );
  }
}

class ClinicHistoryDetail {
  final int clinicId;
  final String? clinicName;
  final String? clinicMunicipality;
  final String? clinicAddress;
  final double? latitude;
  final double? longitude;
  final bool hasLocation;
  final double totalInvoiced;
  final double openBalance;
  final double totalDue;
  final double totalUndue;
  final List<ClinicHistoryInvoice> invoices;
  final List<ClinicHistoryBooking> bookings;

  ClinicHistoryDetail({
    required this.clinicId,
    this.clinicName,
    this.clinicMunicipality,
    this.clinicAddress,
    this.latitude,
    this.longitude,
    this.hasLocation = false,
    this.totalInvoiced = 0,
    this.openBalance = 0,
    this.totalDue = 0,
    this.totalUndue = 0,
    this.invoices = const [],
    this.bookings = const [],
  });

  factory ClinicHistoryDetail.fromJson(Map<String, dynamic> json) {
    return ClinicHistoryDetail(
      clinicId: json['clinicId'] as int,
      clinicName: json['clinicName'] as String?,
      clinicMunicipality: json['clinicMunicipality'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hasLocation: json['hasLocation'] as bool? ?? false,
      totalInvoiced: (json['totalInvoiced'] as num?)?.toDouble() ?? 0,
      openBalance: (json['openBalance'] as num?)?.toDouble() ?? 0,
      totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
      totalUndue: (json['totalUndue'] as num?)?.toDouble() ?? 0,
      invoices: (json['invoices'] as List<dynamic>? ?? [])
          .map((e) => ClinicHistoryInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      bookings: (json['bookings'] as List<dynamic>? ?? [])
          .map((e) => ClinicHistoryBooking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
