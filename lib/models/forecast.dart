class ForecastQuery {
  DateTime? historicalStart;
  DateTime? historicalEnd;
  int horizonDays;
  List<String> locations;
  List<String> itemCodes;
  List<String> suppliers;
  int seasonalityWeight;
  int trendWeight;
  int safetyBufferPercent;

  ForecastQuery({
    this.historicalStart,
    this.historicalEnd,
    this.horizonDays = 30,
    List<String>? locations,
    List<String>? itemCodes,
    List<String>? suppliers,
    this.seasonalityWeight = 50,
    this.trendWeight = 30,
    this.safetyBufferPercent = 10,
  })  : locations = locations ?? [],
        itemCodes = itemCodes ?? [],
        suppliers = suppliers ?? [];

  Map<String, dynamic> toJson() {
    return {
      'historicalStart': historicalStart?.toIso8601String(),
      'historicalEnd': historicalEnd?.toIso8601String(),
      'horizonDays': horizonDays,
      'locations': locations,
      'itemCodes': itemCodes,
      'suppliers': suppliers,
      'seasonalityWeight': seasonalityWeight,
      'trendWeight': trendWeight,
      'safetyBufferPercent': safetyBufferPercent,
    };
  }
}

class ForecastRow {
  final String itemCode;
  final String? uom;
  final double avgMonthlySales;
  final double seasonalityIndex;
  final double trendRatePercent;
  final double forecastQty;
  final int onHand;
  final int pending;
  final int available;
  final int suggestedPoQty;
  final bool limitedHistory;
  final String supplier;

  ForecastRow({
    required this.itemCode,
    this.uom,
    required this.avgMonthlySales,
    required this.seasonalityIndex,
    required this.trendRatePercent,
    required this.forecastQty,
    required this.onHand,
    required this.pending,
    required this.available,
    required this.suggestedPoQty,
    required this.limitedHistory,
    required this.supplier,
  });

  factory ForecastRow.fromJson(Map<String, dynamic> json) {
    return ForecastRow(
      itemCode: json['itemCode'] as String? ?? '',
      uom: (json['uom'] as String?)?.trim(),
      avgMonthlySales: (json['avgMonthlySales'] as num?)?.toDouble() ?? 0,
      seasonalityIndex: (json['seasonalityIndex'] as num?)?.toDouble() ?? 1,
      trendRatePercent: (json['trendRatePercent'] as num?)?.toDouble() ?? 0,
      forecastQty: (json['forecastQty'] as num?)?.toDouble() ?? 0,
      onHand: json['onHand'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      available: json['available'] as int? ?? 0,
      suggestedPoQty: json['suggestedPoQty'] as int? ?? 0,
      limitedHistory: json['limitedHistory'] as bool? ?? false,
      supplier: json['supplier'] as String? ?? 'Unassigned',
    );
  }
}
