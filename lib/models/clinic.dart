class Clinic {
  int? clinicId;
  String? clinicName;
  int? areaId;
  String? areaCode;
  String? clinicMunicipality;
  String? contactNumber;
  String? clinicAddress;
  String? contactPerson;
  int? repId;
  String? repCode;
  String? clinicRemarks;
  int? terms;
  String? tinNo;
  bool? withSi;
  bool isActive;
  DateTime? lastOrderDate;
  double? openBalance;

  Clinic({
    this.clinicId,
    this.clinicName,
    this.areaId,
    this.areaCode,
    this.clinicMunicipality,
    this.contactNumber,
    this.clinicAddress,
    this.contactPerson,
    this.repId,
    this.repCode,
    this.clinicRemarks,
    this.terms,
    this.tinNo,
    this.withSi,
    this.isActive = true,
    this.lastOrderDate,
    this.openBalance,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

    return Clinic(
      clinicId: json['clinicId'] as int?,
      clinicName: json['clinicName'] as String?,
      areaId: json['areaId'] as int?,
      areaCode: (json['areaCode'] as String?)?.trim(),
      clinicMunicipality: json['clinicMunicipality'] as String?,
      contactNumber: json['contactNumber'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
      contactPerson: json['contactPerson'] as String?,
      repId: json['repId'] as int?,
      repCode: (json['repCode'] as String?)?.trim(),
      clinicRemarks: json['clinicRemarks'] as String?,
      terms: json['terms'] as int?,
      tinNo: json['tinNo'] as String?,
      withSi: json['withSi'] as bool?,
      isActive: json['isActive'] as bool? ?? true,
      lastOrderDate: parseDate(json['lastOrderDate']),
      openBalance: (json['openBalance'] as num?)?.toDouble(),
    );
  }

  // Matches vaxiCSR.Api's ClinicSaveRequest - isActive/areaCode/repCode/
  // lastOrderDate/openBalance are server-derived or toggled separately, so
  // they're never sent on create/edit.
  Map<String, dynamic> toSaveJson() {
    return {
      'clinicName': clinicName,
      'areaId': areaId,
      'clinicMunicipality': clinicMunicipality,
      'contactNumber': contactNumber,
      'clinicAddress': clinicAddress,
      'contactPerson': contactPerson,
      'repId': repId,
      'clinicRemarks': clinicRemarks,
      'terms': terms,
      'tinNo': tinNo,
      'withSi': withSi,
    };
  }
}

class ClinicArea {
  final int areaId;
  final String? areaCode;
  final String? areaDescription;

  ClinicArea({required this.areaId, this.areaCode, this.areaDescription});

  factory ClinicArea.fromJson(Map<String, dynamic> json) => ClinicArea(
        areaId: json['areaId'] as int,
        areaCode: (json['areaCode'] as String?)?.trim(),
        areaDescription: (json['areaDescription'] as String?)?.trim(),
      );

  String get label => (areaDescription?.isNotEmpty ?? false) ? areaDescription! : (areaCode ?? '');
}

class ClinicSalesRep {
  final int repId;
  final String? representativeName;
  final String? representativeCode;

  ClinicSalesRep({required this.repId, this.representativeName, this.representativeCode});

  factory ClinicSalesRep.fromJson(Map<String, dynamic> json) => ClinicSalesRep(
        repId: json['repId'] as int,
        representativeName: (json['representativeName'] as String?)?.trim(),
        representativeCode: (json['representativeCode'] as String?)?.trim(),
      );

  String get label => representativeName ?? representativeCode ?? '';
}
