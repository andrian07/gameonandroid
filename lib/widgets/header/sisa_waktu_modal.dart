import 'package:flutter/material.dart';

import '../../core/api/apiService.dart';
import '../../core/api/apiUrl.dart';
import '../../core/storage/sessionManager.dart';
import '../../models/customerTimeModel.dart';
import 'time_history_modal.dart';

/// Warna aksen per baris kategori. Backend tidak mengirim warna, jadi dipilih
/// berurutan dari palet ini.
const _palette = [
  Color(0xffFF6B4D),
  Color(0xff2ED573),
  Color(0xffF6B91A),
  Color(0xffC9A66B),
  Color(0xff46A8FF),
  Color(0xffB673FF),
];

String _formatDuration(Duration value) {
  final clamped = value.isNegative ? Duration.zero : value;
  final hours = clamped.inHours;
  final minutes = clamped.inMinutes.remainder(60);
  final seconds = clamped.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  return "${two(hours)}:${two(minutes)}:${two(seconds)}";
}

/// Menampilkan bottom sheet "Waktu Disimpan": saldo waktu customer dipecah
/// per kategori meja, diambil dari [ApiUrl.customerTime].
void showSisaWaktuModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _SisaWaktuSheet(),
  );
}

class _SisaWaktuSheet extends StatefulWidget {
  const _SisaWaktuSheet();

  @override
  State<_SisaWaktuSheet> createState() => _SisaWaktuSheetState();
}

class _SisaWaktuSheetState extends State<_SisaWaktuSheet> {
  late final Future<List<CustomerTimeModel>> _future = _load();

  Future<List<CustomerTimeModel>> _load() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw Exception("Sesi habis, silakan login ulang.");
    }

    final response = await ApiService().postAuth(ApiUrl.customerTime, {}, token);
    if (response["code"] == 200 && response["result"] is List) {
      return (response["result"] as List)
          .map((e) => CustomerTimeModel.fromJson(e))
          .toList();
    }
    // code != 200 atau bentuk tidak sesuai -> jangan tampil sebagai "kosong".
    final message = response["result"]?.toString() ?? "Gagal memuat data.";
    throw Exception(message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xff1F1B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: FutureBuilder<List<CustomerTimeModel>>(
          future: _future,
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting;
            final items = snapshot.data ?? const <CustomerTimeModel>[];
            final total = items.fold(
              Duration.zero,
              (sum, item) => sum + Duration(minutes: item.remainingMinutes),
            );

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                        ),
                      ),
                      child: const Icon(Icons.timer_rounded,
                          color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Waktu Disimpan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      loading ? "--:--:--" : _formatDuration(total),
                      style: const TextStyle(
                        color: Color(0xffB673FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showTimeHistoryModal(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xffB673FF),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text(
                      "Lihat Riwayat",
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        "Gagal memuat waktu tersimpan.\nCoba lagi nanti.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        "Belum ada waktu tersimpan",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final remaining = Duration(minutes: item.remainingMinutes);
                    final active = remaining > Duration.zero;
                    final color = _palette[index % _palette.length];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1 ? 0 : 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withOpacity(.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.sports_esports_rounded,
                                color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.categoryName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  active ? "Aktif" : "Habis",
                                  style: TextStyle(
                                    color: active
                                        ? const Color(0xff2ED573)
                                        : Colors.white.withOpacity(.4),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatDuration(remaining),
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : Colors.white.withOpacity(.35),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
