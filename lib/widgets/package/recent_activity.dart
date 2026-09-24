import 'package:flutter/material.dart';

import '../../core/api/apiService.dart';
import '../../core/api/apiUrl.dart';
import '../../core/storage/sessionManager.dart';
import '../../pages/transaction_list.dart';

class _ActivityItem {
  final String title;
  final String subtitle;
  final int amount;
  final bool isIn;
  final bool isSaldo; // false = point
  final DateTime? at;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIn,
    required this.isSaldo,
    required this.at,
  });

  factory _ActivityItem.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString();
    final unit = (json['unit_name'] ?? json['unit'])?.toString();
    final payment = (json['payment'] ?? json['payment_name'])?.toString();
    final durationRaw = json['duration_minutes'] ?? json['duration'];
    final duration = durationRaw == null ? null : int.tryParse(durationRaw.toString());

    String subtitle;
    if (type == 'main' && unit != null) {
      subtitle = duration != null ? "$unit • ${(duration / 60).toStringAsFixed(duration % 60 == 0 ? 0 : 1)} Jam" : unit;
    } else if (payment != null && payment.isNotEmpty) {
      subtitle = payment;
    } else {
      subtitle = switch (type) {
        'cafe' => "Pesanan Cafe",
        'point' => "Point",
        _ => "Saldo",
      };
    }

    return _ActivityItem(
      title: json['description']?.toString() ?? '-',
      subtitle: subtitle,
      amount: int.tryParse(json['amount'].toString()) ?? 0,
      isIn: json['movement'] == 'IN',
      isSaldo: type != 'point',
      at: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
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

const _months = [
  "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
  "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
];

String _formatWhen(DateTime? at) {
  if (at == null) return "";
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final time = "${two(at.hour)}:${two(at.minute)}";
  final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
  if (sameDay) return "Hari ini, $time";
  return "${at.day} ${_months[at.month - 1]} ${at.year}, $time";
}

/// Preview 2 aktivitas terbaru di dashboard - data asli dari
/// /apimobile/history (sumber sama dengan TransactionListPage).
class RecentActivitySection extends StatefulWidget {
  const RecentActivitySection({super.key});

  @override
  State<RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<RecentActivitySection> {
  late final Future<List<_ActivityItem>> _future = _load();

  Future<List<_ActivityItem>> _load() async {
    final token = await SessionManager.getToken();
    if (token == null) return const [];

    try {
      final response = await ApiService().postAuth(ApiUrl.history, {}, token);
      if (response['code'] == 200 && response['result'] is List) {
        final items = (response['result'] as List)
            .whereType<Map<String, dynamic>>()
            .map(_ActivityItem.fromJson)
            .toList();
        items.sort((a, b) {
          if (a.at == null) return 1;
          if (b.at == null) return -1;
          return b.at!.compareTo(a.at!);
        });
        return items.take(2).toList();
      }
    } catch (_) {
      // Best-effort - section ini cukup disembunyikan kalau gagal.
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ActivityItem>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (snapshot.connectionState != ConnectionState.done || items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Aktivitas Terbaru",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TransactionListPage()),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Lihat Semua",
                          style: TextStyle(
                            color: Color(0xff5CE1E6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded,
                            color: Color(0xff5CE1E6), size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(.07)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      _ActivityTile(data: items[i], last: i == items.length - 1),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem data;
  final bool last;

  const _ActivityTile({required this.data, required this.last});

  @override
  Widget build(BuildContext context) {
    final amountLabel = data.isSaldo
        ? "${data.isIn ? '+ ' : ''}${_formatRupiah(data.amount)}"
        : "${data.isIn ? '+' : '-'}${data.amount} pt";
    final amountColor = data.isIn ? const Color(0xff2ED573) : Colors.white;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionListPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: Colors.white.withOpacity(.06))),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xff46A8FF).withOpacity(.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_esports_rounded,
                  color: Color(0xff46A8FF), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountLabel,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatWhen(data.at),
                  style: TextStyle(
                    color: Colors.white.withOpacity(.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(.3), size: 18),
          ],
        ),
      ),
    );
  }
}
