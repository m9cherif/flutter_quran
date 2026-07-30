class HizbQuarter {
  final int hizb;
  final int quarter;
  final int rub;
  final int page;

  const HizbQuarter({
    required this.hizb,
    required this.quarter,
    required this.rub,
    required this.page,
  });

  factory HizbQuarter.fromJson(Map<String, dynamic> json) => HizbQuarter(
    hizb: json['hizb'] as int,
    quarter: json['quarter'] as int,
    rub: json['rub'] as int,
    page: json['page'] as int,
  );
}
