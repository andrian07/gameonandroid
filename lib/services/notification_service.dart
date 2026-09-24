import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../models/notificationModel.dart';

/// Cache notifikasi tingkat aplikasi. Dipakai bareng oleh badge lonceng di
/// header, modal notifikasi, dan halaman notifikasi supaya cukup 1x fetch dan
/// hitungan unread selalu sinkron.
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  List<NotificationModel> items = const [];
  bool loading = false;
  String? error;
  bool _loadedOnce = false;

  int get unreadCount => items.where((n) => n.unread).length;

  /// Fetch sekali saja (dipanggil dari header saat dashboard dibuka).
  Future<void> ensureLoaded() async {
    if (_loadedOnce || loading) return;
    await fetch();
  }

  /// notifyListeners yang aman dipanggil dari fase build/layout (mis. TopBar
  /// memanggil ensureLoaded() di build()). Kalau sedang membangun frame,
  /// pemberitahuan ditunda sampai frame selesai supaya tidak melempar assertion.
  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  Future<void> fetch() async {
    loading = true;
    error = null;
    _notifySafely();

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        error = 'Sesi login tidak ditemukan, silakan login ulang.';
        return;
      }

      final response =
          await ApiService().postAuth(ApiUrl.notifications, {}, token);
      if (response['code'] == 200 && response['result'] is List) {
        items = (response['result'] as List)
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList();
        _loadedOnce = true;
      } else {
        error = response['result']?.toString() ?? 'Gagal memuat notifikasi';
      }
    } catch (e) {
      error = 'Server sedang gangguan, silakan coba lagi.';
    } finally {
      loading = false;
      _notifySafely();
    }
  }

  /// Tandai 1 notifikasi (atau semua kalau [id] null) sudah dibaca.
  /// Update lokal dulu biar badge langsung berubah, lalu kirim ke server.
  Future<void> markRead({int? id}) async {
    var changed = false;
    items = items.map((n) {
      if (!n.unread) return n;
      if (id != null && n.id != id) return n;
      changed = true;
      return NotificationModel(
        id: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        unread: false,
        createdAt: n.createdAt,
        detail: n.detail,
      );
    }).toList();

    if (changed) notifyListeners();

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;
      await ApiService().postAuth(
        ApiUrl.notificationRead,
        id != null ? {'id': id} : {},
        token,
      );
    } catch (_) {
      // biarkan - state lokal sudah update, sinkron lagi di fetch berikutnya
    }
  }

  /// Hapus 1 notifikasi (atau SEMUA kalau [id] null). Hapus lokal dulu supaya
  /// UI langsung berubah, lalu kirim ke server.
  Future<void> delete({int? id}) async {
    final before = items;
    items = id == null
        ? const []
        : items.where((n) => n.id != id).toList();

    if (items.length != before.length) notifyListeners();

    try {
      final token = await SessionManager.getToken();
      if (token == null) return;
      await ApiService().postAuth(
        ApiUrl.notificationDelete,
        id != null ? {'id': id} : {},
        token,
      );
    } catch (_) {
      // gagal kirim - kembalikan state lokal & minta user coba lagi via fetch
      items = before;
      notifyListeners();
      rethrow;
    }
  }
}
