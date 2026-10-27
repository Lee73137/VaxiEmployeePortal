class PerformanceMonthCell {
  final double? sale;
  final int actualVisits;
  final int virtualVisits;

  PerformanceMonthCell({this.sale, this.actualVisits = 0, this.virtualVisits = 0});

  factory PerformanceMonthCell.fromJson(Map<String, dynamic> json) => PerformanceMonthCell(
        sale: (json['sale'] as num?)?.toDouble(),
        actualVisits: json['actualVisits'] as int? ?? 0,
        virtualVisits: json['virtualVisits'] as int? ?? 0,
      );
}

class PerformanceRow {
  final String clinicName;
  final String? location;
  final String? repCode;
  final List<PerformanceMonthCell> months;
  final double grandTotal;

  PerformanceRow({
    required this.clinicName,
    this.location,
    this.repCode,
    this.months = const [],
    this.grandTotal = 0,
  });

  factory PerformanceRow.fromJson(Map<String, dynamic> json) => PerformanceRow(
        clinicName: json['clinicName'] as String? ?? '',
        location: json['location'] as String?,
        repCode: (json['repCode'] as String?)?.trim(),
        months: (json['months'] as List<dynamic>? ?? []).map((e) => PerformanceMonthCell.fromJson(e as Map<String, dynamic>)).toList(),
        grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      );
}

class PerformanceResponse {
  final bool generated;
  final int year;
  final List<PerformanceRow> rows;
  final double totalSales;
  final int totalActualVisits;
  final int totalVirtualVisits;
  final int clinicCount;
  final double coveragePercent;

  /// Monthly Sales Trend chart: Jan-Dec combined total, one Jan-Dec series
  /// per rep, and each rep's monthly target.
  final List<double> monthlySalesTotals;
  final Map<String, List<double>> monthlySalesByRep;
  final Map<String, double> targetMonthByRep;
  final bool repFilterLocked;
  final List<String> repOptions;
  final List<String> locationOptions;
  final List<int> yearOptions;

  PerformanceResponse({
    this.generated = false,
    this.year = 0,
    this.rows = const [],
    this.totalSales = 0,
    this.totalActualVisits = 0,
    this.totalVirtualVisits = 0,
    this.clinicCount = 0,
    this.coveragePercent = 0,
    this.monthlySalesTotals = const [],
    this.monthlySalesByRep = const {},
    this.targetMonthByRep = const {},
    this.repFilterLocked = false,
    this.repOptions = const [],
    this.locationOptions = const [],
    this.yearOptions = const [],
  });

  factory PerformanceResponse.fromJson(Map<String, dynamic> json) => PerformanceResponse(
        generated: json['generated'] as bool? ?? false,
        year: json['year'] as int? ?? 0,
        rows: (json['rows'] as List<dynamic>? ?? []).map((e) => PerformanceRow.fromJson(e as Map<String, dynamic>)).toList(),
        totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
        totalActualVisits: json['totalActualVisits'] as int? ?? 0,
        totalVirtualVisits: json['totalVirtualVisits'] as int? ?? 0,
        clinicCount: json['clinicCount'] as int? ?? 0,
        coveragePercent: (json['coveragePercent'] as num?)?.toDouble() ?? 0,
        monthlySalesTotals: (json['monthlySalesTotals'] as List<dynamic>? ?? []).map((e) => (e as num).toDouble()).toList(),
        monthlySalesByRep: (json['monthlySalesByRep'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as List<dynamic>).map((e) => (e as num).toDouble()).toList()),
        ),
        targetMonthByRep: (json['targetMonthByRep'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
        repFilterLocked: json['repFilterLocked'] as bool? ?? false,
        repOptions: (json['repOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        locationOptions: (json['locationOptions'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
        yearOptions: (json['yearOptions'] as List<dynamic>? ?? []).map((e) => e as int).toList(),
      );
}

class ClinicVisitRemark {
  final DateTime arrivalTime;
  final String? remarks;

  ClinicVisitRemark({required this.arrivalTime, this.remarks});

  factory ClinicVisitRemark.fromJson(Map<String, dynamic> json) => ClinicVisitRemark(
        arrivalTime: DateTime.tryParse(json['arrivalTime'] as String? ?? '') ?? DateTime.now(),
        remarks: json['remarks'] as String?,
      );
}
