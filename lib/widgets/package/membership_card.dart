import 'package:flutter/material.dart';

import '../../models/userModel.dart';

class MembershipCard extends StatelessWidget {
  final UserModel? user;

  const MembershipCard({super.key, required this.user});

  static const _monthsShort = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
  ];

  String _formatJoinDate(String? raw) {
    if (raw == null || raw.isEmpty) return "-";
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return "${parsed.day} ${_monthsShort[parsed.month - 1]} ${parsed.year}";
  }

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? "Member GameOn";
    final code = user?.idNumber ?? "-";
    final joinDate = _formatJoinDate(user?.createdAt);
    final verified = user?.verification == "Y";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AspectRatio(
        aspectRatio: 1098 / 483,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff7B2EFF).withOpacity(.35),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  "assets/images/backgrounds/bg_member_card.png",
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "MEMBER CARD",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.85),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified_rounded, color: Colors.white, size: 11),
                                  SizedBox(width: 3),
                                  Text(
                                    "Verified",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 220,
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "KODE MEMBER",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            "Member sejak $joinDate",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
