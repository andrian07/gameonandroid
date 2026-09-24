import 'package:flutter/material.dart';

import '../../core/api/apiService.dart';
import '../../core/api/apiUrl.dart';
import '../../core/storage/sessionManager.dart';
import '../../models/customerTimeHistoryModel.dart';

/// Bottom sheet "Riwayat Waktu Tersimpan": kartu stok mutasi waktu member -
/// IN (disimpan / refund) & OUT (dipakai buka meja), terbaru dulu.
/// Diambil dari [ApiUrl.customerTimeHistory].
void showTimeHistoryModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TimeHistorySheet(),
  );
}

String _fmtDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  String two(int n) => n.toString().padLeft(2, '0');
  return "${two(h)}:${two(m)}:${two(s)}";
}

const _months = [
  "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
  "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
];

String _fmtWhen(DateTime? at) {
  if (at == null) return "";
  String two(int n) => n.toString().padLeft(2, '0');
  return "${at.day} ${_months[at.month - 1]} ${at.year} • ${two(at.hour)}:${two(at.minute)}";
}

class _TimeHistorySheet extends StatefulWidget {
  const _TimeHistorySheet();

  @override
  State<_TimeHistorySheet> createState() => _TimeHistorySheetState();
}

class _TimeHistorySheetState extends State<_TimeHistorySheet> {
  late final Future<List<CustomerTimeHistoryModel>> _future = _load();

  Future<List<CustomerTimeHistoryModel>> _load() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw Exception("Sesi habis, silakan login ulang.");
    }
    final res = await ApiService().postAuth(
      ApiUrl.customerTimeHistory,
      {"page": 1, "per_page": 50},
      token,
    );
    if (res is Map && res["code"] == 200 && res["result"] is Map) {
      final data = (res["result"] as Map)["data"];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) =>
                CustomerTimeHistoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return const [];
    }
    throw Exception(res is Map
        ? (res["result"]?.toString() ?? "Gagal memuat riwayat.")
        : "Gagal memuat riwayat.");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xff1F1B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
                  child: const Icon(Icons.history_rounded,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Riwayat Waktu Tersimpan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<CustomerTimeHistoryModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _msg("Gagal memuat riwayat.\nCoba lagi nanti.");
                  }
                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return _msg("Belum ada riwayat waktu tersimpan");
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 18,
                      color: Colors.white.withOpacity(.06),
                    ),
                    itemBuilder: (_, i) => _row(items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _msg(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 13),
          ),
        ),
      );

  Widget _row(CustomerTimeHistoryModel h) {
    final color = h.isIn ? const Color(0xff2ED573) : const Color(0xffFF6B4D);
    final sign = h.isIn ? "+" : "−";
    final when = _fmtWhen(h.at);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            h.isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (h.ref != null) h.ref!,
                  if (when.isNotEmpty) when,
                ].join("  •  "),
                style: TextStyle(
                  color: Colors.white.withOpacity(.45),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "$sign${_fmtDuration(h.amount)}",
          style: TextStyle(
            color: color,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
