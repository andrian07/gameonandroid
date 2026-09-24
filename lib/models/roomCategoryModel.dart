class RoomCategoryModel {
  final int id;
  final String name;
  final String? image;
  final int? price;
  final String? durationLabel;

  RoomCategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.price,
    this.durationLabel,
  });

  factory RoomCategoryModel.fromJson(Map<String, dynamic> json) {
    return RoomCategoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      price: json['price'] == null ? null : int.tryParse(json['price'].toString()),
      durationLabel: json['duration_label']?.toString(),
    );
  }
}
