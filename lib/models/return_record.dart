class ReturnItem {
  final int? returnitemid;
  final String? itemcode;
  final String? unitofmeasure;
  final int quantity;
  final String? lotnumber;
  final String? reasoncategory;
  final String? notes;

  ReturnItem({
    this.returnitemid,
    this.itemcode,
    this.unitofmeasure,
    required this.quantity,
    this.lotnumber,
    this.reasoncategory,
    this.notes,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      returnitemid: json['returnitemid'] as int?,
      itemcode: json['itemcode'] as String?,
      unitofmeasure: (json['unitofmeasure'] as String?)?.trim(),
      quantity: json['quantity'] as int? ?? 0,
      lotnumber: json['lotnumber'] as String?,
      reasoncategory: json['reasoncategory'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class ReturnRecord {
  final int returnid;
  final int qbextractedid;
  final String? refnumber;
  final String? customerfullname;
  final String? referenceid;
  final DateTime returndate;
  final String? recordedby;

  ReturnRecord({
    required this.returnid,
    required this.qbextractedid,
    this.refnumber,
    this.customerfullname,
    this.referenceid,
    required this.returndate,
    this.recordedby,
  });

  factory ReturnRecord.fromJson(Map<String, dynamic> json) {
    return ReturnRecord(
      returnid: json['returnid'] as int,
      qbextractedid: json['qbextractedid'] as int? ?? 0,
      refnumber: (json['refnumber'] as String?)?.trim(),
      customerfullname: json['customerfullname'] as String?,
      referenceid: json['referenceid'] as String?,
      returndate: DateTime.tryParse(json['returndate'] as String? ?? '') ?? DateTime.now(),
      recordedby: json['recordedby'] as String?,
    );
  }
}

class ReturnRow {
  final ReturnRecord returnRecord;
  final List<ReturnItem> items;
  final int totalQuantity;

  ReturnRow({required this.returnRecord, required this.items, required this.totalQuantity});

  factory ReturnRow.fromJson(Map<String, dynamic> json) {
    return ReturnRow(
      returnRecord: ReturnRecord.fromJson(json['return'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>? ?? []).map((e) => ReturnItem.fromJson(e as Map<String, dynamic>)).toList(),
      totalQuantity: json['totalQuantity'] as int? ?? 0,
    );
  }
}

class ReturnListResponse {
  final List<ReturnRow> items;
  final String? search;
  final int page;
  final int totalItems;
  final int totalPages;

  ReturnListResponse({required this.items, this.search, required this.page, required this.totalItems, required this.totalPages});

  factory ReturnListResponse.fromJson(Map<String, dynamic> json) {
    return ReturnListResponse(
      items: (json['items'] as List<dynamic>? ?? []).map((e) => ReturnRow.fromJson(e as Map<String, dynamic>)).toList(),
      search: json['search'] as String?,
      page: json['page'] as int? ?? 1,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}

class InvoiceSearchResult {
  final int id;
  final String? refnumber;
  final String? customername;
  final String? txndate;
  final double balance;

  InvoiceSearchResult({required this.id, this.refnumber, this.customername, this.txndate, required this.balance});

  factory InvoiceSearchResult.fromJson(Map<String, dynamic> json) {
    return InvoiceSearchResult(
      id: json['id'] as int,
      refnumber: (json['refnumber'] as String?)?.trim(),
      customername: json['customername'] as String?,
      txndate: json['txndate'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InvoiceItemForReturn {
  final String itemcode;
  final int quantity;
  final int alreadyReturned;
  final int remaining;
  final String? uom;
  final List<String> knownLots;

  InvoiceItemForReturn({
    required this.itemcode,
    required this.quantity,
    required this.alreadyReturned,
    required this.remaining,
    this.uom,
    required this.knownLots,
  });

  factory InvoiceItemForReturn.fromJson(Map<String, dynamic> json) {
    return InvoiceItemForReturn(
      itemcode: json['itemcode'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      alreadyReturned: json['alreadyReturned'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
      uom: (json['uom'] as String?)?.trim(),
      knownLots: (json['knownLots'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
    );
  }
}

class InvoiceItemsForReturnResponse {
  final int invoiceId;
  final String? refnumber;
  final String? customername;
  final List<InvoiceItemForReturn> items;

  InvoiceItemsForReturnResponse({required this.invoiceId, this.refnumber, this.customername, required this.items});

  factory InvoiceItemsForReturnResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceItemsForReturnResponse(
      invoiceId: json['invoiceId'] as int,
      refnumber: (json['refnumber'] as String?)?.trim(),
      customername: json['customername'] as String?,
      items: (json['items'] as List<dynamic>? ?? []).map((e) => InvoiceItemForReturn.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
