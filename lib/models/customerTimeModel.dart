/// Saldo waktu bermain milik customer, dipecah per kategori room/meja.
/// Sumber: endpoint [ApiUrl.customerTime].
class CustomerTimeModel {
  final int categoryId;
  final String categoryName;
  final int remainingMinutes;

  CustomerTimeModel({
    required this.categoryId,
    required this.categoryName,
    required this.remainingMinutes,
  });

  factory CustomerTimeModel.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['category_id'] ?? json['room_category_id'] ?? json['id'];
    final rawName = json['category_name'] ??
        json['room_category'] ??
        json['category'] ??
        json['name'];
    final rawMinutes = json['remaining_minutes'] ??
        json['minutes'] ??
        json['time'] ??
        json['customer_time'];

    return CustomerTimeModel(
      categoryId: int.tryParse(rawId.toString()) ?? 0,
      categoryName: rawName?.toString() ?? '',
      remainingMinutes: int.tryParse(rawMinutes.toString()) ?? 0,
    );
  }
}
