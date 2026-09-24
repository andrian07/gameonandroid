import 'package:flutter/material.dart';

import '../../pages/booking_page.dart';
import '../../pages/rewards_page.dart';

/// Dua kartu promo statis di dashboard - belum ada endpoint promo/event,
/// jadi dipakai konten tetap yang mengarah ke halaman terkait (booking &
/// tukar reward) supaya tetap berguna bagi pengguna.
class PromoEventSection extends StatelessWidget {
  const PromoEventSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Promo & Event",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RewardsPage()),
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
          child: Row(
            children: [
              Expanded(
                child: _PromoCard(
                  title: "WEEKEND\nGAMING TIME",
                  subtitle: "Main lebih lama, lebih hemat!",
                  icon: Icons.sports_esports_rounded,
                  gradient: const [Color(0xff7B2EFF), Color(0xff3A1B6B)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingPage()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PromoCard(
                  title: "MEMBER\nEXCLUSIVE",
                  subtitle: "Point bisa ditukar berbagai hadiah!",
                  icon: Icons.card_giftcard_rounded,
                  gradient: const [Color(0xffF6B91A), Color(0xff8B4513)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardsPage()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 128,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: Border.all(color: Colors.white.withOpacity(.1)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(icon, color: Colors.white.withOpacity(.18), size: 74),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.8),
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
