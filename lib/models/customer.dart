class Customer {
  int? customerid;
  String? listid;
  DateTime? timecreated;
  DateTime? timemodified;
  String? name;
  String? fullname;
  bool? isactive;
  String? companyname;
  String? firstname;
  String? middlename;
  String? lastname;
  String? billaddress1;
  String? billaddress2;
  String? billaddress3;
  String? billaddress4;
  String? billaddress5;
  String? city;
  String? state;
  String? postalcode;
  String? phone;
  String? altphone;
  String? fax;
  String? email;
  String? contact;
  String? termsreffullname;
  String? salesrepreffullname;
  double? balance;
  double? totalbalance;
  String? location;
  String? tinno;
  int? totalpoints;
  String? remarks;
  bool? dealer;
  DateTime? birthday;
  String? createdby;
  String? modifiedby;
  bool deleted;
  String? deletedby;
  DateTime? deletedat;

  Customer({
    this.customerid,
    this.listid,
    this.timecreated,
    this.timemodified,
    this.name,
    this.fullname,
    this.isactive,
    this.companyname,
    this.firstname,
    this.middlename,
    this.lastname,
    this.billaddress1,
    this.billaddress2,
    this.billaddress3,
    this.billaddress4,
    this.billaddress5,
    this.city,
    this.state,
    this.postalcode,
    this.phone,
    this.altphone,
    this.fax,
    this.email,
    this.contact,
    this.termsreffullname,
    this.salesrepreffullname,
    this.balance,
    this.totalbalance,
    this.location,
    this.tinno,
    this.totalpoints,
    this.remarks,
    this.dealer,
    this.birthday,
    this.createdby,
    this.modifiedby,
    this.deleted = false,
    this.deletedby,
    this.deletedat,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

    return Customer(
      customerid: json['customerid'] as int?,
      listid: json['listid'] as String?,
      timecreated: parseDate(json['timecreated']),
      timemodified: parseDate(json['timemodified']),
      name: json['name'] as String?,
      fullname: json['fullname'] as String?,
      isactive: json['isactive'] as bool?,
      companyname: json['companyname'] as String?,
      firstname: json['firstname'] as String?,
      middlename: json['middlename'] as String?,
      lastname: json['lastname'] as String?,
      billaddress1: json['billaddress1'] as String?,
      billaddress2: json['billaddress2'] as String?,
      billaddress3: json['billaddress3'] as String?,
      billaddress4: json['billaddress4'] as String?,
      billaddress5: json['billaddress5'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalcode: json['postalcode'] as String?,
      phone: json['phone'] as String?,
      altphone: json['altphone'] as String?,
      fax: json['fax'] as String?,
      email: json['email'] as String?,
      contact: json['contact'] as String?,
      termsreffullname: json['termsreffullname'] as String?,
      salesrepreffullname: json['salesrepreffullname'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      totalbalance: (json['totalbalance'] as num?)?.toDouble(),
      location: json['location'] as String?,
      tinno: json['tinno'] as String?,
      totalpoints: json['totalpoints'] as int?,
      remarks: json['remarks'] as String?,
      dealer: json['dealer'] as bool?,
      birthday: parseDate(json['birthday']),
      createdby: json['createdby'] as String?,
      modifiedby: json['modifiedby'] as String?,
      deleted: json['deleted'] as bool? ?? false,
      deletedby: json['deletedby'] as String?,
      deletedat: parseDate(json['deletedat']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerid': customerid,
      'name': name,
      'fullname': fullname,
      'isactive': isactive,
      'companyname': companyname,
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
      'billaddress1': billaddress1,
      'billaddress2': billaddress2,
      'billaddress3': billaddress3,
      'billaddress4': billaddress4,
      'billaddress5': billaddress5,
      'city': city,
      'state': state,
      'postalcode': postalcode,
      'phone': phone,
      'altphone': altphone,
      'fax': fax,
      'email': email,
      'contact': contact,
      'location': location,
      'tinno': tinno,
      'remarks': remarks,
      'dealer': dealer,
      'birthday': birthday?.toIso8601String(),
    };
  }

  String get displayName => (fullname?.isNotEmpty ?? false) ? fullname! : (name ?? '');
}
