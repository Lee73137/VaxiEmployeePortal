class CollectibleCustomer {
  final int customerId;
  final String? clinicName;
  final String? contactNumber;
  final String? contactName;
  final String? location;
  final String? address;
  final String? salesRep;
  final double openBalance;
  final double overdueBalance;
  final double notDueBalance;
  final int invoiceCount;

  CollectibleCustomer({
    required this.customerId,
    this.clinicName,
    this.contactNumber,
    this.contactName,
    this.location,
    this.address,
    this.salesRep,
    this.openBalance = 0,
    this.overdueBalance = 0,
    this.notDueBalance = 0,
    this.invoiceCount = 0,
  });

  factory CollectibleCustomer.fromJson(Map<String, dynamic> json) => CollectibleCustomer(
        customerId: json['customerId'] as int,
        clinicName: json['clinicName'] as String?,
        contactNumber: (json['contactNumber'] as String?)?.trim(),
        contactName: json['contactName'] as String?,
        location: json['location'] as String?,
        address: json['address'] as String?,
        salesRep: (json['salesRep'] as String?)?.trim(),
        openBalance: (json['openBalance'] as num?)?.toDouble() ?? 0,
        overdueBalance: (json['overdueBalance'] as num?)?.toDouble() ?? 0,
        notDueBalance: (json['notDueBalance'] as num?)?.toDouble() ?? 0,
        invoiceCount: json['invoiceCount'] as int? ?? 0,
      );
}

class CollectibleListResponse {
  final List<CollectibleCustomer> items;
  final List<String> locations;
  final List<String> salesReps;
  final int totalItems;
  final double totalOpenBalanceAll;
  final int customersWithBalanceAll;
  final bool repFilterLocked;
  final bool isTruncated;

  CollectibleListResponse({
    required this.items,
    this.locations = const [],
    this.salesReps = const [],
    this.totalItems = 0,
    this.totalOpenBalanceAll = 0,
    this.customersWithBalanceAll = 0,
    this.repFilterLocked = false,
    this.isTruncated = false,
  });

  factory CollectibleListResponse.fromJson(Map<String, dynamic> json) => CollectibleListResponse(
        items: (json['items'] as List<dynamic>? ?? []).map((e) => CollectibleCustomer.fromJson(e as Map<String, dynamic>)).toList(),
        locations: (json['locations'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        salesReps: (json['salesReps'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        totalItems: json['totalItems'] as int? ?? 0,
        totalOpenBalanceAll: (json['totalOpenBalanceAll'] as num?)?.toDouble() ?? 0,
        customersWithBalanceAll: json['customersWithBalanceAll'] as int? ?? 0,
        repFilterLocked: json['repFilterLocked'] as bool? ?? false,
        isTruncated: json['isTruncated'] as bool? ?? false,
      );
}

class CollectibleInvoice {
  final int qbExtractedId;
  final String? refNumber;
  final DateTime? txnDate;
  final DateTime? dueDate;
  final double balanceRemaining;
  final int daysOverdue;

  CollectibleInvoice({
    required this.qbExtractedId,
    this.refNumber,
    this.txnDate,
    this.dueDate,
    this.balanceRemaining = 0,
    this.daysOverdue = 0,
  });

  factory CollectibleInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return CollectibleInvoice(
      qbExtractedId: json['qbExtractedId'] as int,
      refNumber: (json['refNumber'] as String?)?.trim(),
      txnDate: parseDate(json['txnDate']),
      dueDate: parseDate(json['dueDate']),
      balanceRemaining: (json['balanceRemaining'] as num?)?.toDouble() ?? 0,
      daysOverdue: json['daysOverdue'] as int? ?? 0,
    );
  }
}
