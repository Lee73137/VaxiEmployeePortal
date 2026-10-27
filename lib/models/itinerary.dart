class Itinerary {
  final int itineraryId;
  final DateTime scheduleDate;
  final int repId;
  final String? repName;
  final int clinicId;
  final String? clinicName;
  final String? areaName;
  final String? purpose;
  final double totalOverdueBalance;
  final bool? approved;
  final DateTime? dateApproved;
  final String? approvedBy;
  final DateTime? arrivalTime;
  final String statusLabel;
  final String? drCollection;
  final double? drCollectionAmount;
  final double? drCollectionAmountCollected;
  final String? drDelivery;
  final double? drDeliveryAmount;
  final bool hasSignature;

  Itinerary({
    required this.itineraryId,
    required this.scheduleDate,
    required this.repId,
    this.repName,
    required this.clinicId,
    this.clinicName,
    this.areaName,
    this.purpose,
    this.totalOverdueBalance = 0,
    this.approved,
    this.dateApproved,
    this.approvedBy,
    this.arrivalTime,
    this.statusLabel = 'Pending',
    this.drCollection,
    this.drCollectionAmount,
    this.drCollectionAmountCollected,
    this.drDelivery,
    this.drDeliveryAmount,
    this.hasSignature = false,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return Itinerary(
      itineraryId: json['itineraryId'] as int,
      scheduleDate: parseDate(json['scheduleDate']) ?? DateTime.now(),
      repId: json['repId'] as int,
      repName: json['repName'] as String?,
      clinicId: json['clinicId'] as int,
      clinicName: json['clinicName'] as String?,
      areaName: (json['areaName'] as String?)?.trim(),
      purpose: json['purpose'] as String?,
      totalOverdueBalance: (json['totalOverdueBalance'] as num?)?.toDouble() ?? 0,
      approved: json['approved'] as bool?,
      dateApproved: parseDate(json['dateApproved']),
      approvedBy: json['approvedBy'] as String?,
      arrivalTime: parseDate(json['arrivalTime']),
      statusLabel: json['statusLabel'] as String? ?? 'Pending',
      drCollection: json['drCollection'] as String?,
      drCollectionAmount: (json['drCollectionAmount'] as num?)?.toDouble(),
      drCollectionAmountCollected: (json['drCollectionAmountCollected'] as num?)?.toDouble(),
      drDelivery: json['drDelivery'] as String?,
      drDeliveryAmount: (json['drDeliveryAmount'] as num?)?.toDouble(),
      hasSignature: json['hasSignature'] as bool? ?? false,
    );
  }
}

class ItineraryListResponse {
  final List<Itinerary> items;
  final bool canApprove;
  final bool repFilterLocked;

  ItineraryListResponse({required this.items, required this.canApprove, required this.repFilterLocked});

  factory ItineraryListResponse.fromJson(Map<String, dynamic> json) => ItineraryListResponse(
        items: (json['items'] as List<dynamic>? ?? []).map((e) => Itinerary.fromJson(e as Map<String, dynamic>)).toList(),
        canApprove: json['canApprove'] as bool? ?? false,
        repFilterLocked: json['repFilterLocked'] as bool? ?? false,
      );
}

class ItinerarySaveRequest {
  final DateTime scheduleDate;
  final int repId;
  final int clinicId;
  final String? purpose;
  final String? drCollection;
  final double? drCollectionAmount;

  ItinerarySaveRequest({
    required this.scheduleDate,
    required this.repId,
    required this.clinicId,
    this.purpose,
    this.drCollection,
    this.drCollectionAmount,
  });

  Map<String, dynamic> toJson() => {
        'scheduleDate': scheduleDate.toIso8601String(),
        'repId': repId,
        'clinicId': clinicId,
        'purpose': purpose,
        'drCollection': drCollection,
        'drCollectionAmount': drCollectionAmount,
      };
}

class ItineraryInvoice {
  final int qbExtractedId;
  final String? refNumber;
  final DateTime? dueDate;
  final double balanceRemaining;
  final bool isOverdue;

  ItineraryInvoice({
    required this.qbExtractedId,
    this.refNumber,
    this.dueDate,
    this.balanceRemaining = 0,
    this.isOverdue = false,
  });

  factory ItineraryInvoice.fromJson(Map<String, dynamic> json) => ItineraryInvoice(
        qbExtractedId: json['qbExtractedId'] as int,
        refNumber: (json['refNumber'] as String?)?.trim(),
        dueDate: json['dueDate'] == null ? null : DateTime.tryParse(json['dueDate'] as String),
        balanceRemaining: (json['balanceRemaining'] as num?)?.toDouble() ?? 0,
        isOverdue: json['isOverdue'] as bool? ?? false,
      );
}

class ItineraryVisit {
  final int itineraryId;
  final DateTime scheduleDate;
  final String? clinicName;
  final String? clinicAddress;
  final String? contactNumber;
  final String? purpose;
  final bool? approved;
  final DateTime? arrivalTime;
  final double totalOverdueBalance;
  final double totalNotDueBalance;
  final List<ItineraryInvoice> unpaidInvoices;
  final String? drDelivery;
  final double? drDeliveryAmount;
  final String? drCollection;
  final double? drCollectionAmount;
  final double? drCollectionAmountCollected;
  final String? visitRemarks;
  final String statusLabel;

  ItineraryVisit({
    required this.itineraryId,
    required this.scheduleDate,
    this.clinicName,
    this.clinicAddress,
    this.contactNumber,
    this.purpose,
    this.approved,
    this.arrivalTime,
    this.totalOverdueBalance = 0,
    this.totalNotDueBalance = 0,
    this.unpaidInvoices = const [],
    this.drDelivery,
    this.drDeliveryAmount,
    this.drCollection,
    this.drCollectionAmount,
    this.drCollectionAmountCollected,
    this.visitRemarks,
    this.statusLabel = 'Pending',
  });

  factory ItineraryVisit.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return ItineraryVisit(
      itineraryId: json['itineraryId'] as int,
      scheduleDate: parseDate(json['scheduleDate']) ?? DateTime.now(),
      clinicName: json['clinicName'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      contactNumber: json['contactNumber'] as String?,
      purpose: json['purpose'] as String?,
      approved: json['approved'] as bool?,
      arrivalTime: parseDate(json['arrivalTime']),
      totalOverdueBalance: (json['totalOverdueBalance'] as num?)?.toDouble() ?? 0,
      totalNotDueBalance: (json['totalNotDueBalance'] as num?)?.toDouble() ?? 0,
      unpaidInvoices: (json['unpaidInvoices'] as List<dynamic>? ?? []).map((e) => ItineraryInvoice.fromJson(e as Map<String, dynamic>)).toList(),
      drDelivery: json['drDelivery'] as String?,
      drDeliveryAmount: (json['drDeliveryAmount'] as num?)?.toDouble(),
      drCollection: json['drCollection'] as String?,
      drCollectionAmount: (json['drCollectionAmount'] as num?)?.toDouble(),
      drCollectionAmountCollected: (json['drCollectionAmountCollected'] as num?)?.toDouble(),
      visitRemarks: json['visitRemarks'] as String?,
      statusLabel: json['statusLabel'] as String? ?? 'Pending',
    );
  }
}

class ItineraryClinicOption {
  final int clinicId;
  final String name;
  final String? subtitle;

  ItineraryClinicOption({required this.clinicId, required this.name, this.subtitle});

  factory ItineraryClinicOption.fromJson(Map<String, dynamic> json) => ItineraryClinicOption(
        clinicId: json['clinicId'] as int,
        name: json['name'] as String? ?? '',
        subtitle: (json['subtitle'] as String?)?.trim(),
      );
}

class ItineraryActivity {
  final int activityId;
  final String description;

  ItineraryActivity({required this.activityId, required this.description});

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) => ItineraryActivity(
        activityId: json['activityId'] as int,
        description: json['activityDescription'] as String? ?? '',
      );
}
