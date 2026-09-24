class RewardCategoryModel {
  final int id;
  final String name;
  final String? icon;

  const RewardCategoryModel({required this.id, required this.name, this.icon});

  factory RewardCategoryModel.fromJson(Map<String, dynamic> json) {
    return RewardCategoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }
}

class RewardItemModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String? subtitle;
  final int pointCost;
  final String? image;
  final String? benefitDescription;

  const RewardItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.subtitle,
    required this.pointCost,
    this.image,
    this.benefitDescription,
  });

  factory RewardItemModel.fromJson(Map<String, dynamic> json) {
    return RewardItemModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      categoryName: json['category_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      pointCost: int.tryParse(json['point_cost'].toString()) ?? 0,
      image: json['image']?.toString(),
      benefitDescription: json['benefit_description']?.toString(),
    );
  }
}

class RewardRedemptionResult {
  final String redeemCode;
  final String rewardName;
  final int pointSpent;
  final String? benefitDescription;

  const RewardRedemptionResult({
    required this.redeemCode,
    required this.rewardName,
    required this.pointSpent,
    this.benefitDescription,
  });

  factory RewardRedemptionResult.fromJson(Map<String, dynamic> json) {
    return RewardRedemptionResult(
      redeemCode: json['redeem_code']?.toString() ?? '',
      rewardName: json['reward_name']?.toString() ?? '',
      pointSpent: int.tryParse(json['point_spent'].toString()) ?? 0,
      benefitDescription: json['benefit_description']?.toString(),
    );
  }
}

// 1 baris riwayat hadiah yang sudah pernah ditukar (dari GET /apimobile/reward_redemptions) -
// beda dari RewardRedemptionResult (hasil langsung setelah 1x tukar) karena punya status & tanggal.
class RewardRedemptionModel {
  final int id;
  final String rewardName;
  final int pointSpent;
  final String status;
  final String redeemCode;
  final String? image;
  final DateTime? createdAt;

  const RewardRedemptionModel({
    required this.id,
    required this.rewardName,
    required this.pointSpent,
    required this.status,
    required this.redeemCode,
    this.image,
    required this.createdAt,
  });

  factory RewardRedemptionModel.fromJson(Map<String, dynamic> json) {
    return RewardRedemptionModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      rewardName: json['reward_name']?.toString() ?? '-',
      pointSpent: int.tryParse(json['point_spent'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'Redeemed',
      redeemCode: json['redeem_code']?.toString() ?? '',
      image: json['image']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
