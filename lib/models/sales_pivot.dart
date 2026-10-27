class SalesPivotMonth {
  final int year;
  final int month;
  final String label;

  SalesPivotMonth({required this.year, required this.month, required this.label});

  factory SalesPivotMonth.fromJson(Map<String, dynamic> json) => SalesPivotMonth(
        year: json['year'] as int,
        month: json['month'] as int,
        label: json['label'] as String? ?? '',
      );
}

class SalesPivotRow {
  final String clinicName;
  final String? salesRep;
  final String? location;
  final List<double> monthlyAmounts;
  final double rowTotal;
  final bool boughtEveryMonth;

  SalesPivotRow({
    required this.clinicName,
    this.salesRep,
    this.location,
    this.monthlyAmounts = const [],
    this.rowTotal = 0,
    this.boughtEveryMonth = false,
  });

  factory SalesPivotRow.fromJson(Map<String, dynamic> json) => SalesPivotRow(
        clinicName: json['clinicName'] as String? ?? '',
        salesRep: json['salesRep'] as String?,
        location: json['location'] as String?,
        monthlyAmounts: (json['monthlyAmounts'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
        rowTotal: (json['rowTotal'] as num?)?.toDouble() ?? 0,
        boughtEveryMonth: json['boughtEveryMonth'] as bool? ?? false,
      );
}

class SalesPivotResponse {
  final bool generated;
  final List<SalesPivotMonth> months;
  final List<SalesPivotRow> rows;
  final List<double> grandTotalsByMonth;
  final double grandTotal;
  final List<String> repOptions;

  SalesPivotResponse({
    this.generated = false,
    this.months = const [],
    this.rows = const [],
    this.grandTotalsByMonth = const [],
    this.grandTotal = 0,
    this.repOptions = const [],
  });

  factory SalesPivotResponse.fromJson(Map<String, dynamic> json) => SalesPivotResponse(
        generated: json['generated'] as bool? ?? false,
        months: (json['months'] as List<dynamic>? ?? []).map((e) => SalesPivotMonth.fromJson(e as Map<String, dynamic>)).toList(),
        rows: (json['rows'] as List<dynamic>? ?? []).map((e) => SalesPivotRow.fromJson(e as Map<String, dynamic>)).toList(),
        grandTotalsByMonth: (json['grandTotalsByMonth'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
        repOptions: (json['repOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}

class SalesPivotInvoice {
  final int qbExtractedId;
  final String? refNumber;
  final DateTime? txnDate;
  final double subtotal;
  final double balanceRemaining;

  SalesPivotInvoice({
    required this.qbExtractedId,
    this.refNumber,
    this.txnDate,
    this.subtotal = 0,
    this.balanceRemaining = 0,
  });

  factory SalesPivotInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v == null ? null : DateTime.tryParse(v as String);
    return SalesPivotInvoice(
      qbExtractedId: json['qbExtractedId'] as int,
      refNumber: (json['refNumber'] as String?)?.trim(),
      txnDate: parseDate(json['txnDate']),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      balanceRemaining: (json['balanceRemaining'] as num?)?.toDouble() ?? 0,
    );
  }
}
