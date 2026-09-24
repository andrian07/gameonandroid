/// Satu baris "kartu stok" waktu tersimpan customer: mutasi IN (waktu disimpan
/// / refund) atau OUT (waktu dipakai buka meja). Sumber: [ApiUrl.customerTimeHistory].
class CustomerTimeHistoryModel {
  final int id;
  final int categoryId;
  final String categoryName;

  /// Jumlah waktu yang bergerak pada baris ini (bukan saldo).
  final Duration amount;

  /// true = IN (nambah), false = OUT (kepakai).
  final bool isIn;

  /// Keterangan bebas dari cabang (mis. "Buka VIP 1", "INV/06/0900001").
  final String? ref;
  final String createdBy;
  final DateTime? at;

  CustomerTimeHistoryModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.isIn,
    required this.ref,
    required this.createdBy,
    required this.at,
  });

  factory CustomerTimeHistoryModel.fromJson(Map<String, dynamic> json) {
    Duration parseHms(dynamic v) {
      final parts = (v?.toString() ?? "").split(":");
      if (parts.length != 3) return Duration.zero;
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(parts[2]) ?? 0,
      );
    }

    DateTime? parseAt() {
      final raw = json['created_at']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final d = DateTime.tryParse(raw.replaceFirst(" ", "T"));
        if (d != null) return d;
      }
      final date = json['date']?.toString() ?? "";
      final time = json['time']?.toString() ?? "00:00:00";
      return DateTime.tryParse("${date}T$time");
    }

    return CustomerTimeHistoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: int.tryParse(json['category_meja_id'].toString()) ?? 0,
      categoryName: json['category_meja_name']?.toString() ?? "-",
      amount: parseHms(json['amount']),
      isIn: (json['movement']?.toString().toUpperCase() ?? "OUT") == "IN",
      ref: (json['ref']?.toString().isNotEmpty ?? false)
          ? json['ref'].toString()
          : null,
      createdBy: json['created_by']?.toString() ?? "",
      at: parseAt(),
    );
  }
}
