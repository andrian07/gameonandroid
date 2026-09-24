import 'package:flutter/material.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../models/customerTimeHistoryModel.dart';
import '../widgets/appSnackbar.dart';
import '../widgets/footer/custom_bottom_nav.dart';

enum _HistoryType { saldo, point, waktu }

enum _Movement { inFlow, outFlow }

/// Kategori baris riwayat: main = sesi billing, cafe = pesanan cafe,
/// saldo = top up/refund, point = mutasi point, waktu = simpan/pakai
/// Waktu Disimpan (dari /apimobile/customer_time_history).
enum _HistoryCat { main, cafe, saldo, point, waktu }

class _CafeLine {
  final String name;
  final int qty;
  final int subtotal;
  final String? note;

  const _CafeLine({
    required this.name,
    required this.qty,
    required this.subtotal,
    this.note,
  });

  factory _CafeLine.fromJson(Map<String, dynamic> j) => _CafeLine(
        name: j['name']?.toString() ?? '-',
        qty: int.tryParse(j['qty'].toString()) ?? 1,
        subtotal: int.tryParse(j['sub_total'].toString()) ?? 0,
        note: (j['note']?.toString().isNotEmpty ?? false) ? j['note'].toString() : null,
      );
}

class _HistoryItem {
  final _HistoryCat cat;
  final _Movement movement;
  final int amount;
  final String description;
  final DateTime? createdAt;

  // Detail sesi main / cafe (opsional, dari branch_transaction*).
  final int? durationMinutes; // lama main
  final String? promo; // nama promo yang dipakai, null kalau tanpa promo
  final String? unitName; // "Meja N"
  final String? startClock; // jam mulai "HH:MM"
  final String? endClock; // jam selesai "HH:MM"
  final DateTime? sessionDate; // tanggal main/pesanan
  final String? paymentName; // "Saldo" / "Cash" / dll
  final String? invoice;
  final List<_CafeLine> items; // isi pesanan cafe

  // Sesi yang dibayar pakai sisa "Waktu Disimpan" (lihat sisa_waktu_modal.dart)
  // alih-alih saldo/cash. Sejalan dengan billing_report_page.dart di app kasir.
  final bool usedSavedTime;
  final int? savedTimeValue; // nilai tagihan seharusnya kalau tidak pakai waktu disimpan

  // Khusus cat == waktu (dari /apimobile/customer_time_history): jumlah waktu
  // yang bergerak & keterangan bebas dari cabang. `amount`/`durationMinutes`
  // di atas tidak dipakai untuk baris ini.
  final Duration? timeAmount;
  final String? timeRef;

  const _HistoryItem({
    required this.cat,
    required this.movement,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.durationMinutes,
    this.promo,
    this.unitName,
    this.startClock,
    this.endClock,
    this.sessionDate,
    this.paymentName,
    this.invoice,
    this.items = const [],
    this.usedSavedTime = false,
    this.timeAmount,
    this.timeRef,
    this.savedTimeValue,
  });

  factory _HistoryItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final rawDuration = json['duration_minutes'] ?? json['duration'];
    final rawPromo = (json['promo'] ?? json['promo_name'])?.toString();
    final rawUnit = (json['unit_name'] ?? json['unit'])?.toString();
    final rawPayment = (json['payment'] ?? json['payment_name'])?.toString();
    final rawItems = json['items'];

    _HistoryCat cat;
    switch (json['type']?.toString()) {
      case 'main':
        cat = _HistoryCat.main;
        break;
      case 'cafe':
        cat = _HistoryCat.cafe;
        break;
      case 'point':
        cat = _HistoryCat.point;
        break;
      default:
        cat = _HistoryCat.saldo;
    }

    return _HistoryItem(
      cat: cat,
      movement: json['movement'] == 'OUT' ? _Movement.outFlow : _Movement.inFlow,
      amount: rawAmount is int ? rawAmount : int.tryParse(rawAmount.toString()) ?? 0,
      description: json['description']?.toString() ?? '-',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      durationMinutes:
          rawDuration == null ? null : int.tryParse(rawDuration.toString()),
      promo: (rawPromo == null || rawPromo.isEmpty) ? null : rawPromo,
      unitName: (rawUnit == null || rawUnit.isEmpty) ? null : rawUnit,
      startClock: _clock(json['start_time']),
      endClock: _clock(json['end_time']),
      sessionDate: DateTime.tryParse(json['date']?.toString() ?? ''),
      paymentName:
          (rawPayment == null || rawPayment.isEmpty) ? null : rawPayment,
      invoice: json['invoice']?.toString(),
      usedSavedTime: json['used_saved_time'] == true ||
          json['saved_time_value'] != null,
      savedTimeValue: json['saved_time_value'] == null
          ? null
          : int.tryParse(json['saved_time_value'].toString()),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => _CafeLine.fromJson(e.cast<String, dynamic>()))
              .toList()
          : const [],
    );
  }

  /// Baris "kartu stok" waktu tersimpan (/apimobile/customer_time_history)
  /// diperlakukan sebagai baris riwayat biasa supaya bisa digabung & diurutkan
  /// kronologis bersama saldo/point/sesi main di satu list yang sama.
  factory _HistoryItem.fromTimeHistory(CustomerTimeHistoryModel m) {
    return _HistoryItem(
      cat: _HistoryCat.waktu,
      movement: m.isIn ? _Movement.inFlow : _Movement.outFlow,
      amount: 0,
      description: m.isIn
          ? "Simpan Waktu ${m.categoryName}"
          : "Pakai Waktu Disimpan ${m.categoryName}",
      createdAt: m.at,
      unitName: m.categoryName,
      timeAmount: m.amount,
      timeRef: m.ref,
    );
  }

  // "13:00:00" / "2026-09-02 13:00:00" -> "13:00"
  static String? _clock(dynamic raw) {
    final s = raw?.toString() ?? '';
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
    if (m == null) return null;
    return "${m.group(1)!.padLeft(2, '0')}:${m.group(2)}";
  }

  /// Untuk pewarnaan & ikon: main & cafe diperlakukan seperti saldo (uang).
  _HistoryType get type => switch (cat) {
        _HistoryCat.point => _HistoryType.point,
        _HistoryCat.waktu => _HistoryType.waktu,
        _ => _HistoryType.saldo,
      };

  bool get hasPlayDetail =>
      cat != _HistoryCat.waktu &&
      (durationMinutes != null ||
          promo != null ||
          unitName != null ||
          startClock != null ||
          paymentName != null ||
          usedSavedTime);

  /// Sejalan dengan _keteranganLabel di billing_report_page.dart (app kasir).
  String get savedTimeLabel {
    if (!usedSavedTime) return "-";
    final value = savedTimeValue;
    if (value == null) return "Bayar pakai sisa waktu";
    return "Bayar pakai sisa waktu (senilai ${_formatRupiah(value)})";
  }
}

// Halaman ini menampilkan riwayat AKTIVITAS akun (saldo masuk/keluar & point yang didapat) - data asli
// dari gameon (POST /apimobile/history). Sengaja BUKAN daftar sesi main per unit/meja (mis. "PS5 VVIP 2
// Jam") - itu belum ada sumber datanya (belum disinkronkan dari billing_api cabang ke gameon).
class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  bool _loading = true;
  String? _error;
  List<_HistoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _error = 'Sesi login tidak ditemukan, silakan login ulang.';
          _loading = false;
        });
        return;
      }

      final response = await ApiService().postAuth(ApiUrl.history, {}, token);
      if (response['code'] == 200 && response['result'] is List) {
        final items = (response['result'] as List)
            .whereType<Map<String, dynamic>>()
            .map(_HistoryItem.fromJson)
            .toList();

        // Gabung dengan riwayat simpan/pakai Waktu Disimpan supaya tampil
        // kronologis di list yang sama. Best-effort: kalau endpoint ini
        // gagal, riwayat saldo/point di atas tetap tampil seperti biasa.
        items.addAll(await _loadTimeHistory(token));
        items.sort((a, b) {
          final da = a.createdAt;
          final db = b.createdAt;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });

        if (!mounted) return;
        setState(() {
          _items = items;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = response['result']?.toString() ?? 'Gagal memuat riwayat';
          _loading = false;
        });
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, e.message, isError: true);
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Server sedang gangguan, silakan coba lagi.';
        _loading = false;
      });
    }
  }

  /// Ambil riwayat mutasi Waktu Disimpan. Best-effort: error di sini tidak
  /// menggagalkan halaman, cukup baris "waktu" saja yang tidak muncul.
  Future<List<_HistoryItem>> _loadTimeHistory(String token) async {
    try {
      final res = await ApiService().postAuth(
        ApiUrl.customerTimeHistory,
        {"page": 1, "per_page": 100},
        token,
      );
      if (res is Map && res['code'] == 200 && res['result'] is Map) {
        final data = (res['result'] as Map)['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => _HistoryItem.fromTimeHistory(
                  CustomerTimeHistoryModel.fromJson(
                      Map<String, dynamic>.from(e))))
              .toList();
        }
      }
    } catch (_) {
      // diamkan - lihat komentar di atas.
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(initialIndex: 3),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "Riwayat Aktivitas",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(.3), size: 40),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(.2)),
              ),
              child: const Text("Coba Lagi"),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.history_rounded, color: Colors.white.withOpacity(.25), size: 40),
          const SizedBox(height: 12),
          Text(
            "Belum ada aktivitas",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 13),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _HistoryTile(
        data: _items[index],
        onTap: () => _showDetail(context, _items[index]),
      ),
    );
  }

  void _showDetail(BuildContext context, _HistoryItem data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HistoryDetailSheet(data: data),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final _HistoryItem data;
  final VoidCallback? onTap;

  const _HistoryTile({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIn = data.movement == _Movement.inFlow;

    final accentColor = isIn ? const Color(0xff2ED573) : const Color(0xffFF5A71);
    final icon = switch (data.type) {
      _HistoryType.waktu => Icons.timer_rounded,
      _HistoryType.point => Icons.star_rounded,
      _HistoryType.saldo => isIn
          ? Icons.account_balance_wallet_rounded
          : Icons.shopping_bag_rounded,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff1B1836), Color(0xff141227)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cleanDescription(data.description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(data.createdAt),
                      style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                switch (data.type) {
                  _HistoryType.waktu =>
                    "${isIn ? '+' : '-'}${_formatDuration((data.timeAmount ?? Duration.zero).inMinutes)}",
                  _HistoryType.point => "${isIn ? '+' : '-'}${data.amount} pt",
                  _HistoryType.saldo =>
                    "${isIn ? '+' : '-'}${_formatRupiah(data.amount)}",
                },
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(.25),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popup detail 1 baris riwayat aktivitas (muncul saat kartu ditekan).
class _HistoryDetailSheet extends StatelessWidget {
  final _HistoryItem data;

  const _HistoryDetailSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final isIn = data.movement == _Movement.inFlow;

    // OUT selalu merah, IN selalu hijau.
    final accentColor = isIn ? const Color(0xff2ED573) : const Color(0xffFF5A71);

    IconData icon;
    String typeLabel;
    switch (data.cat) {
      case _HistoryCat.main:
        icon = Icons.sports_esports_rounded;
        typeLabel = "SESI MAIN";
        break;
      case _HistoryCat.cafe:
        icon = Icons.local_cafe_rounded;
        typeLabel = "PESANAN CAFE";
        break;
      case _HistoryCat.point:
        icon = Icons.star_rounded;
        typeLabel = isIn ? "POINT MASUK" : "POINT KELUAR";
        break;
      case _HistoryCat.waktu:
        icon = Icons.timer_rounded;
        typeLabel = isIn ? "WAKTU DISIMPAN" : "WAKTU DIPAKAI";
        break;
      case _HistoryCat.saldo:
        icon = isIn
            ? Icons.account_balance_wallet_rounded
            : Icons.shopping_bag_rounded;
        typeLabel = isIn ? "SALDO MASUK" : "SALDO KELUAR";
        break;
    }

    final amountLabel = switch (data.type) {
      _HistoryType.waktu =>
        "${isIn ? '+ ' : '- '}${_formatDuration((data.timeAmount ?? Duration.zero).inMinutes)}",
      _HistoryType.point => "${isIn ? '+ ' : '- '}${data.amount} pt",
      _HistoryType.saldo => "${isIn ? '+ ' : '- '}${_formatRupiah(data.amount)}",
    };

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff211B3B), Color(0xff120F22)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ---- Ringkasan nominal ----------------------------------------
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(.3)),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        amountLabel,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              // Deskripsi lengkap (tidak dipotong seperti di kartu list) agar
              // keterangan tambahan, mis. "(Simpan waktu 15 menit)", ikut tampil.
              data.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // ---- Kartu: Sesi Main / Pesanan Cafe -----------------------
            if (data.hasPlayDetail) _buildSessionCard(),
            if (data.hasPlayDetail) const SizedBox(height: 12),

            // ---- Kartu: Isi pesanan cafe ------------------------------
            if (data.items.isNotEmpty) _buildItemsCard(),
            if (data.items.isNotEmpty) const SizedBox(height: 12),

            // ---- Kartu: Rincian transaksi ----------------------------
            _card(
              title: "Rincian Transaksi",
              children: [
                _row(
                  "Jenis",
                  switch (data.cat) {
                    _HistoryCat.main => "Sesi Main",
                    _HistoryCat.cafe => "Pesanan Cafe",
                    _HistoryCat.point => "Point",
                    _HistoryCat.waktu => "Waktu Disimpan",
                    _HistoryCat.saldo => "Saldo",
                  },
                ),
                _row(
                  "Jumlah",
                  switch (data.type) {
                    _HistoryType.waktu => _formatDuration(
                        (data.timeAmount ?? Duration.zero).inMinutes),
                    _HistoryType.point => "${data.amount} poin",
                    _HistoryType.saldo => _formatRupiah(data.amount),
                  },
                  valueColor: accentColor,
                ),
                if (data.cat == _HistoryCat.waktu && data.unitName != null)
                  _row("Kategori Meja", data.unitName!),
                if (data.cat == _HistoryCat.waktu && data.timeRef != null)
                  _row("Keterangan", data.timeRef!),
                if (data.paymentName != null)
                  _row("Metode Bayar", data.paymentName!),
                if (data.invoice != null && data.invoice!.isNotEmpty)
                  _row("Invoice", data.invoice!),
                _row("Tanggal", _formatDateOnly(data.createdAt)),
                _row("Jam", _formatTime(data.createdAt), last: true),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  // Kartu "Sesi Main" / "Pesanan Cafe": jam mulai -> selesai, durasi, meja, promo.
  Widget _buildSessionCard() {
    final isCafe = data.cat == _HistoryCat.cafe;
    final hasRange = data.startClock != null && data.endClock != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xff9D4DFF).withOpacity(.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCafe
                    ? Icons.receipt_long_rounded
                    : Icons.sports_esports_rounded,
                color: const Color(0xffB98CFF),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isCafe ? "Info Pesanan" : "Sesi Main",
                style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasRange) ...[
            Row(
              children: [
                _timeBlock("Mulai", data.startClock!),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        data.durationMinutes != null
                            ? _formatDuration(data.durationMinutes!)
                            : "",
                        style: const TextStyle(
                          color: Color(0xffB98CFF),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(child: _dottedLine()),
                          const Icon(Icons.arrow_right_alt_rounded,
                              color: Color(0xffB98CFF), size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
                _timeBlock("Selesai", data.endClock!, alignEnd: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateOnly(data.sessionDate ?? data.createdAt),
              style: TextStyle(
                  color: Colors.white.withOpacity(.4), fontSize: 10.5),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(.08), height: 1),
            const SizedBox(height: 6),
          ],

          if (!hasRange && data.durationMinutes != null)
            _row("Durasi", _formatDuration(data.durationMinutes!)),
          if (data.unitName != null)
            _row(isCafe ? "Meja" : "Ruangan / Unit", data.unitName!),
          _row("Promo", data.promo ?? "Tanpa promo",
              last: !data.usedSavedTime),
          if (data.usedSavedTime)
            _row("Keterangan", data.savedTimeLabel, last: true),
        ],
      ),
    );
  }

  // Kartu daftar item pesanan cafe.
  Widget _buildItemsCard() {
    return _card(
      title: "Isi Pesanan",
      children: [
        for (int i = 0; i < data.items.length; i++)
          _itemLine(data.items[i], last: i == data.items.length - 1),
      ],
    );
  }

  Widget _itemLine(_CafeLine it, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 6 : 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${it.qty}x",
                style: const TextStyle(
                  color: Color(0xffB98CFF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (it.note != null)
                      Text(
                        it.note!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.45),
                          fontSize: 10.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatRupiah(it.subtotal),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white.withOpacity(.06), height: 1),
            ),
        ],
      ),
    );
  }

  Widget _timeBlock(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _dottedLine() {
    return LayoutBuilder(
      builder: (context, c) {
        final count = (c.maxWidth / 6).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count < 1 ? 1 : count,
            (_) => Container(
              width: 3,
              height: 1.5,
              color: Colors.white.withOpacity(.18),
            ),
          ),
        );
      },
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(.85),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor, bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 6 : 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: Colors.white.withOpacity(.5), fontSize: 12.5),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!last)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white.withOpacity(.06), height: 1),
            ),
        ],
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return "${_formatDateOnly(date)}, ${_formatTime(date)}";
}

String _formatDateOnly(DateTime? date) {
  if (date == null) return '-';
  return "${date.day} ${_months[date.month - 1]} ${date.year}";
}

String _formatTime(DateTime? date) {
  if (date == null) return '-';
  return "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";
}

String _formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromRight = digits.length - i;
    buffer.write(digits[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
  }
  return "Rp$buffer";
}

String _formatDuration(int minutes) {
  if (minutes <= 0) return '-';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m Menit';
  if (m == 0) return '$h Jam';
  return '$h Jam $m Menit';
}

/// Buang kode di dalam kurung dari deskripsi, mis.
/// "Bayar pakai saldo (branch1-saldo-6a97...)" -> "Bayar pakai saldo".
String _cleanDescription(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'\s*\([^()]*\)'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  return cleaned.isEmpty ? raw.trim() : cleaned;
}
