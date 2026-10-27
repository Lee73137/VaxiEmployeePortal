class Invoice {
  final int qbextractedid;
  final String? customerfullname;
  final DateTime? txndate;
  final String? refnumber;
  final String? termsreffullname;
  final DateTime? duedate;
  final String? salesrepreffullname;
  final double? subtotal;
  final double? balanceremaining;
  final bool? ispaid;
  final String? location;
  final int daysOverdue;
  final int daysUntilDue;

  Invoice({
    required this.qbextractedid,
    this.customerfullname,
    this.txndate,
    this.refnumber,
    this.termsreffullname,
    this.duedate,
    this.salesrepreffullname,
    this.subtotal,
    this.balanceremaining,
    this.ispaid,
    this.location,
    required this.daysOverdue,
    required this.daysUntilDue,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return Invoice(
      qbextractedid: json['qbextractedid'] as int,
      customerfullname: json['customerfullname'] as String?,
      txndate: parseDate(json['txndate']),
      refnumber: (json['refnumber'] as String?)?.trim(),
      termsreffullname: json['termsreffullname'] as String?,
      duedate: parseDate(json['duedate']),
      salesrepreffullname: json['salesrepreffullname'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      balanceremaining: (json['balanceremaining'] as num?)?.toDouble(),
      ispaid: json['ispaid'] as bool?,
      location: json['location'] as String?,
      daysOverdue: json['daysOverdue'] as int? ?? 0,
      daysUntilDue: json['daysUntilDue'] as int? ?? 0,
    );
  }
}

class InvoiceList {
  final List<Invoice> items;
  final String sort;
  final String dir;
  final int page;
  final int pageSize;
  final int totalItems;
  final double totalBalance;
  final int totalPages;

  InvoiceList({
    required this.items,
    required this.sort,
    required this.dir,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalBalance,
    required this.totalPages,
  });

  factory InvoiceList.fromJson(Map<String, dynamic> json) {
    return InvoiceList(
      items: (json['items'] as List<dynamic>? ?? []).map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList(),
      sort: json['sort'] as String? ?? 'duedate',
      dir: json['dir'] as String? ?? 'asc',
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalItems: json['totalItems'] as int? ?? 0,
      totalBalance: (json['totalBalance'] as num?)?.toDouble() ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class InvoiceDashboard {
  final DateTime asOf;
  final InvoiceList overdue;
  final InvoiceList dueSoon;

  InvoiceDashboard({required this.asOf, required this.overdue, required this.dueSoon});

  factory InvoiceDashboard.fromJson(Map<String, dynamic> json) {
    return InvoiceDashboard(
      asOf: DateTime.tryParse(json['asOf'] as String? ?? '') ?? DateTime.now(),
      overdue: InvoiceList.fromJson(json['overdue'] as Map<String, dynamic>),
      dueSoon: InvoiceList.fromJson(json['dueSoon'] as Map<String, dynamic>),
    );
  }
}

class InvoiceDetailItem {
  final int qbextracteddetailid;
  final String? itemreffullname;
  final String? description;
  final int? quantity;
  final String? unitofmeasure;
  final double? orrate;
  final double? amount;

  InvoiceDetailItem({
    required this.qbextracteddetailid,
    this.itemreffullname,
    this.description,
    this.quantity,
    this.unitofmeasure,
    this.orrate,
    this.amount,
  });

  factory InvoiceDetailItem.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailItem(
      qbextracteddetailid: json['qbextracteddetailid'] as int,
      itemreffullname: json['itemreffullname'] as String?,
      description: json['description'] as String?,
      quantity: json['quantity'] as int?,
      unitofmeasure: (json['unitofmeasure'] as String?)?.trim(),
      orrate: (json['orrate'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }
}

class InvoiceItemsResponse {
  final Invoice invoice;
  final List<InvoiceDetailItem> items;
  final double totalAmount;

  InvoiceItemsResponse({required this.invoice, required this.items, required this.totalAmount});

  factory InvoiceItemsResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceItemsResponse(
      invoice: Invoice.fromJson(json['invoice'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>? ?? []).map((e) => InvoiceDetailItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
