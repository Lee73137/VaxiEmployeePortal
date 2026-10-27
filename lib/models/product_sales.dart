class ProductSalesRow {
  final String itemCode;
  final int quantity;
  final int free;
  final double amount;
  final int totalItems;

  ProductSalesRow({
    required this.itemCode,
    this.quantity = 0,
    this.free = 0,
    this.amount = 0,
    this.totalItems = 0,
  });

  factory ProductSalesRow.fromJson(Map<String, dynamic> json) => ProductSalesRow(
        itemCode: json['itemCode'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        free: json['free'] as int? ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        totalItems: json['totalItems'] as int? ?? 0,
      );
}

class ProductSalesResponse {
  final bool generated;
  final List<ProductSalesRow> rows;
  final double totalSales;
  final double uncollectedAmount;
  final double vaxishAppSales;
  final double vaxihubSales;
  final List<ProductSalesRow> vaxishAppItemRows;
  final List<ProductSalesRow> vaxihubItemRows;
  final List<ProductSalesCustomerRow> vaxishAppCustomerRows;
  final List<ProductSalesCustomerRow> vaxihubCustomerRows;
  final bool repFilterLocked;
  final List<String> repOptions;
  final List<String> prefixOptions;

  ProductSalesResponse({
    this.generated = false,
    this.rows = const [],
    this.totalSales = 0,
    this.uncollectedAmount = 0,
    this.vaxishAppSales = 0,
    this.vaxihubSales = 0,
    this.vaxishAppItemRows = const [],
    this.vaxihubItemRows = const [],
    this.vaxishAppCustomerRows = const [],
    this.vaxihubCustomerRows = const [],
    this.repFilterLocked = false,
    this.repOptions = const [],
    this.prefixOptions = const [],
  });

  factory ProductSalesResponse.fromJson(Map<String, dynamic> json) => ProductSalesResponse(
        generated: json['generated'] as bool? ?? false,
        rows: (json['rows'] as List<dynamic>? ?? []).map((e) => ProductSalesRow.fromJson(e as Map<String, dynamic>)).toList(),
        totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
        uncollectedAmount: (json['uncollectedAmount'] as num?)?.toDouble() ?? 0,
        vaxishAppSales: (json['vaxishAppSales'] as num?)?.toDouble() ?? 0,
        vaxihubSales: (json['vaxihubSales'] as num?)?.toDouble() ?? 0,
        vaxishAppItemRows: (json['vaxishAppItemRows'] as List<dynamic>? ?? []).map((e) => ProductSalesRow.fromJson(e as Map<String, dynamic>)).toList(),
        vaxihubItemRows: (json['vaxihubItemRows'] as List<dynamic>? ?? []).map((e) => ProductSalesRow.fromJson(e as Map<String, dynamic>)).toList(),
        vaxishAppCustomerRows: (json['vaxishAppCustomerRows'] as List<dynamic>? ?? [])
            .map((e) => ProductSalesCustomerRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        vaxihubCustomerRows: (json['vaxihubCustomerRows'] as List<dynamic>? ?? [])
            .map((e) => ProductSalesCustomerRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        repFilterLocked: json['repFilterLocked'] as bool? ?? false,
        repOptions: (json['repOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        prefixOptions: (json['prefixOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}

class OtherProductRow {
  final String itemCode;
  final String? tsrCode;
  final String? refNumber;
  final DateTime? txnDate;
  final int quantity;
  final int free;
  final double amount;
  final double balanceRemaining;
  final double collectedAmount;

  OtherProductRow({
    required this.itemCode,
    this.tsrCode,
    this.refNumber,
    this.txnDate,
    this.quantity = 0,
    this.free = 0,
    this.amount = 0,
    this.balanceRemaining = 0,
    this.collectedAmount = 0,
  });

  factory OtherProductRow.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return OtherProductRow(
      itemCode: json['itemCode'] as String? ?? '',
      tsrCode: (json['tsrCode'] as String?)?.trim(),
      refNumber: (json['refNumber'] as String?)?.trim(),
      txnDate: parseDate(json['txnDate']),
      quantity: json['quantity'] as int? ?? 0,
      free: json['free'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceRemaining: (json['balanceRemaining'] as num?)?.toDouble() ?? 0,
      collectedAmount: (json['collectedAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// One row of a "Per Customer" tab (VaxiShApp or VaxiHub).
class ProductSalesCustomerRow {
  final String customerName;
  final String location;
  final int quantity;
  final double amount;

  ProductSalesCustomerRow({required this.customerName, this.location = '', this.quantity = 0, this.amount = 0});

  factory ProductSalesCustomerRow.fromJson(Map<String, dynamic> json) => ProductSalesCustomerRow(
        customerName: json['customerName'] as String? ?? '',
        location: json['location'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 0,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

/// One invoice behind a Per Customer row, with its item lines.
class ProductSalesCustomerInvoice {
  final String? refNumber;
  final int qbExtractedId;
  final DateTime? txnDate;
  final String? tsrCode;
  final double subtotal;
  final double balanceRemaining;
  final double collectedAmount;
  final List<ProductSalesRow> items;

  ProductSalesCustomerInvoice({
    this.refNumber,
    this.qbExtractedId = 0,
    this.txnDate,
    this.tsrCode,
    this.subtotal = 0,
    this.balanceRemaining = 0,
    this.collectedAmount = 0,
    this.items = const [],
  });

  factory ProductSalesCustomerInvoice.fromJson(Map<String, dynamic> json) => ProductSalesCustomerInvoice(
        refNumber: (json['refNumber'] as String?)?.trim(),
        qbExtractedId: json['qbExtractedId'] as int? ?? 0,
        txnDate: json['txnDate'] == null ? null : DateTime.tryParse(json['txnDate'] as String),
        tsrCode: (json['tsrCode'] as String?)?.trim(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        balanceRemaining: (json['balanceRemaining'] as num?)?.toDouble() ?? 0,
        collectedAmount: (json['collectedAmount'] as num?)?.toDouble() ?? 0,
        items: (json['items'] as List<dynamic>? ?? []).map((e) => ProductSalesRow.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
