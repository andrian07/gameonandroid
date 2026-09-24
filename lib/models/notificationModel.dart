import 'package:flutter/material.dart';

/// 1 baris notifikasi member (dari POST /apimobile/notifications).
/// Server mengirim `type` sebagai string; ikon & warna diturunkan di sini
/// supaya tampilan tetap konsisten dengan desain lama.
class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool unread;
  final DateTime? createdAt;

  /// Detail key-value dari server (kolom `data` JSON) - ditampilkan saat diklik.
  final Map<String, String> detail;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.unread,
    required this.createdAt,
    this.detail = const {},
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawRead = json['is_read'];
    final isRead = rawRead == true ||
        rawRead == 1 ||
        rawRead.toString() == '1' ||
        rawRead.toString().toLowerCase() == 'true';

    final rawDetail = json['data'];
    final detail = <String, String>{};
    if (rawDetail is Map) {
      rawDetail.forEach((k, v) {
        if (v != null) detail[k.toString()] = v.toString();
      });
    }

    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '-',
      message: json['message']?.toString() ?? '',
      unread: !isRead,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      detail: detail,
    );
  }

  IconData get icon {
    switch (type) {
      case 'booking':
        return Icons.event_available_rounded;
      case 'topup':
        return Icons.account_balance_wallet_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'point':
        return Icons.card_giftcard_rounded;
      case 'tournament':
        return Icons.emoji_events_rounded;
      case 'verification':
        return Icons.verified_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'reward':
        return Icons.redeem_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'booking':
        return const Color(0xffFF5A71);
      case 'topup':
        return const Color(0xff46A8FF);
      case 'promo':
        return const Color(0xffF6B91A);
      case 'point':
        return const Color(0xffA855F7);
      case 'tournament':
        return const Color(0xffFF5A71);
      case 'verification':
        return const Color(0xffF6B91A);
      case 'cafe':
        return const Color(0xffB06CFF);
      case 'reward':
        return const Color(0xff2ED573);
      default:
        return const Color(0xff9D4DFF);
    }
  }

  /// Label waktu relatif ("5 menit lalu", "Kemarin • 20:15", "3 hari lalu").
  String get timeLabel {
    final date = createdAt;
    if (date == null) return '';

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';

    final time =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    if (diff.inDays == 1) return 'Kemarin • $time';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
}
