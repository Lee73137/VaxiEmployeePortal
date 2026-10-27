class SalesSummaryYearAmounts {
  final int year;
  final List<double> monthlyAmounts;

  SalesSummaryYearAmounts({required this.year, this.monthlyAmounts = const []});

  factory SalesSummaryYearAmounts.fromJson(Map<String, dynamic> json) => SalesSummaryYearAmounts(
        year: json['year'] as int,
        monthlyAmounts: (json['monthlyAmounts'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
      );
}

class SalesSummaryRow {
  final String? salesRep;
  final String? location;
  final String customerName;
  final List<SalesSummaryYearAmounts> monthlySalesByYear;
  final double rowTotal;

  SalesSummaryRow({
    this.salesRep,
    this.location,
    required this.customerName,
    this.monthlySalesByYear = const [],
    this.rowTotal = 0,
  });

  factory SalesSummaryRow.fromJson(Map<String, dynamic> json) => SalesSummaryRow(
        salesRep: json['salesRep'] as String?,
        location: json['location'] as String?,
        customerName: json['customerName'] as String? ?? '',
        monthlySalesByYear: (json['monthlySalesByYear'] as List<dynamic>? ?? []).map((e) => SalesSummaryYearAmounts.fromJson(e as Map<String, dynamic>)).toList(),
        rowTotal: (json['rowTotal'] as num?)?.toDouble() ?? 0,
      );
}

class SalesSummaryResponse {
  final bool generated;
  final int year;
  final List<int> years;
  final List<SalesSummaryRow> rows;
  final List<SalesSummaryYearAmounts> grandTotalsByYear;
  final List<String> repOptions;
  final List<String> locationOptions;

  SalesSummaryResponse({
    this.generated = false,
    this.year = 0,
    this.years = const [],
    this.rows = const [],
    this.grandTotalsByYear = const [],
    this.repOptions = const [],
    this.locationOptions = const [],
  });

  factory SalesSummaryResponse.fromJson(Map<String, dynamic> json) => SalesSummaryResponse(
        generated: json['generated'] as bool? ?? false,
        year: json['year'] as int? ?? 0,
        years: (json['years'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
        rows: (json['rows'] as List<dynamic>? ?? []).map((e) => SalesSummaryRow.fromJson(e as Map<String, dynamic>)).toList(),
        grandTotalsByYear: (json['grandTotalsByYear'] as List<dynamic>? ?? []).map((e) => SalesSummaryYearAmounts.fromJson(e as Map<String, dynamic>)).toList(),
        repOptions: (json['repOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        locationOptions: (json['locationOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      );
}
