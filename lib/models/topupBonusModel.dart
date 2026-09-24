/// Promo "Extra Saldo" yang lagi aktif untuk top up, diambil dari
/// [ApiUrl.topupBonusInfo] (baca tabel topup_bonus_setting - lihat
/// docs/topup_bonus_setting.sql). Periode & nominal bonus diatur admin lewat
/// data, bukan hardcode di app.
class TopupBonusModel {
  final String title;
  final String? description;
  final int bonusAmount;
  final int minTopupAmount;
  final DateTime? startDate;
  final DateTime? endDate;

  const TopupBonusModel({
    required this.title,
    this.description,
    required this.bonusAmount,
    this.minTopupAmount = 0,
    this.startDate,
    this.endDate,
  });

  factory TopupBonusModel.fromJson(Map<String, dynamic> json) {
    return TopupBonusModel(
      title: json['title']?.toString() ?? "Promo Top Up",
      description: (json['description']?.toString().isNotEmpty ?? false)
          ? json['description'].toString()
          : null,
      bonusAmount: int.tryParse(json['bonus_amount'].toString()) ?? 0,
      minTopupAmount: int.tryParse(json['min_topup_amount'].toString()) ?? 0,
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['end_date']?.toString() ?? ''),
    );
  }

  /// True kalau top up sejumlah [amount] memenuhi syarat minimal buat dapat
  /// bonus ini (0 = tanpa syarat minimal).
  bool eligibleFor(int amount) => amount >= minTopupAmount;
}
