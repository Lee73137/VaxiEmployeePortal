class MarketingSupportListItem {
  final int requestId;
  final String referenceNo;
  final String clinicName;
  final DateTime requestDate;
  final String tsr;
  final String status;
  final String requestType;
  final String? description;
  final String? location;
  final DateTime? dateApproved;
  final DateTime? dateFulfilled;

  MarketingSupportListItem({
    required this.requestId,
    required this.referenceNo,
    required this.clinicName,
    required this.requestDate,
    required this.tsr,
    required this.status,
    required this.requestType,
    this.description,
    this.location,
    this.dateApproved,
    this.dateFulfilled,
  });

  factory MarketingSupportListItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return MarketingSupportListItem(
      requestId: json['requestId'] as int,
      referenceNo: json['referenceNo'] as String? ?? '',
      clinicName: json['clinicName'] as String? ?? '',
      requestDate: parseDate(json['requestDate']) ?? DateTime.now(),
      tsr: json['tsr'] as String? ?? '',
      status: json['status'] as String? ?? '',
      requestType: json['requestType'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      dateApproved: parseDate(json['dateApproved']),
      dateFulfilled: parseDate(json['dateFulfilled']),
    );
  }
}

class MarketingSupportItem {
  final int requestDetailId;
  final String itemCode;
  final int qty;

  MarketingSupportItem({required this.requestDetailId, required this.itemCode, required this.qty});

  factory MarketingSupportItem.fromJson(Map<String, dynamic> json) => MarketingSupportItem(
        requestDetailId: json['requestDetailId'] as int,
        itemCode: json['itemCode'] as String? ?? '',
        qty: json['qty'] as int? ?? 0,
      );
}

class MarketingSupportDetail {
  final int requestId;
  final String referenceNo;
  final int clinicId;
  final String clinicName;
  final DateTime requestDate;
  final String tsr;
  final String status;
  final String? description;
  final String requestType;
  final String? remarks;
  final String? reason;
  final String? location;
  final DateTime? dateApproved;
  final DateTime? dateFulfilled;
  final List<MarketingSupportItem> items;
  final bool canDecide;
  final bool canMarkFulfilled;
  final bool canDelete;

  MarketingSupportDetail({
    required this.requestId,
    required this.referenceNo,
    required this.clinicId,
    required this.clinicName,
    required this.requestDate,
    required this.tsr,
    required this.status,
    this.description,
    required this.requestType,
    this.remarks,
    this.reason,
    this.location,
    this.dateApproved,
    this.dateFulfilled,
    this.items = const [],
    this.canDecide = false,
    this.canMarkFulfilled = false,
    this.canDelete = false,
  });

  factory MarketingSupportDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return MarketingSupportDetail(
      requestId: json['requestId'] as int,
      referenceNo: json['referenceNo'] as String? ?? '',
      clinicId: json['clinicId'] as int,
      clinicName: json['clinicName'] as String? ?? '',
      requestDate: parseDate(json['requestDate']) ?? DateTime.now(),
      tsr: json['tsr'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
      requestType: json['requestType'] as String? ?? '',
      remarks: json['remarks'] as String?,
      reason: json['reason'] as String?,
      location: json['location'] as String?,
      dateApproved: parseDate(json['dateApproved']),
      dateFulfilled: parseDate(json['dateFulfilled']),
      items: (json['items'] as List<dynamic>? ?? []).map((e) => MarketingSupportItem.fromJson(e as Map<String, dynamic>)).toList(),
      canDecide: json['canDecide'] as bool? ?? false,
      canMarkFulfilled: json['canMarkFulfilled'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
    );
  }
}

// POST (create) / PUT (edit) body - status/decision fields are never touched
// through this request, only via decision()/markFulfilled() below (mirrors
// vaxiCSR's own Manage POST).
class MarketingSupportSaveRequest {
  final String? username;
  final int clinicId;
  final DateTime requestDate;
  final String description;
  final String requestType;
  final String? remarks;
  final String? location;

  MarketingSupportSaveRequest({
    this.username,
    required this.clinicId,
    required this.requestDate,
    required this.description,
    required this.requestType,
    this.remarks,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'clinicId': clinicId,
        'requestDate': requestDate.toIso8601String(),
        'description': description,
        'requestType': requestType,
        'remarks': remarks,
        'location': location,
      };
}

// Fixed enum of request types - a `private static readonly string[]` in
// vaxiCSR's own MarketingSupportController, not DB-driven there either.
const List<String> marketingSupportRequestTypes = [
  'Anniversary',
  'Birthday',
  'Donations',
  'Events',
  'Opening of Clinics',
  'Opening of New Branches',
  'Others',
  'Registration',
];
