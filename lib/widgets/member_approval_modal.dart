import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';

/// Modal konfirmasi pembayaran: muncul saat kasir menekan bayar "Potong Saldo"
/// dengan akun member ini. Member wajib menyetujui dengan PIN (atau menolak /
/// dibiarkan kadaluarsa). Tidak bisa ditutup dengan back / tap di luar.
///
/// [approval] = 1 item dari /apimobile/pending_approvals:
///   { id, ref, type, amount, detail:{...}, attempts, expires_at, created_at }
Future<void> showMemberApprovalModal(
  BuildContext context,
  Map<String, dynamic> approval,
) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: _MemberApprovalDialog(approval: approval),
    ),
  );
}

class _MemberApprovalDialog extends StatefulWidget {
  final Map<String, dynamic> approval;
  const _MemberApprovalDialog({required this.approval});

  @override
  State<_MemberApprovalDialog> createState() => _MemberApprovalDialogState();
}

class _MemberApprovalDialogState extends State<_MemberApprovalDialog> {
  final _pinController = TextEditingController();
  String? _error;
  bool _busy = false;

  Timer? _tick;
  late DateTime _deadline;
  Duration _left = Duration.zero;

  String get _ref => widget.approval['ref']?.toString() ?? "";
  int get _amount {
    final v = widget.approval['amount'];
    return v is int ? v : int.tryParse(v?.toString() ?? "") ?? 0;
  }

  Map<String, dynamic> get _detail {
    final d = widget.approval['detail'];
    return d is Map<String, dynamic> ? d : const {};
  }

  /// amount 0 = konfirmasi POTONG WAKTU (bukan uang) - kasir buka meja pakai
  /// saldo waktu tersimpan member. Tampilkan durasinya, bukan "Rp0".
  bool get _isTimeApproval =>
      _amount == 0 || widget.approval['type']?.toString() == 'billing_time';
  String get _timeText => (_detail['Waktu'] ?? _detail['waktu'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _deadline =
        DateTime.tryParse(widget.approval['expires_at']?.toString() ?? "") ??
        DateTime.now().add(const Duration(seconds: 120));
    _updateLeft();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _updateLeft());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _updateLeft() {
    final left = _deadline.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _left = left.isNegative ? Duration.zero : left);
    if (left.isNegative && !_busy) {
      _tick?.cancel();
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _respond(String action) async {
    if (_busy) return;
    final pin = _pinController.text.trim();
    if (action == 'approve' && pin.length != 6) {
      setState(() => _error = "Masukkan PIN 6 digit");
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _error = "Sesi login tidak ditemukan");
        return;
      }
      final res = await ApiService().postAuth(ApiUrl.respondApproval, {
        "ref": _ref,
        "action": action,
        if (action == 'approve') "pin": pin,
      }, token);

      final status = res['status']?.toString();
      if (res['code'] == 200 || status == 'approved' || status == 'rejected') {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      // gagal (mis. PIN salah / terkunci / kadaluarsa)
      final msg = res['result']?.toString() ?? "Gagal memproses";
      if (status == 'rejected' || status == 'expired') {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _error = msg;
        _pinController.clear();
      });
    } catch (_) {
      setState(() => _error = "Server sedang gangguan, coba lagi.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _rupiah(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return "Rp$b";
  }

  @override
  Widget build(BuildContext context) {
    final secs = _left.inSeconds;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                ),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isTimeApproval ? "Konfirmasi Pemakaian Waktu" : "Konfirmasi Pembayaran",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isTimeApproval
                  ? "Kasir memakai saldo waktu tersimpan kamu"
                  : "Kasir meminta pembayaran dari saldo kamu",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isTimeApproval
                  ? (_timeText.isNotEmpty ? _timeText : "Potong Waktu")
                  : _rupiah(_amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final e in _detail.entries)
              // 'Waktu' sudah tampil besar di atas untuk approval potong waktu
              if (!(_isTimeApproval && e.key.toString().toLowerCase() == 'waktu'))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${e.key}: ${e.value}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(.55),
                      fontSize: 12,
                    ),
                  ),
                ),
            const SizedBox(height: 18),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 10,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                counterText: "",
                hintText: "PIN transaksi (6 digit)",
                hintStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  letterSpacing: 0,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              secs > 0 ? "Kadaluarsa dalam ${secs}s" : "Waktu habis",
              style: TextStyle(
                color: secs <= 20
                    ? const Color(0xFFDC2626)
                    : Colors.white.withOpacity(.5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _respond('reject'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: BorderSide(color: Colors.white.withOpacity(.25)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "TOLAK",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 8,
                      backgroundColor: Colors.transparent,
                      shadowColor: const Color(0xffA64DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 46),
                    ),
                    onPressed: _busy ? null : () => _respond('approve'),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xff6C3BFF), Color(0xffC44DFF)],
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        height: 46,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "SETUJUI",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
