import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../pages/notification_page.dart';
import 'member_approval_service.dart';
import 'notification_service.dart';

/// Navigator global supaya bisa pindah halaman dari luar widget tree
/// (mis. saat user menekan push notification).
final navigatorKey = GlobalKey<NavigatorState>();

/// Handler pesan FCM saat app di background / terminated. WAJIB top-level dan
/// diberi anotasi vm:entry-point. OS sudah menampilkan notifikasinya sendiri
/// dari payload `notification`, jadi di sini tidak perlu apa-apa.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  // `late` supaya FirebaseMessaging.instance baru diakses saat benar-benar
  // dipakai (di web, tanpa config Firebase web, akses ini akan throw).
  late final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _started = false;

  Future<void> init() async {
    // FCM web butuh setup terpisah (config web + VAPID key) yang belum ada,
    // jadi di web push dilewati - app tetap jalan normal.
    if (kIsWeb) return;
    if (_started) return;
    _started = true;

    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[PUSH] permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[PUSH] requestPermission error: $e');
    }

    await _syncToken();
    _fcm.onTokenRefresh.listen((t) {
      debugPrint('[PUSH] onTokenRefresh');
      _syncToken();
    });

    // Push masuk saat app foreground -> cukup segarkan daftar notifikasi
    // (sumber kebenaran ada di tabel notifications lewat /apimobile/notifications).
    FirebaseMessaging.onMessage.listen((message) {
      NotificationService.instance.fetch();
      if (message.data['type'] == 'approval') {
        MemberApprovalService.instance.checkNow();
      }
    });

    // User menekan push (app di background)
    FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);

    // App benar-benar tertutup lalu dibuka lewat push
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _openFromMessage(initial);
  }

  /// Kirim ulang token ke server (mis. dipanggil setelah login berhasil).
  Future<void> registerAfterLogin() async {
    if (kIsWeb) return;
    return _syncToken();
  }

  Future<void> _syncToken() async {
    try {
      final fcmToken = await _fcm.getToken();
      final auth = await SessionManager.getToken();
      debugPrint('[PUSH] fcmToken=${fcmToken == null ? "NULL" : "${fcmToken.substring(0, 12)}..."} '
          'auth=${auth == null ? "NULL" : "ok"}');
      if (fcmToken == null || auth == null) return;

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final res = await ApiService().postAuth(
        ApiUrl.fcmToken,
        {'token': fcmToken, 'platform': platform},
        auth,
      );
      debugPrint('[PUSH] /fcm_token response: $res');
    } catch (e, s) {
      debugPrint('[PUSH] _syncToken error: $e\n$s');
    }
  }

  void _openFromMessage(RemoteMessage message) {
    NotificationService.instance.fetch();
    if (message.data['type'] == 'approval') {
      MemberApprovalService.instance.checkNow();
      return;
    }
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }
}
