import 'package:flutter/material.dart';

import '../widgets/footer/custom_bottom_nav.dart';

/// Lightweight placeholder for sections that don't have a full flow yet
/// (Booking, Match, Leaderboard). Keeps nav/menu taps functional instead of
/// dead-ending, without building out a feature that wasn't asked for.
class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  final int navIndex;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
    this.navIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 38),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Segera Hadir",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(initialIndex: navIndex),
    );
  }
}
