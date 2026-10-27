class ClinicAccount {
  final String id;
  final String? userName;
  final String? email;
  final String? fullname;
  final int? points;
  final int? spendpoints;
  final int badgeavailedpoints;
  final bool isrestricted;
  final String? salesRepCode;
  final int resetLinkCount;

  ClinicAccount({
    required this.id,
    this.userName,
    this.email,
    this.fullname,
    this.points,
    this.spendpoints,
    this.badgeavailedpoints = 0,
    this.isrestricted = false,
    this.salesRepCode,
    this.resetLinkCount = 0,
  });

  factory ClinicAccount.fromJson(Map<String, dynamic> json) => ClinicAccount(
        id: json['id'] as String,
        userName: json['userName'] as String?,
        email: json['email'] as String?,
        fullname: json['fullname'] as String?,
        points: json['points'] as int?,
        spendpoints: json['spendpoints'] as int?,
        badgeavailedpoints: json['badgeavailedpoints'] as int? ?? 0,
        isrestricted: json['isrestricted'] as bool? ?? false,
        salesRepCode: (json['salesRepCode'] as String?)?.trim(),
        resetLinkCount: json['resetLinkCount'] as int? ?? 0,
      );

  String get displayName => (fullname?.isNotEmpty ?? false) ? fullname! : (userName ?? '');

  int get availablePoints => (points ?? 0) - badgeavailedpoints;
}

class ClinicAccountListResponse {
  final List<ClinicAccount> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final bool repFilterLocked;

  ClinicAccountListResponse({
    required this.items,
    this.page = 1,
    this.pageSize = 25,
    this.totalItems = 0,
    this.repFilterLocked = false,
  });

  int get totalPages => totalItems == 0 ? 1 : ((totalItems + pageSize - 1) ~/ pageSize);

  factory ClinicAccountListResponse.fromJson(Map<String, dynamic> json) => ClinicAccountListResponse(
        items: (json['items'] as List<dynamic>? ?? []).map((e) => ClinicAccount.fromJson(e as Map<String, dynamic>)).toList(),
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 25,
        totalItems: json['totalItems'] as int? ?? 0,
        repFilterLocked: json['repFilterLocked'] as bool? ?? false,
      );
}
