import 'package:flutter/material.dart';

import '../../pages/booking_page.dart';
import '../../pages/cafe_menu.dart';
import '../../pages/rank_page.dart';
import 'top_up_modal.dart';

class QuickMenu extends StatelessWidget {
  const QuickMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      QuickMenuItem(
        title: "Top Up",
        iconPath: "assets/images/icons/ic_topup.png",
        onTap: () => showTopUpModal(context),
      ),
      QuickMenuItem(
        title: "Booking",
        iconPath: "assets/images/icons/ic_booking.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingPage()),
        ),
      ),
      QuickMenuItem(
        title: "Cafe",
        iconPath: "assets/images/icons/ic_store.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CafeMenuPage()),
        ),
      ),
      QuickMenuItem(
        title: "Rank",
        iconPath: "assets/images/icons/ic_trophy.png",
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RankPage()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final item in items) ...[
            Expanded(child: item),
            if (item != items.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class QuickMenuItem extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  const QuickMenuItem({
    super.key,
    required this.title,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 58, height: 58),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
