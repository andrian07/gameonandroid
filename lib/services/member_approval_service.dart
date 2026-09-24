import 'dart:async';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../widgets/member_approval_modal.dart';
import 'push_service.dart' show navigatorKey;

/// Memantau permintaan konfirmasi pembayaran (kasir bayar "Potong Saldo" pakai
/// akun member ini). Selama user login, polling tiap 3 detik ke
/// /apimobile/pending_approvals; juga bisa dipicu langsung oleh push FCM
/// bertipe `approval`. Saat ada permintaan -> tampilkan [showMemberApprovalModal].
class MemberApprovalService {
  MemberApprovalService._();
  static final MemberApprovalService instance = MemberApprovalService._();

  Timer? _timer;
  bool _checking = false;
  bool _modalOpen = false;
  final Set<String> _handledRefs = {};

  void start() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => checkNow(),
    );
    checkNow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _handledRefs.clear();
  }

  Future<void> checkNow() async {
    if (_checking || _modalOpen) return;
    _checking = true;
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        stop();
        return;
      }

      final res =
          await ApiService().postAuth(ApiUrl.pendingApprovals, {}, token);
      if (res is! Map || res['code'] != 200 || res['result'] is! List) return;

      final list = (res['result'] as List).whereType<Map>().toList();
      if (list.isEmpty) return;

      // ambil yang paling awal & belum pernah ditangani di sesi ini
      Map<String, dynamic>? next;
      for (final raw in list) {
        final item = Map<String, dynamic>.from(raw);
        final ref = item['ref']?.toString() ?? '';
        if (ref.isEmpty || _handledRefs.contains(ref)) continue;
        next = item;
        break;
      }
      if (next == null) return;

      // navigatorKey global (bukan context milik widget yang bisa ter-dispose),
      // aman dipakai setelah await.
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      _handledRefs.add(next['ref'].toString());
      _modalOpen = true;
      try {
        // ignore: use_build_context_synchronously
        await showMemberApprovalModal(ctx, next);
      } finally {
        _modalOpen = false;
      }
      // cek lagi segera kalau masih ada antrean lain
      unawaited(checkNow());
    } catch (_) {
      // diamkan - dicoba lagi di tick berikutnya
    } finally {
      _checking = false;
    }
  }
}
