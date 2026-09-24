class UserModel {
  final int id;
  final String idNumber;
  final String name;
  final String phone;
  final String address;
  final String email;
  final num saldo;
  final int point;
  final String verification;
  final String createdAt;
  final bool hasPin;
  final int timeRemainingMinutes;

  UserModel({
    required this.id,
    required this.idNumber,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.saldo,
    required this.point,
    required this.verification,
    required this.createdAt,
    this.hasPin = false,
    this.timeRemainingMinutes = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      idNumber: json['id_number']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      saldo: num.tryParse(json['saldo'].toString()) ?? 0,
      point: int.tryParse(json['point'].toString()) ?? 0,
      verification: json['verification']?.toString() ?? 'N',
      createdAt: json['created_at']?.toString() ?? '',
      hasPin: json['has_pin'] == true,
      timeRemainingMinutes: int.tryParse(json['time_remaining_minutes'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_number': idNumber,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'saldo': saldo,
      'point': point,
      'verification': verification,
      'created_at': createdAt,
      'has_pin': hasPin,
      'time_remaining_minutes': timeRemainingMinutes,
    };
  }

  UserModel copyWith({bool? hasPin, int? point}) {
    return UserModel(
      id: id,
      idNumber: idNumber,
      name: name,
      phone: phone,
      address: address,
      email: email,
      saldo: saldo,
      point: point ?? this.point,
      verification: verification,
      createdAt: createdAt,
      hasPin: hasPin ?? this.hasPin,
      timeRemainingMinutes: timeRemainingMinutes,
    );
  }
}
